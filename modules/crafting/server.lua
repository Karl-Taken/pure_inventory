if not lib then return end
lib.locale()

local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'

local CraftingConfig = lib.load('data.crafting') or {}
local BenchTypes = CraftingConfig.types or {}
local StaticBenches = CraftingConfig.benches or {}
local BlueprintConfig = CraftingConfig.blueprints or {}
local XPConfig = CraftingConfig.xp or {}

local CraftingBenches = {}
local CraftingStorages = {}
local PlacementItems = {}
local PlacedBenches = {}
local PendingPlacement = {}
local CraftingXP = {}
local getPlayerIdentifier
local function asBool(value)
	return value == true or value == 1 or value == '1'
end

local function getDefaultRoleDefinitions()
	return {
		{
			name = locale('crafting_role_member') or 'Member',
			can_use = 1,
			can_move = 0,
			can_pack = 0,
			can_manage = 0,
		},
		{
			name = locale('crafting_role_manager') or 'Manager',
			can_use = 1,
			can_move = 1,
			can_pack = 1,
			can_manage = 1,
		},
	}
end

local function getBenchRecord(benchId)
	return PlacedBenches[benchId]
end

local function ensureDefaultRoles(persistentId)
	if not persistentId then return end

	local existing = MySQL.scalar.await('SELECT COUNT(*) FROM ox_crafting_roles WHERE bench_id = ?', { persistentId })

	if existing and existing > 0 then
		return
	end

	for _, roleData in ipairs(getDefaultRoleDefinitions()) do
		MySQL.insert.await(
			'INSERT INTO ox_crafting_roles (bench_id, name, can_use, can_move, can_pack, can_manage) VALUES (?, ?, ?, ?, ?, ?)',
			{ persistentId, roleData.name, roleData.can_use, roleData.can_move, roleData.can_pack, roleData.can_manage }
		)
	end
end

local function loadBenchRoles(benchId, persistentId)
	if not persistentId then return end

	ensureDefaultRoles(persistentId)

	local roleRows = MySQL.query.await('SELECT * FROM ox_crafting_roles WHERE bench_id = ? ORDER BY id ASC', { persistentId }) or {}
	local roles = {}
	local memberIndex = {}

	for _, row in ipairs(roleRows) do
		roles[row.id] = {
			id = row.id,
			benchId = row.bench_id,
			name = row.name,
			canUse = asBool(row.can_use),
			canMove = asBool(row.can_move),
			canPack = asBool(row.can_pack),
			canManage = asBool(row.can_manage),
			members = {},
		}
	end

	if next(roles) then
		local memberRows = MySQL.query.await('SELECT * FROM ox_crafting_role_members WHERE bench_id = ?', { persistentId }) or {}

		for _, row in ipairs(memberRows) do
			local role = roles[row.role_id]
			if role then
				local memberEntry = {
					id = row.id,
					identifier = row.identifier,
					addedBy = row.added_by,
				}
				role.members[#role.members + 1] = memberEntry
				memberIndex[row.identifier] = row.role_id
			end
		end
	end

	local record = benchId and getBenchRecord(benchId)
	if record then
		record.roles = {
			list = roles,
			memberIndex = memberIndex,
		}
	end

	return roles, memberIndex
end

local function getBenchRolesCache(benchId)
	local record = getBenchRecord(benchId)
	if not record or not record.id then return nil end

	if not record.roles then
		loadBenchRoles(benchId, record.id)
	end

	return record.roles
end

local function getOnlineSourceByIdentifier(identifier)
	if not identifier then return nil end
	for _, playerId in ipairs(GetPlayers()) do
		local src = tonumber(playerId)
		if src then
			local inv = Inventory(src)
			if inv and inv.owner == identifier then
				return src
			end
		end
	end
end

local function toVector3(value)
	if not value then return nil end
	local valueType = type(value)

	if valueType == 'vector3' then
		return value
	end

	if valueType == 'table' then
		if value.coords then
			return toVector3(value.coords)
		end

		if value.x or value.y or value.z then
			return vec3(value.x or 0.0, value.y or 0.0, value.z or 0.0)
		end

		if value[1] or value[2] or value[3] then
			return vec3(value[1] or 0.0, value[2] or 0.0, value[3] or 0.0)
		end
	end

	return nil
end

local function getBenchReferenceCoords(bench)
	if not bench then return nil end

	return toVector3(bench.coords)
		or (bench.zones and toVector3(bench.zones[1]))
		or (bench.points and toVector3(bench.points[1]))
end




local function giveBlueprintToPlayer(targetId, blueprintKey, overrideValue)
	if not targetId or not blueprintKey then return false, 'invalid_parameters' end

	local blueprint = BlueprintConfig[blueprintKey]
	if not blueprint then
		return false, 'crafting_blueprint_not_found'
	end

	local itemName = blueprint.item
	if not itemName then
		return false, 'crafting_blueprint_no_item'
	end

	local metadata = {}
	if blueprint.metadataKey then
		metadata[blueprint.metadataKey] = overrideValue or blueprint.metadataValue
	end

	local success, err = Inventory.AddItem(targetId, itemName, 1, metadata)
	if not success then
		return false, err or 'crafting_blueprint_failed'
	end

	return true, itemName
end


RegisterCommand('giveBlueprintToPlayer', function(source, args)
	local targetId = tonumber(args[1])
	local blueprintKey = args[2]
	local overrideValue = args[3]

	giveBlueprintToPlayer(targetId, blueprintKey, overrideValue)
end, true)


local function collectOnlinePlayers(originCoords, radius)
	local players = {}
	local useRadius = originCoords and radius and radius > 0

	for _, playerId in ipairs(GetPlayers()) do
		local src = tonumber(playerId)
		if src then
			local inv = Inventory(src)
			if inv and inv.owner then
				local include = true

				if useRadius then
					local ped = GetPlayerPed(src)
					if ped and ped ~= 0 then
						local pedCoords = GetEntityCoords(ped)
						if #(pedCoords - originCoords) > radius then
							include = false
						end
					else
						include = false
					end
				end

				if include then
					players[#players + 1] = {
						source = src,
						identifier = inv.owner,
						name = inv.player and inv.player.name or GetPlayerName(src),
					}
				end
			end
		end
	end

	return players
end

exports('giveBlueprintToPlayer', giveBlueprintToPlayer)

lib.callback.register('ox_inventory:crafting:giveBlueprint', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local targetId = data.target
	local blueprintKey = data.blueprint
	local overrideValue = data.override

	if type(targetId) ~= 'number' then
		return false, 'invalid_data'
	end

	local success, info = giveBlueprintToPlayer(targetId, blueprintKey, overrideValue)
	if success then
		if source and source > 0 then
			lib.notify(source, { type = 'success', description = locale('crafting_blueprint_granted') or 'Blueprint granted.' })
		end
		lib.notify(targetId, { type = 'inform', description = locale('crafting_blueprint_received') or 'You received a blueprint.' })
		return true, info
	end

	if source and source > 0 then
		lib.notify(source, { type = 'error', description = locale(info) or tostring(info) })
	end
	return false, info
end)

RegisterNetEvent('ox_inventory:crafting:requestBlueprint', function(metadataKey, metadataValue)
	local src = source
	if type(metadataKey) ~= 'string' then return end

	for key, blueprint in pairs(BlueprintConfig) do
		if blueprint.metadataKey == metadataKey and blueprint.metadataValue == metadataValue then
			giveBlueprintToPlayer(src, key)
			break
		end
	end
end)

local function resolveIdentifier(input)
	if type(input) == 'number' then
		local inv = Inventory(input)
		return inv and inv.owner or nil, input
	end

	if type(input) == 'string' then
		local trimmed = input:gsub('^%s+', ''):gsub('%s+$', '')
		if trimmed == '' then return nil end
		if trimmed:match('^%d+$') then
			local src = tonumber(trimmed)
			if src then
				local inv = Inventory(src)
				if inv and inv.owner then
					return inv.owner, src
				end
			end
		end
		return trimmed, nil
	end

	return nil
end
local function trim(value)
	if type(value) ~= "string" then return nil end
	local trimmed = value:gsub("^%s+", ""):gsub("%s+$", "")
	return trimmed
end

local function canManageBench(source, benchId)
	local record = getBenchRecord(benchId)
	if not record then return false, nil end

	local identifier = getPlayerIdentifier(source)
	if not identifier then return false, record end

	if record.owner == identifier then
		return true, record
	end

	if hasBenchPermission(identifier, benchId, 'manage') then
		return true, record
	end

	return false, record
end
local function computeBenchPermissions(benchId, identifier)
	local permissions = {
		canUse = true,
		canMove = false,
		canPack = false,
		canManage = false,
		isOwner = false,
		roleId = nil,
		roleName = nil,
	}

	if not benchId then
		return permissions
	end

	local record = getBenchRecord(benchId)

	if not record then
		return permissions
	end

	if identifier and record.owner == identifier then
		permissions.canMove = true
		permissions.canPack = true
		permissions.canManage = true
		permissions.isOwner = true
		permissions.roleId = nil
		return permissions
	end

	local rolesCache = getBenchRolesCache(benchId)

	if not rolesCache then
		permissions.canUse = false
		return permissions
	end

	local roleId = identifier and rolesCache.memberIndex and rolesCache.memberIndex[identifier] or nil
	local role = roleId and rolesCache.list and rolesCache.list[roleId]

	if not role then
		permissions.canUse = false
		return permissions
	end

	permissions.canUse = role.canUse
	permissions.canMove = role.canMove
	permissions.canPack = role.canPack
	permissions.canManage = role.canManage
	permissions.roleId = role.id
	permissions.roleName = role.name

	return permissions
end

 function hasBenchPermission(subject, benchId, permission)
	if permission == 'use' and not benchId then
		return true
	end

	local identifier = subject
	if type(subject) ~= 'string' then
		identifier = getPlayerIdentifier(subject)
	end

	local record = getBenchRecord(benchId)

	if not record then
		return permission == 'use'
	end

	if identifier and record.owner == identifier then
		return true
	end

	local perms = computeBenchPermissions(benchId, identifier)

	if permission == 'use' then
		return perms.canUse
	elseif permission == 'move' then
		return perms.canMove
	elseif permission == 'pack' then
		return perms.canPack
	elseif permission == 'manage' then
		return perms.canManage
	elseif permission == 'owner' then
		return perms.isOwner
	end

	return false
end

local function buildBenchPermissionsPayload(source, benchId)
	local bench = CraftingBenches[benchId]
	local record = getBenchRecord(benchId)
	if not bench or not record then
		return nil, 'crafting_not_found'
	end

	local identifier = getPlayerIdentifier(source)
	if not identifier then
		return nil, 'crafting_no_permission'
	end

	local isOwner = record.owner == identifier
	if not isOwner and not hasBenchPermission(identifier, benchId, 'manage') then
		return nil, 'crafting_no_permission'
	end

	local rolesCache = getBenchRolesCache(benchId)
	if not rolesCache then
		rolesCache = { list = {}, memberIndex = {} }
	end

	local onlinePlayers = collectOnlinePlayers()
	local onlineIndex = {}
	for i = 1, #onlinePlayers do
		local player = onlinePlayers[i]
		local roleId = rolesCache.memberIndex and rolesCache.memberIndex[player.identifier]
		player.roleId = roleId
		onlineIndex[player.identifier] = player
	end

	local roles = {}
	for _, role in pairs(rolesCache.list or {}) do
		local members = {}
		for _, member in ipairs(role.members or {}) do
			local online = onlineIndex[member.identifier]
			members[#members + 1] = {
				id = member.id,
				identifier = member.identifier,
				name = online and online.name or member.identifier,
				online = online and true or false,
				serverId = online and online.source or nil,
				addedBy = member.addedBy,
			}
		end

		table.sort(members, function(a, b)
			return a.identifier < b.identifier
		end)

		roles[#roles + 1] = {
			id = role.id,
			name = role.name,
			canUse = role.canUse,
			canMove = role.canMove,
			canPack = role.canPack,
			canManage = role.canManage,
			memberCount = #members,
			members = members,
		}
	end

	table.sort(roles, function(a, b)
		return a.id < b.id
	end)

	local ownerInfo = record.owner and onlineIndex[record.owner] or nil
	local ownerName = ownerInfo and ownerInfo.name or record.owner
	local benchCoords = getBenchReferenceCoords(bench)
	local nearbyRadius = benchCoords and (bench.nearbyRadius or 10.0) or nil
	local nearbyPlayers = collectOnlinePlayers(benchCoords, nearbyRadius)

	return {
		benchId = benchId,
		benchLabel = bench.label or benchId,
		owner = {
			identifier = record.owner,
			name = ownerName,
			online = ownerInfo and true or false,
			serverId = ownerInfo and ownerInfo.source or nil,
		},
		roles = roles,
		onlinePlayers = nearbyPlayers,
		canTransfer = isOwner,
		isOwner = isOwner,
		playerPermissions = computeBenchPermissions(benchId, identifier),
	}, nil
end
local function sendBenchPermissions(playerId, benchId)
	local bench = CraftingBenches[benchId]
	if not bench then return end

	local identifier = getPlayerIdentifier(playerId)
	local perms = computeBenchPermissions(benchId, identifier)

	TriggerClientEvent('ox_inventory:crafting:updatePermissions', playerId, {
		id = benchId,
		canUse = perms.canUse,
		canMove = perms.canMove,
		canPack = perms.canPack,
		canManage = perms.canManage,
		isOwner = perms.isOwner,
		roleId = perms.roleId,
		roleName = perms.roleName,
	})
end

local function notifyBenchMembers(benchId, includeOwner)
	local record = getBenchRecord(benchId)
	if not record then return end

	local identifiers = {}

	if includeOwner and record.owner then
		identifiers[record.owner] = true
	end

	local cache = getBenchRolesCache(benchId)
	if cache and cache.memberIndex then
		for identifier in pairs(cache.memberIndex) do
			identifiers[identifier] = true
		end
	end

	for identifier in pairs(identifiers) do
		local targetSrc = getOnlineSourceByIdentifier(identifier)
		if targetSrc then
			sendBenchPermissions(targetSrc, benchId)
		end
	end
end

local function clearBenchRoles(benchId, persistentId)
	local record = getBenchRecord(benchId)
	if record then
		record.roles = nil
	end
end


CraftingQueues = CraftingQueues or {}
CraftingNextId = CraftingNextId or 0

local function getPlayerQueue(source)
	CraftingQueues[source] = CraftingQueues[source] or {}
	return CraftingQueues[source]
end

local function sendQueueUpdate(source)
	local q = getPlayerQueue(source)
	local payload = {}
	for i = 1, #q do
		local job = q[i]
		local remaining = nil
		if job.startedAt then
			remaining = math.max(0, job.startedAt + job.duration - os.time())
		end

		payload[i] = {
			benchId = job.benchId,
			recipe = job.recipe and job.recipe.name,
			recipeSlot = job.recipeSlot,
			craftCount = job.craftCount,
			startedAt = job.startedAt,
			duration = job.duration,
			remaining = remaining
		}
	end

	TriggerClientEvent('ox_inventory:crafting:queueUpdated', source, payload)
end

local function completeCraftJob(jobIndex, source)
	local q = getPlayerQueue(source)
	local job = q[jobIndex]
	if not job then return end

	
	local craftedItem = job.craftedItem
	local craftCount = job.craftCount or 1
	local targetInventory = job.targetInventory

	local added = Inventory.AddItem(targetInventory, craftedItem, craftCount, job.recipe.metadata or {}, craftedItem.stack and job.toSlot or nil)

	

	local xpReward = job.recipe.xp and job.recipe.xp.reward or XPConfig.defaultReward or 0
	if xpReward > 0 then
		addPlayerXP(source, xpReward)
	end

	
	table.remove(q, jobIndex)
	sendQueueUpdate(source)

	
	local nextJob = q[1]
	if nextJob then
		nextJob.startedAt = os.time()
		sendQueueUpdate(source)
		SetTimeout((nextJob.duration or 3) * 1000, function()
			local q2 = getPlayerQueue(source)
			local idx = nil
			for i = 1, #q2 do
				if q2[i].id == nextJob.id then idx = i break end
			end

			if idx then
				completeCraftJob(idx, source)
			end
		end)
	end
	
	if added then
		pcall(function()
			lib.notify(source, { type = 'success', description = ('Crafted: %s'):format(tostring(craftedItem.label or craftedItem.name)) })
		end)
	else
		pcall(function()
			lib.notify(source, { type = 'error', description = ('Failed to add crafted item: %s'):format(tostring(craftedItem.label or craftedItem.name)) })
		end)
	end
end


CraftingStoragePlayers = CraftingStoragePlayers or {}

local function deepCopy(value)
	if type(value) ~= 'table' then return value end
	if table.deepclone then
		return table.deepclone(value)
	end

	local copy = {}

	for k, v in pairs(value) do
		copy[k] = deepCopy(v)
	end

	return copy
end
local function craftingStorageKey(benchId, index)
	return ('crafting:%s:%s'):format(benchId, index or 1)
end

local function resolveStorageConfig(bench)
	local config = bench.storage

	if config == false then
		return
	end

	if type(config) ~= 'table' then
		config = {}
	end

	local slots = config.slots or config[1] or shared.playerslots
	local maxWeight = config.maxWeight or config[2] or shared.playerweight

	return {
		slots = slots,
		maxWeight = maxWeight,
		label = config.label,
		owner = config.owner,
		groups = config.groups or bench.groups,
		items = config.items,
		coords = config.coords,
		restrict = config.restrict,
	}
end

local function setStorageStateForPlayer(playerId, storage)
	if not storage then
		return
	end

	local previousStorageId = CraftingStoragePlayers[playerId]

	if previousStorageId and previousStorageId ~= storage.id then
		local previousStorage = Inventory(previousStorageId)

		if previousStorage then
			previousStorage.openedBy[playerId] = nil

			if not next(previousStorage.openedBy) then
				previousStorage:set('open', false)
			end
		end
	end

	storage.openedBy[playerId] = true
	storage:set('open', true)
	CraftingStoragePlayers[playerId] = storage.id
end

local function releaseStorageForPlayer(playerId, storageId)
	storageId = storageId or CraftingStoragePlayers[playerId]

	if not storageId then
		return
	end

	local storage = Inventory(storageId)

	if storage then
		storage.openedBy[playerId] = nil

		if not next(storage.openedBy) then
			storage:set('open', false)
		end
	end

	if not storageId or storageId == CraftingStoragePlayers[playerId] then
		CraftingStoragePlayers[playerId] = nil
	end
end

function getPlayerIdentifier(source)
	local inv = Inventory(source)
	if inv and inv.owner then
		return inv.owner
	end

	return ('player:%s'):format(source)
end

local function fetchPlayerXP(identifier)
	if CraftingXP[identifier] ~= nil then
		return CraftingXP[identifier]
	end

	local row = MySQL.single.await('SELECT xp FROM ox_crafting_xp WHERE identifier = ?', { identifier })
	local xp = row and row.xp or 0
	CraftingXP[identifier] = xp
	return xp
end

local function getPlayerXP(source)
	if not XPConfig.enabled then
		return 0
	end

	local identifier = getPlayerIdentifier(source)
	return fetchPlayerXP(identifier)
end

local function savePlayerXP(identifier, xp)
	CraftingXP[identifier] = xp
	MySQL.prepare.await('INSERT INTO ox_crafting_xp (identifier, xp) VALUES (?, ?) ON DUPLICATE KEY UPDATE xp = VALUES(xp)', {
		identifier,
		xp
	})
end

 function addPlayerXP(source, amount)
	if not XPConfig.enabled or not amount or amount <= 0 then
		return
	end

	local identifier = getPlayerIdentifier(source)
	local newValue = fetchPlayerXP(identifier) + amount
	savePlayerXP(identifier, newValue)
	TriggerClientEvent('ox_inventory:crafting:updateXp', source, newValue)
end

local function collectBlueprintsFromItems(items)
	if not items or not BlueprintConfig then
		return {}
	end

	local unlocked = {}

	for _, slot in pairs(items) do
		if slot and slot.name then
			for key, blueprint in pairs(BlueprintConfig) do
				if slot.name == blueprint.item then
					
					local hasDurability = slot.metadata and slot.metadata.durability
					local hasEnoughDurability = true
					
					if hasDurability then
						local durability = slot.metadata.durability
						if durability <= 0 then
							hasEnoughDurability = false
						end
					end
					
					if hasEnoughDurability then
						if blueprint.metadataKey then
							local meta = slot.metadata
							if type(meta) == 'table' then
								local value = meta[blueprint.metadataKey]

								if value ~= nil then
									if not blueprint.metadataValue or blueprint.metadataValue == value then
										unlocked[key] = slot
									end
								end
							end
						else
							unlocked[key] = slot
						end
					end
				end
			end
		end
	end

	return unlocked
end

local function collectBlueprints(source, storage)
	if not BlueprintConfig or not next(BlueprintConfig) then
		return {}
	end

	local unlocked = {}

	
	
	
	
	
	

	if storage and storage.items then
		for key, slot in pairs(collectBlueprintsFromItems(storage.items)) do
			unlocked[key] = slot
		end
	end

	return unlocked
end

local function playerHasBlueprint(source, blueprintKey, storage)
	if not blueprintKey then
		return true
	end

	local un = collectBlueprints(source, storage)
	return un[blueprintKey] ~= nil
end

 function consumeBlueprint(storage, blueprintKey, consumeAmount)
	if not blueprintKey or not storage or not BlueprintConfig then
		return false
	end

	local blueprint = BlueprintConfig[blueprintKey]
	if not blueprint or not blueprint.consume or blueprint.consume <= 0 then
		return true 
	end

	local blueprints = collectBlueprintsFromItems(storage.items)
	local blueprintSlot = blueprints[blueprintKey]
	
	if not blueprintSlot then
		return false
	end

	local amount = consumeAmount or blueprint.consume
	
	for slot, item in pairs(storage.items) do
		if item == blueprintSlot then
			local itemData = Items(item.name)
			if not itemData then return false end
			
			if item.metadata and item.metadata.durability then
				local durability = item.metadata.durability
				
				if durability > 100 then
					
					local degrade = (item.metadata.degrade or itemData.degrade) * 60
					durability -= degrade * amount
				else
					
					durability -= amount * 100
				end
				
				if item.count > 1 then
					
					local emptySlot = Inventory.GetEmptySlot(storage)
					if emptySlot then
						local newItem = Inventory.SetSlot(storage, itemData, 1, deepCopy(item.metadata), emptySlot)
						if newItem then
							Items.UpdateDurability(storage, newItem, itemData, durability < 0 and 0 or durability)
						end
					end
					
					item.count -= 1
					item.weight = Inventory.SlotWeight(itemData, item)
					
					storage:syncSlotsWithClients({
						{
							item = item,
							inventory = storage.id
						}
					}, true)
				else
					
					Items.UpdateDurability(storage, item, itemData, durability < 0 and 0 or durability)
				end
				
				return true
			end
			
			
			
			return true
		end
	end
	
	return false
end

local function notifyBlueprintUpdate(source, storage)
	if not BlueprintConfig or not next(BlueprintConfig) then
		return
	end

	local blueprintsSlots = collectBlueprints(source, storage)
	local blueprints = {}
	
	
	for key, _ in pairs(blueprintsSlots) do
		blueprints[key] = true
	end
	
	TriggerClientEvent('ox_inventory:crafting:updateBlueprints', source, blueprints)
end

local function getCraftingStorage(source, benchId, bench, index)
	local storageConfig = resolveStorageConfig(bench)

	if not storageConfig then
		releaseStorageForPlayer(source)
		return
	end

	local key = craftingStorageKey(benchId, index)
	local storageId = CraftingStorages[key]
	local storage = storageId and Inventory(storageId)

	if not storage then
		local label

		if type(storageConfig.label) == 'string' then
			label = storageConfig.label
		elseif bench.label then
			label = ('%s Storage'):format(bench.label)
		else
			label = locale('storage') or 'Storage'
		end

		storage = Inventory.Create(
			key,
			label,
			'stash',
			storageConfig.slots,
			0,
			storageConfig.maxWeight,
			storageConfig.owner or false,
			storageConfig.items,
			storageConfig.groups
		)

		if not storage then
			return
		end

		local coords = storageConfig.coords
			or (bench.zones and bench.zones[index] and bench.zones[index].coords)
			or (bench.points and bench.points[index])

		if coords then
			storage.coords = coords
		end

		CraftingStorages[key] = storage.id
	else
		if storageConfig.label and storage.label ~= storageConfig.label then
			storage.label = storageConfig.label
		elseif not storageConfig.label and bench.label then
			storage.label = ('%s Storage'):format(bench.label)
		end

		if storageConfig.groups then
			storage.groups = storageConfig.groups
		end

		if storageConfig.maxWeight and storage.maxWeight ~= storageConfig.maxWeight then
			Inventory.SetMaxWeight(storage, storageConfig.maxWeight)
		end

		if storageConfig.slots and storage.slots ~= storageConfig.slots then
			Inventory.SetSlotCount(storage, storageConfig.slots)
		end
	end

	setStorageStateForPlayer(source, storage)

	return storage
end

local function getCraftingCoords(source, bench, index)
	if not bench.zones and not bench.points then
		return GetEntityCoords(GetPlayerPed(source))
	else
		return shared.target and bench.zones and bench.zones[index].coords or bench.points and bench.points[index]
	end
end

local function validatePlacementItem(typeName, itemName)
	local typeConfig = BenchTypes[typeName]

	if not typeConfig or not typeConfig.placement then
		return false
	end

	if typeConfig.placement.item ~= itemName then
		return false
	end

	return true
end

local function buildBenchDefinition(id, benchData)
	local typeId = benchData.type or benchData.typeId
	local typeConfig = typeId and BenchTypes[typeId]

	if not typeConfig and not benchData.items then
		warn(('failed to create crafting bench "%s" - unknown type "%s"'):format(id, tostring(typeId)))
		return
	end

	local built = table.clone(benchData) or {}
	built.id = id
	built.typeId = typeId
	built.typeConfig = typeConfig

	
	
	
	built.groups = built.groups or built.jobs or built.job or built.gangs or built.gang

	if typeConfig then
		built.label = built.label or typeConfig.label
		built.model = built.model or typeConfig.model
		built.spawnRange = built.spawnRange or typeConfig.spawnRange
		built.storage = built.storage or typeConfig.storage
		built.items = built.items or typeConfig.recipes
		built.hideLocked = typeConfig.hideLocked
	else
		built.items = built.items or {}
	end

	built.items = deepCopy(built.items or {})

	if built.coords and not built.points and not built.zones then
		local vec = built.coords
		if type(vec) == 'vector3' then
			built.points = { vec3(vec.x, vec.y, vec.z) }
		elseif type(vec) == 'table' then
			built.points = { vec3(vec.x or 0.0, vec.y or 0.0, vec.z or 0.0) }
		end
	end

	return built
end

local function sanitiseBenchForClient(bench)
	local payload = deepCopy(bench)
	payload.typeConfig = nil
	if payload.coords and type(payload.coords) == 'vector3' then
		payload.coords = { x = payload.coords.x, y = payload.coords.y, z = payload.coords.z }
	end
	return payload
end

local function registerBench(id, benchData)
	local built = buildBenchDefinition(id, benchData)
	if not built then return end

	if built.coords then
		if type(built.coords) == 'vector3' then
			built.coords = vec3(built.coords.x, built.coords.y, built.coords.z)
		elseif type(built.coords) == 'table' then
			built.coords = vec3(built.coords.x or 0.0, built.coords.y or 0.0, built.coords.z or 0.0)
		end
	end

	local recipes = built.items

	if recipes then
		for i = 1, #recipes do
			local recipe = recipes[i]
			local item = recipe and recipe.name and Items(recipe.name)

			if item then
				recipe.weight = item.weight
				recipe.slot = i
			else
				warn(('failed to setup crafting recipe (bench: %s, slot: %s) - item "%s" does not exist'):format(id, i, tostring(recipe and recipe.name)))
			end
		end
	end

	CraftingBenches[id] = built

	return built
end

local function ensureDatabase()
	MySQL.query.await([[
		CREATE TABLE IF NOT EXISTS `ox_crafting_benches` (
			`id` INT NOT NULL AUTO_INCREMENT,
			`type` VARCHAR(64) NOT NULL,
			`owner` VARCHAR(64) NULL,
			`label` VARCHAR(64) NULL,
			`coords` JSON NOT NULL,
			`metadata` JSON NULL,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			PRIMARY KEY (`id`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])

	MySQL.query.await([[
		CREATE TABLE IF NOT EXISTS `ox_crafting_xp` (
			`identifier` VARCHAR(64) NOT NULL,
			`xp` INT NOT NULL DEFAULT 0,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			PRIMARY KEY (`identifier`)
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])

	MySQL.query.await([[
		CREATE TABLE IF NOT EXISTS `ox_crafting_roles` (
			`id` INT NOT NULL AUTO_INCREMENT,
			`bench_id` INT NOT NULL,
			`name` VARCHAR(64) NOT NULL,
			`can_use` TINYINT(1) NOT NULL DEFAULT 1,
			`can_move` TINYINT(1) NOT NULL DEFAULT 0,
			`can_pack` TINYINT(1) NOT NULL DEFAULT 0,
			`can_manage` TINYINT(1) NOT NULL DEFAULT 0,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			`updated_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
			PRIMARY KEY (`id`),
			KEY `idx_crafting_roles_bench` (`bench_id`),
			CONSTRAINT `fk_crafting_roles_bench` FOREIGN KEY (`bench_id`) REFERENCES `ox_crafting_benches`(`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])

	MySQL.query.await([[
		CREATE TABLE IF NOT EXISTS `ox_crafting_role_members` (
			`id` INT NOT NULL AUTO_INCREMENT,
			`bench_id` INT NOT NULL,
			`role_id` INT NOT NULL,
			`identifier` VARCHAR(64) NOT NULL,
			`added_by` VARCHAR(64) NULL,
			`created_at` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
			PRIMARY KEY (`id`),
			KEY `idx_role_members_bench` (`bench_id`),
			KEY `idx_role_members_role` (`role_id`),
			CONSTRAINT `fk_role_members_role` FOREIGN KEY (`role_id`) REFERENCES `ox_crafting_roles`(`id`) ON DELETE CASCADE,
			CONSTRAINT `fk_role_members_bench` FOREIGN KEY (`bench_id`) REFERENCES `ox_crafting_benches`(`id`) ON DELETE CASCADE
		) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
	]])
end

local function registerPlacementItems()
	for typeName, typeConfig in pairs(BenchTypes) do
		local placement = typeConfig.placement

		if placement and placement.item and not PlacementItems[placement.item] then
			PlacementItems[placement.item] = typeName
		end
	end
end

local function registerStaticBenches()
	if type(StaticBenches) ~= 'table' then return end

	for index, bench in ipairs(StaticBenches) do
		local benchId = bench.name or ('bench_static_%s'):format(index)
		registerBench(benchId, bench)
	end
end

local function broadcastDynamicBench(bench)
	local payload = sanitiseBenchForClient(bench)
	TriggerClientEvent('ox_inventory:crafting:addBench', -1, payload)

	local benchId = bench.id or payload.id or payload.name
	if benchId then
		for _, playerId in ipairs(GetPlayers()) do
			local src = tonumber(playerId)
			if src then
				sendBenchPermissions(src, benchId)
			end
		end
	end
end

local function loadPersistentBenches()
	local rows = MySQL.query.await('SELECT * FROM ox_crafting_benches')

	for _, row in ipairs(rows) do
		local coords = type(row.coords) == 'string' and json.decode(row.coords) or row.coords or {}
		local metadata = type(row.metadata) == 'string' and json.decode(row.metadata) or row.metadata or {}

		local vec = vec3(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0)
		local heading = coords.w or metadata.heading or 0.0
		local benchId = ('placed:%s'):format(row.id)

		local benchData = {
			name = metadata.name or benchId,
			type = row.type,
			label = row.label,
			coords = vec,
			heading = heading,
			owner = row.owner,
			dynamic = true,
			persistentId = row.id,
		}

		local bench = registerBench(benchId, benchData)

		if bench then
			bench.dynamic = true
			bench.heading = heading
			bench.coords = vec
			bench.persistentId = row.id

			PlacedBenches[benchId] = {
				id = row.id,
				owner = row.owner,
				type = bench.typeId,
				storageKey = craftingStorageKey(benchId, 1),
				coords = vec,
			}

			loadBenchRoles(benchId, row.id)
			broadcastDynamicBench(bench)
		end
	end
end

CreateThread(function()
	ensureDatabase()
	registerPlacementItems()
	registerStaticBenches()
	loadPersistentBenches()
end)

AddEventHandler('ox_inventory:usedItem', function(invId, itemName, slot, metadata, source)
	local source = source
	local typeName = PlacementItems[itemName]
	if not typeName then return end

	local playerInventory = Inventory(invId)
	if not playerInventory then return end

	local typeConfig = BenchTypes[typeName]
	if not typeConfig then return end

	PendingPlacement[invId] = {
		type = typeName,
		item = itemName,
		slot = slot,
	}

	TriggerClientEvent('ox_inventory:crafting:startPlacement', source , {
		type = typeName,
		item = itemName,
		slot = slot,
		model = typeConfig.model,
		label = typeConfig.label or typeName,
		spawnRange = typeConfig.spawnRange,
		inventory = invId,
	})
end)

local function getBenchById(id)
	return CraftingBenches[id]
end

RegisterNetEvent('ox_inventory:crafting:requestBenches', function()
	local src = source

	for benchId, bench in pairs(CraftingBenches) do
		if bench.dynamic then
			TriggerClientEvent('ox_inventory:crafting:addBench', src, sanitiseBenchForClient(bench))
			sendBenchPermissions(src, benchId)
		end
	end
end)

RegisterNetEvent('ox_inventory:crafting:refreshPermissions', function()
	local src = source

	for benchId, bench in pairs(CraftingBenches) do
		if bench.dynamic then
			sendBenchPermissions(src, benchId)
		end
	end
end)

RegisterNetEvent('ox_inventory:crafting:placementCancelled', function()
	PendingPlacement[source] = nil
end)

RegisterNetEvent('ox_inventory:crafting:placeBench', function(data)
	local src = source

	if type(data) ~= 'table' then
		return
	end

	local pending = PendingPlacement[data.inventory]
	if not pending then
		return
	end

	local typeName = data.type
	if not validatePlacementItem(typeName, pending.item) then
		PendingPlacement[data.inventory] = nil
		return
	end

	local typeConfig = BenchTypes[typeName]
	if not typeConfig then
		PendingPlacement[data.inventory] = nil
		return
	end

	local slot = pending.slot
	local coords = data.coords
	local heading = data.heading or 0.0

	if type(coords) ~= 'table' then
		PendingPlacement[data.inventory] = nil
		return
	end

	local vec = vector3(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0)

	local removed = Inventory.RemoveItem(data.inventory, pending.item, 1, nil, slot)
	if not removed then
		PendingPlacement[data.inventory] = nil
		lib.notify(src, { type = 'error', description = locale('cannot_perform') })
		return
	end

	local identifier = getPlayerIdentifier(src)
	local label = data.label or typeConfig.label or typeName

	local dbId = MySQL.insert.await('INSERT INTO ox_crafting_benches (type, owner, label, coords, metadata) VALUES (?, ?, ?, ?, ?)', {
		typeName,
		identifier,
		label,
		json.encode({ x = vec.x, y = vec.y, z = vec.z, w = heading }),
		json.encode({ name = label }),
	})

	if not dbId or dbId < 1 then
		Inventory.AddItem(src, pending.item, 1)
		PendingPlacement[data.inventory] = nil
		lib.notify(src, { type = 'error', description = locale('cannot_perform') })
		return
	end

	local benchId = ('placed:%s'):format(dbId)
	local benchData = {
		name = label,
		type = typeName,
		label = label,
		coords = vec,
		heading = heading,
		owner = identifier,
		dynamic = true,
		persistentId = dbId,
	}

	local bench = registerBench(benchId, benchData)

	if bench then
		bench.dynamic = true
		bench.heading = heading
		bench.coords = vec
		bench.persistentId = dbId

		PlacedBenches[benchId] = {
			id = dbId,
			owner = identifier,
			type = bench.typeId,
			storageKey = craftingStorageKey(benchId, 1),
			coords = vec,
		}

		loadBenchRoles(benchId, dbId)
		broadcastDynamicBench(bench)
		lib.notify(src, { type = 'success', description = locale('crafting_bench_placed') or 'Bench placed.' })
	else
		Inventory.AddItem(src, pending.item, 1)
	end

	PendingPlacement[data.inventory] = nil
end)

RegisterNetEvent('ox_inventory:crafting:requestMoveBench', function(benchId)
	local src = source
	local bench = benchId and CraftingBenches[benchId]
	if not bench or not bench.dynamic then return end

	local record = PlacedBenches[benchId]
	if not record then return end

	if not hasBenchPermission(src, benchId, 'move') then return end

	local coords = bench.coords or vec3(0.0, 0.0, 0.0)

	TriggerClientEvent('ox_inventory:crafting:startMove', src, {
		id = benchId,
		model = bench.model,
		coords = { x = coords.x, y = coords.y, z = coords.z },
		heading = bench.heading or 0.0,
		label = bench.label or benchId,
		spawnRange = bench.spawnRange,
	})
end)

RegisterNetEvent('ox_inventory:crafting:moveBench', function(benchId, payload)
	local src = source
	local bench = benchId and CraftingBenches[benchId]
	if not bench or not bench.dynamic then return end

	local record = PlacedBenches[benchId]
	if not record then return end

	if not hasBenchPermission(src, benchId, 'move') then return end

	if type(payload) ~= 'table' or not payload.coords then return end

	local coords = payload.coords
	local vec = vec3(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0)
	local heading = payload.heading or 0.0

	bench.coords = vec
	bench.heading = heading
	record.coords = vec

	local storageKey = craftingStorageKey(benchId, 1)
	local storageId = CraftingStorages[storageKey]
	local storage = storageId and Inventory(storageId)

	if storage then
		storage.coords = vec
	end

	if record.id then
		MySQL.update.await('UPDATE ox_crafting_benches SET coords = ? WHERE id = ?', {
			json.encode({ x = vec.x, y = vec.y, z = vec.z, w = heading }),
			record.id
		})
	end

	broadcastDynamicBench(bench)
end)

RegisterNetEvent('ox_inventory:crafting:packBench', function(benchId)
	local src = source
	local bench = benchId and CraftingBenches[benchId]
	if not bench or not bench.dynamic then return end

	local record = PlacedBenches[benchId]
	if not record then return end

	if not hasBenchPermission(src, benchId, 'pack') then
		return
	end

	local typeConfig = bench.typeConfig or (bench.typeId and BenchTypes[bench.typeId])
	if not typeConfig or not typeConfig.placement or not typeConfig.placement.item then
		return
	end

	local storageKey = craftingStorageKey(benchId, 1)
	local storageId = CraftingStorages[storageKey]
	local storage = storageId and Inventory(storageId)



	CraftingBenches[benchId] = nil
	PlacedBenches[benchId] = nil
	MySQL.update.await('DELETE FROM ox_crafting_benches WHERE id = ?', { record.id })
	clearBenchRoles(benchId, record.id)

	TriggerClientEvent('ox_inventory:crafting:removeBench', -1, benchId)
	TriggerClientEvent('ox_inventory:crafting:updatePermissions', -1, { id = benchId, removed = true })

	Inventory.AddItem(src, typeConfig.placement.item, 1)
	lib.notify(src, { type = 'success', description = locale('crafting_bench_packed') or 'Bench packed up.' })
end)

lib.callback.register('ox_inventory:openCraftingBench', function(source, id, index)
	local left, bench = Inventory(source), getBenchById(id)

	if not left then return end

	if bench then
		local groups = bench.groups
		local coords = getCraftingCoords(source, bench, index)

		if not coords then return end
		print(groups)
		if groups and not server.hasGroup(left, groups) then
			
			
			return nil, nil, 'inventory_right_access'
		end

		if not hasBenchPermission(source, id, 'use') then
			return nil, nil, 'crafting_no_permission'
		end
		if #(GetEntityCoords(GetPlayerPed(source)) - coords) > 10 then return end

		if left.open and left.open ~= source then
			local inv = Inventory(left.open)

			if inv?.player then
				inv:closeInventory()
			end
		end

		left:openInventory(left)

		local storage = getCraftingStorage(source, id, bench, index)
		local xp = getPlayerXP(source)
		local blueprints = collectBlueprints(source, storage)

		local storagePayload

		if storage then
			storagePayload = {
				id = storage.id,
				label = storage.label,
				type = 'backpack',
				slots = storage.slots,
				maxWeight = storage.maxWeight,
				weight = storage.weight,
				items = storage.items,
			}
		end

		return {
			label = left.label,
			type = left.type,
			slots = left.slots,
			weight = left.weight,
			maxWeight = left.maxWeight,
			storage = storagePayload,
			crafting = {
				id = id,
				type = bench.typeId,
				xp = {
					enabled = XPConfig.enabled or false,
					current = xp,
					hideLocked = bench.hideLocked ~= nil and bench.hideLocked or XPConfig.hideLocked or false
				},
				blueprints = blueprints,
				queue = (function()
					local q = getPlayerQueue(source)
					local out = {}
					for i = 1, #q do
						local job = q[i]
						local remaining = nil
						if job.startedAt then
							remaining = math.max(0, job.startedAt + job.duration - os.time())
						end

						out[i] = {
							benchId = job.benchId,
							recipe = job.recipe and job.recipe.name,
							recipeSlot = job.recipeSlot,
							craftCount = job.craftCount,
							startedAt = job.startedAt,
							duration = job.duration,
							remaining = remaining
						}
					end
					return out
				end)(),
			}
		}
	end
end)

local TriggerEventHooks = require 'modules.hooks.server'

lib.callback.register('ox_inventory:craftItem', function(source, id, index, recipeSlot, toSlot, storageId, count)
	local playerInventory, bench = Inventory(source), getBenchById(id)
	if not playerInventory then return end
	count = math.max(1, tonumber(count) or 1)

	if bench then
		local groups = bench.groups
		local coords = getCraftingCoords(source, bench, index)

		if not coords then return end

		if groups and not server.hasGroup(playerInventory, groups) then return end
		if #(GetEntityCoords(GetPlayerPed(source)) - coords) > 10 then return end

		local storage = storageId and Inventory(storageId) or getCraftingStorage(source, id, bench, index)
		local targetInventory = storage or playerInventory

		if storage then
			local previousStorageId = CraftingStoragePlayers[source]
			if previousStorageId and previousStorageId ~= storage.id then
				local previousStorage = Inventory(previousStorageId)
				if previousStorage then
					previousStorage.openedBy[source] = nil
				end
			end

			storage.openedBy[source] = true
			CraftingStoragePlayers[source] = storage.id
		end

		local recipe = bench.items and bench.items[recipeSlot]

		if recipe then
			local function queueCraft()
				if XPConfig.enabled then
					local currentXp = getPlayerXP(source)
					local requiredXp = recipe.xp and recipe.xp.required or 0

					if requiredXp and currentXp < requiredXp then
						return false, 'crafting_missing_xp'
					end
				end

				if recipe.blueprint and not playerHasBlueprint(source, recipe.blueprint, storage) then
					return false, 'crafting_missing_blueprint'
				end

				local tbl, num = {}, 0

				for name in pairs(recipe.ingredients) do
					num += 1
					tbl[num] = name
				end

				local craftedItem = Items(recipe.name)
				local craftCount = (type(recipe.count) == 'number' and recipe.count) or (table.type(recipe.count) == 'array' and math.random(recipe.count[1], recipe.count[2])) or 1

				local newWeight = targetInventory.weight
				local items = Inventory.Search(targetInventory, 'slots', tbl) or {}

				for name, needs in pairs(recipe.ingredients) do
					if needs > 0 then
						local item = Items(name)
						if item then
							newWeight -= (item.weight * needs)
						end
					end
				end

				newWeight += (craftedItem.weight + (recipe.metadata?.weight or 0)) * craftCount

				if newWeight > targetInventory.maxWeight then return false, 'cannot_carry' end

				items = Inventory.Search(targetInventory, 'slots', tbl) or {}
				table.wipe(tbl)

				for name, needs in pairs(recipe.ingredients) do
					if needs == 0 then break end

					local slots = items[name] or items

					if #slots == 0 then return end

					for i = 1, #slots do
						local slot = slots[i]

						if needs == 0 then
							if not slot.metadata.durability or slot.metadata.durability > 0 then
								break
							end
						elseif needs < 1 then
							local item = Items(name)
							local durability = slot.metadata.durability

							if durability and durability >= needs * 100 then
								if durability > 100 then
									local degrade = (slot.metadata.degrade or item.degrade) * 60
									local percentage = ((durability - os.time()) * 100) / degrade

									if percentage >= needs * 100 then
										tbl[slot.slot] = needs
										break
									end
								else
									tbl[slot.slot] = needs
									break
								end
							end
						elseif needs <= slot.count then
							tbl[slot.slot] = needs
							break
						else
							tbl[slot.slot] = slot.count
							needs -= slot.count
						end

						if needs == 0 then break end
						if needs > 0 and i == #slots then return end
					end
				end

				if not TriggerEventHooks('craftItem', {
					source = source,
					benchId = id,
					benchIndex = index,
					recipe = recipe,
					toInventory = targetInventory.id,
					toSlot = toSlot,
					storageId = storage and storage.id,
				}) then return false end

				
				for name, needs in pairs(recipe.ingredients) do
					if Inventory.GetItemCount(targetInventory, name) < needs then return false end
				end

				
				if recipe.blueprint and storage then
					local consumed = consumeBlueprint(storage, recipe.blueprint)
					if not consumed then
						
						return false, 'crafting_blueprint_consume_failed'
					end
				end

				for slot, count in pairs(tbl) do
					local invSlot = targetInventory.items[slot]

					if not invSlot then return end

					if count < 1 then
						local item = Items(invSlot.name)
						local durability = invSlot.metadata.durability or 100

						if durability > 100 then
							local degrade = (invSlot.metadata.degrade or item.degrade) * 60
							durability -= degrade * count
						else
							durability -= count * 100
						end

						if invSlot.count > 1 then
							local emptySlot = Inventory.GetEmptySlot(targetInventory)

							if emptySlot then
								local newItem = Inventory.SetSlot(targetInventory, item, 1, deepCopy(invSlot.metadata), emptySlot)

								if newItem then
									Items.UpdateDurability(targetInventory, newItem, item, durability < 0 and 0 or durability)
								end
							end

							invSlot.count -= 1
							invSlot.weight = Inventory.SlotWeight(item, invSlot)

							targetInventory:syncSlotsWithClients({
								{
									item = invSlot,
									inventory = targetInventory.id
								}
							}, true)
						else
							Items.UpdateDurability(targetInventory, invSlot, item, durability < 0 and 0 or durability)
						end
					else
						local removed = invSlot and Inventory.RemoveItem(targetInventory, invSlot.name, count, nil, slot)
						if not removed then return end
					end
				end

						
						CraftingNextId = (CraftingNextId or 0) + 1
						local duration = recipe.duration or 3000
						local q = getPlayerQueue(source)
						local isEmpty = (#q == 0)
						local job = {
							id = CraftingNextId,
							benchId = id,
							recipe = recipe,
							recipeSlot = recipeSlot,
							craftedItem = craftedItem,
							craftCount = craftCount,
							duration = duration / 1000, 
							startedAt = isEmpty and os.time() or nil,
							targetInventory = targetInventory,
							storage = storage,
							toSlot = toSlot,
							source = source,
						}

						q[#q+1] = job
						sendQueueUpdate(source)

						
						if isEmpty then
							SetTimeout((job.duration or 3) * 1000, function()
								
								local q2 = getPlayerQueue(source)
								local idx = nil
								for i = 1, #q2 do
									if q2[i].id == job.id then idx = i break end
								end

								if idx then
									completeCraftJob(idx, source)
								end
							end)
						end

				return true
			end

			for i = 1, count do
				local ok, err = queueCraft()
				if not ok then return ok, err end
			end

			return true
		end
	end
end)

lib.callback.register('ox_inventory:cancelCraft', function(source, benchId, jobIndex)
	local q = getPlayerQueue(source)
	local job = q[jobIndex]

	if not job or job.benchId ~= benchId then return false end

	local refundInv = job.targetInventory
	if not refundInv then return false end

	local recipe = job.recipe
	if recipe and recipe.ingredients then
		for name, count in pairs(recipe.ingredients) do
			if count > 0 then
				if count >= 1 then
					local refundAmount = count
					local added = Inventory.AddItem(refundInv, name, refundAmount)
					if not added then
						if refundInv.id ~= source then
							Inventory.AddItem(source, name, refundAmount)
						else
							Inventory.AddItem(source, name, refundAmount)
						end
					end
				else
					local durabilityToRestore = count * 100
					
					local items = Inventory.Search(refundInv, 'slots', name)
					if items then
						for _, item in pairs(items) do
							if item.metadata and item.metadata.durability and item.metadata.durability < 100 then
								local current = item.metadata.durability
								local newDurability = math.min(100, current + durabilityToRestore)
								
								if newDurability > current then
									Items.UpdateDurability(refundInv, item, Items(item.name), newDurability)
									
									durabilityToRestore = durabilityToRestore - (newDurability - current)
									if durabilityToRestore <= 0.1 then break end -- Floating point safety
								end
							end
						end
					end
				end
			end
		end
	end

	table.remove(q, jobIndex)
	
	if jobIndex == 1 then
		local nextJob = q[1]
		if nextJob then
			nextJob.startedAt = os.time()
			
			SetTimeout((nextJob.duration or 3) * 1000, function()
				local q2 = getPlayerQueue(source)
				local idx = nil
				for i = 1, #q2 do
					if q2[i].id == nextJob.id then idx = i break end
				end

				if idx then
					completeCraftJob(idx, source)
				end
			end)
		end
	end

	sendQueueUpdate(source)
	return true
end)

AddEventHandler('ox_inventory:closeInventory', function()
	releaseStorageForPlayer(source)
end)


lib.callback.register('ox_inventory:crafting:getBenchPermissions', function(source, benchId)
	if type(benchId) ~= 'string' then
		return false, 'crafting_not_found'
	end

	local payload, err = buildBenchPermissionsPayload(source, benchId)
	if not payload then
		return false, err or 'crafting_no_permission'
	end

	return payload
end)

lib.callback.register('ox_inventory:crafting:createRole', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local benchId = data.benchId
	local name = trim(data.name) or ''
	local permissions = data.permissions or {}

	if type(benchId) ~= 'string' then
		return false, 'crafting_not_found'
	end

	local allowed, record = canManageBench(source, benchId)
	if not allowed or not record or not record.id then
		return false, 'crafting_no_permission'
	end

	if name == '' then
		name = locale('crafting_role_new') or 'Role'
	end

	local canUse = permissions.use and 1 or 0
	local canMove = permissions.move and 1 or 0
	local canPack = permissions.pack and 1 or 0
	local canManage = permissions.manage and 1 or 0

	MySQL.insert.await('INSERT INTO ox_crafting_roles (bench_id, name, can_use, can_move, can_pack, can_manage) VALUES (?, ?, ?, ?, ?, ?)', {
		record.id,
		name,
		canUse,
		canMove,
		canPack,
		canManage,
	})

	loadBenchRoles(benchId, record.id)
	notifyBenchMembers(benchId, true)

	return buildBenchPermissionsPayload(source, benchId)
end)

lib.callback.register('ox_inventory:crafting:updateRole', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local benchId = data.benchId
	local roleId = data.roleId
	local name = trim(data.name) or ''
	local permissions = data.permissions or {}

	if type(benchId) ~= 'string' or type(roleId) ~= 'number' then
		return false, 'invalid_data'
	end

	local allowed, record = canManageBench(source, benchId)
	if not allowed or not record or not record.id then
		return false, 'crafting_no_permission'
	end

	local roleRow = MySQL.single.await('SELECT bench_id FROM ox_crafting_roles WHERE id = ?', { roleId })
	if not roleRow or roleRow.bench_id ~= record.id then
		return false, 'crafting_not_found'
	end

	if name == '' then
		name = locale('crafting_role_new') or 'Role'
	end

	local canUse = permissions.use and 1 or 0
	local canMove = permissions.move and 1 or 0
	local canPack = permissions.pack and 1 or 0
	local canManage = permissions.manage and 1 or 0

	MySQL.update.await('UPDATE ox_crafting_roles SET name = ?, can_use = ?, can_move = ?, can_pack = ?, can_manage = ? WHERE id = ?', {
		name,
		canUse,
		canMove,
		canPack,
		canManage,
		roleId,
	})

	loadBenchRoles(benchId, record.id)
	notifyBenchMembers(benchId, true)

	return buildBenchPermissionsPayload(source, benchId)
end)

lib.callback.register('ox_inventory:crafting:deleteRole', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local benchId = data.benchId
	local roleId = data.roleId
	if type(benchId) ~= 'string' or type(roleId) ~= 'number' then
		return false, 'invalid_data'
	end

	local allowed, record = canManageBench(source, benchId)
	if not allowed or not record or not record.id then
		return false, 'crafting_no_permission'
	end

	local rolesCache = getBenchRolesCache(benchId)
	local role = rolesCache and rolesCache.list and rolesCache.list[roleId]
	if not role then
		return false, 'crafting_not_found'
	end

	if role.members and #role.members > 0 then
		return false, 'crafting_role_has_members'
	end

	MySQL.update.await('DELETE FROM ox_crafting_roles WHERE id = ? AND bench_id = ?', { roleId, record.id })

	loadBenchRoles(benchId, record.id)
	notifyBenchMembers(benchId, true)

	return buildBenchPermissionsPayload(source, benchId)
end)

lib.callback.register('ox_inventory:crafting:setMemberRole', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local benchId = data.benchId
	local roleId = data.roleId
	local target = data.target

	if type(benchId) ~= 'string' then
		return false, 'invalid_data'
	end

	local allowed, record = canManageBench(source, benchId)
	if not allowed or not record or not record.id then
		return false, 'crafting_no_permission'
	end

	local identifier, resolvedSource = resolveIdentifier(target)
	if not identifier then
		return false, 'crafting_invalid_member'
	end

	local rolesCache = getBenchRolesCache(benchId)
	local previousRoleId = rolesCache and rolesCache.memberIndex and rolesCache.memberIndex[identifier]

	MySQL.update.await('DELETE FROM ox_crafting_role_members WHERE bench_id = ? AND identifier = ?', { record.id, identifier })

	if roleId and type(roleId) == 'number' then
		local role = rolesCache and rolesCache.list and rolesCache.list[roleId]
		if not role then
			return false, 'crafting_not_found'
		end

		MySQL.insert.await('INSERT INTO ox_crafting_role_members (bench_id, role_id, identifier, added_by) VALUES (?, ?, ?, ?)', {
			record.id,
			roleId,
			identifier,
			getPlayerIdentifier(source),
		})
	end

	loadBenchRoles(benchId, record.id)
	notifyBenchMembers(benchId, true)

	local payload, err = buildBenchPermissionsPayload(source, benchId)
	if resolvedSource then
		sendBenchPermissions(resolvedSource, benchId)
	elseif previousRoleId then
		local targetSrc = getOnlineSourceByIdentifier(identifier)
		if targetSrc then
			sendBenchPermissions(targetSrc, benchId)
		end
	end

	return payload, err
end)

lib.callback.register('ox_inventory:crafting:transferOwnership', function(source, data)
	if type(data) ~= 'table' then
		return false, 'invalid_data'
	end

	local benchId = data.benchId
	local target = data.target
	if type(benchId) ~= 'string' then
		return false, 'invalid_data'
	end

	local allowed, record = canManageBench(source, benchId)
	local identifier = getPlayerIdentifier(source)
	if not allowed or not record or record.owner ~= identifier then
		return false, 'crafting_no_permission'
	end

	local newIdentifier, resolvedSource = resolveIdentifier(target)
	if not newIdentifier or newIdentifier == record.owner then
		return false, 'crafting_invalid_member'
	end

	MySQL.update.await('UPDATE ox_crafting_benches SET owner = ? WHERE id = ?', { newIdentifier, record.id })
	record.owner = newIdentifier
	PlacedBenches[benchId].owner = newIdentifier
	if CraftingBenches[benchId] then
		CraftingBenches[benchId].owner = newIdentifier
	end

	MySQL.update.await('DELETE FROM ox_crafting_role_members WHERE bench_id = ? AND identifier = ?', { record.id, newIdentifier })

	loadBenchRoles(benchId, record.id)

	local oldOwnerSource = getOnlineSourceByIdentifier(identifier)
	if oldOwnerSource then
		sendBenchPermissions(oldOwnerSource, benchId)
	end

	if resolvedSource then
		sendBenchPermissions(resolvedSource, benchId)
	end

	notifyBenchMembers(benchId, true)

	return buildBenchPermissionsPayload(source, benchId)
end)
AddEventHandler('playerDropped', function()
	releaseStorageForPlayer(source)
	PendingPlacement[source] = nil
end)


AddEventHandler('ox_inventory:onInventoryChanged', function(invId)
	local inv = Inventory(invId)
	if not inv or inv.type ~= 'stash' then return end
	
	
	local isCraftingStorage = false
	for _, storageId in pairs(CraftingStorages) do
		if storageId == invId then
			isCraftingStorage = true
			break
		end
	end
	
	if not isCraftingStorage then return end
	
	
	if inv.openedBy then
		for playerId in pairs(inv.openedBy) do
			notifyBlueprintUpdate(playerId, inv)
		end
	end
end)


exports.ox_inventory:registerHook('swapItems', function(payload)
	local toInventory = payload.toInventory and Inventory(payload.toInventory)
	local fromInventory = payload.fromInventory and Inventory(payload.fromInventory)
	
	
	if toInventory and toInventory.type == 'stash' then
		for _, storageId in pairs(CraftingStorages) do
			if storageId == toInventory.id then
				
				if toInventory.openedBy then
					for playerId in pairs(toInventory.openedBy) do
						SetTimeout(100, function()
							notifyBlueprintUpdate(playerId, toInventory)
						end)
					end
				end
				break
			end
		end
	end
	
	
	if fromInventory and fromInventory.type == 'stash' then
		for _, storageId in pairs(CraftingStorages) do
			if storageId == fromInventory.id then
				
				if fromInventory.openedBy then
					for playerId in pairs(fromInventory.openedBy) do
						SetTimeout(100, function()
							notifyBlueprintUpdate(playerId, fromInventory)
						end)
					end
				end
				break
			end
		end
	end
	
	return true
end, {
	print = false
})








RegisterNetEvent('ox_inventory:crafting:requestBlueprint', function(metadataKey, metadataValue)
	local src = source
	local identifier = getPlayerIdentifier(src)
	if not identifier then
		return
	end

	for key, blueprint in pairs(BlueprintConfig) do
		if blueprint.metadataKey == metadataKey and blueprint.metadataValue == metadataValue then
			giveBlueprintToPlayer(src, key)
			break
		end
	end
end)
