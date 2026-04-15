-- Ensure digit grouping is always available before any early return.
if not math.groupdigits then
	function math.groupdigits(number, separator)
		if lib and lib.math and lib.math.groupdigits then
			return lib.math.groupdigits(number, separator)
		end
		local sep = separator or ','
		local num = tonumber(number) or 0
		local sign = num < 0 and '-' or ''
		local s = tostring(math.abs(num))
		local int, frac = s:match('^(%d+)(%.%d+)$')
		int = int or s
		local grouped = int:reverse():gsub('(%d%d%d)', '%1' .. sep):reverse():gsub('^' .. sep, '')
		if frac then grouped = grouped .. frac end
		return sign .. grouped
	end
end

if not lib then return end

require 'modules.bridge.server'
require 'modules.crafting.server'
require 'modules.shops.server'
require 'modules.pefcl.server'
local Utility = require 'modules.utility.server'

if GetConvar('inventory:versioncheck', 'true') == 'true' then
	lib.versionCheck('overextended/ox_inventory')
end

local TriggerEventHooks = require 'modules.hooks.server'
local db = require 'modules.mysql.server'
local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'

local AmmoPoolTemplate = {
	pistol = { clip = 0, reserve = 0, maxReserve = 250 },
	rifle = { clip = 0, reserve = 0, maxReserve = 350 },
	shotgun = { clip = 0, reserve = 0, maxReserve = 125 },
	smg = { clip = 0, reserve = 0, maxReserve = 350 },
	sniper = { clip = 0, reserve = 0, maxReserve = 150 },
}

local PlayerAmmoPools = {}
local DirtyPlayerAmmoPools = {}
local PURE_ADMIN_RESOURCE_NAME = 'pure_admin'

local function getPlayerIdentifierSummary(playerSource)
	if type(playerSource) ~= 'number' or playerSource <= 0 then
		return {}
	end

	return {
		discord = GetPlayerIdentifierByType(playerSource, 'discord'),
		fivem = GetPlayerIdentifierByType(playerSource, 'fivem'),
		license = GetPlayerIdentifierByType(playerSource, 'license2') or GetPlayerIdentifierByType(playerSource, 'license'),
	}
end

function PureAdminBuildCommandActor(playerSource)
	if type(playerSource) ~= 'number' or playerSource <= 0 then
		return {
			source = 0,
			label = 'console',
			owner = 'console',
			name = 'console',
			identifiers = {},
		}
	end

	local actorInventory = Inventory(playerSource)

	return {
		source = playerSource,
		label = actorInventory and actorInventory.label or GetPlayerName(playerSource) or tostring(playerSource),
		owner = actorInventory and actorInventory.owner or tostring(playerSource),
		name = GetPlayerName(playerSource) or tostring(playerSource),
		identifiers = getPlayerIdentifierSummary(playerSource),
	}
end

local function attachTargetIdentifiers(targetData, targetSource)
	if type(targetSource) == 'number' and targetSource > 0 then
		targetData.identifiers = getPlayerIdentifierSummary(targetSource)
	end

	return targetData
end

function PureAdminBuildRawCommand(commandName, args)
	local parts = { '/' .. tostring(commandName) }

	for i = 1, #(args or {}) do
		parts[#parts + 1] = tostring(args[i])
	end

	return table.concat(parts, ' ')
end

local function getSecondaryInventoryType(source, invType, right)
	if right and right.player and right.id ~= source then
		return 'otherplayer'
	end

	return (right and right.type) or invType or 'unknown'
end

local function buildSecondaryInventoryTarget(source, right, fallbackType)
	if not right then
		return nil
	end

	local targetType = getSecondaryInventoryType(source, fallbackType, right)
	local targetData = {
		id = right.id,
		type = targetType,
		label = right.label,
		owner = right.owner,
	}

	if right.netid then
		targetData.netId = right.netid
	end

	if right.player and right.id ~= source then
		targetData.name = GetPlayerName(right.id) or tostring(right.id)
		return attachTargetIdentifiers(targetData, right.id)
	end

	return targetData
end

function PureAdminLogger(playerSource, eventName, message, data)
	local resourceState = GetResourceState(PURE_ADMIN_RESOURCE_NAME)

	if resourceState ~= 'started' then
		return
	end

	local ok, errorMessage = pcall(function()
		exports[PURE_ADMIN_RESOURCE_NAME]:logger(playerSource, eventName, message, data)
	end)

	if not ok and server and server.loglevel and server.loglevel > 1 then
		lib.print.warn(('[ox_inventory] pure_admin logger failed: %s'):format(tostring(errorMessage)))
	end
end

local function ammoDebug(message, ...)
	if not server.ammodebug then return end

	local parts = table.pack(...)
	for i = 1, parts.n do
		parts[i] = tostring(parts[i])
	end

	shared.info('[ammo-debug]', message, table.unpack(parts, 1, parts.n))
end

local function copyAmmoPoolState(state, defaults)
	local defaultState = defaults or state or {}
	local maxReserve = math.max(0, tonumber(state?.maxReserve) or tonumber(defaultState?.maxReserve) or 0)

	return {
		clip = math.max(0, tonumber(state?.clip) or 0),
		reserve = math.min(math.max(0, tonumber(state?.reserve) or 0), maxReserve),
		maxReserve = maxReserve,
	}
end

local function sanitiseAmmoPools(data)
	local pools = {}

	if type(data) == 'string' and data ~= '' then
		data = json.decode(data)
	end

	if type(data) ~= 'table' then
		data = {}
	end

	for key, defaultState in pairs(AmmoPoolTemplate) do
		pools[key] = copyAmmoPoolState(data[key] or defaultState, defaultState)
	end

	return pools
end

local function getWeaponAmmoPoolKey(item)
	if not item?.weapon then return end

	local ammoName = item.ammoname

	if item.name == 'WEAPON_TECPISTOL' or item.name == 'WEAPON_MACHINEPISTOL' or item.name == 'WEAPON_MINISMG'
		or item.name == 'WEAPON_MICROSMG' or item.name == 'WEAPON_SMG' or item.name == 'WEAPON_SMG_MK2'
		or item.name == 'WEAPON_COMBATPDW' or item.name == 'WEAPON_ASSAULTSMG'
	then
		return 'smg'
	elseif ammoName == 'ammo-9' or ammoName == 'ammo-22' or ammoName == 'ammo-38' or ammoName == 'ammo-44' or ammoName == 'ammo-45' or ammoName == 'ammo-50' then
		return 'pistol'
	elseif ammoName == 'ammo-rifle' or ammoName == 'ammo-rifle2' or ammoName == 'rifle_ammo' then
		return 'rifle'
	elseif ammoName == 'ammo-shotgun' or ammoName == 'ammo-musket' or ammoName == 'shotgun_ammo' then
		return 'shotgun'
	elseif ammoName == 'smg_ammo' then
		return 'smg'
	elseif ammoName == 'ammo-sniper' or ammoName == 'ammo-heavysniper' then
		return 'sniper'
	elseif ammoName == 'ammo-emp' or ammoName == 'ammo-flare' or ammoName == 'ammo-firework' or ammoName == 'pistol_ammo' then
		return 'pistol'
	end
end

local function loadPlayerAmmoPools(identifier)
	local pools = PlayerAmmoPools[identifier]

	if pools then
		ammoDebug('cache hit for citizenid', identifier, json.encode(pools))
		return pools
	end

	local rawAmmo = db.loadPlayerAmmo(identifier)
	ammoDebug('loadPlayerAmmo raw result for citizenid', identifier, rawAmmo)
	pools = sanitiseAmmoPools(rawAmmo)
	PlayerAmmoPools[identifier] = pools
	DirtyPlayerAmmoPools[identifier] = nil
	ammoDebug('sanitised ammo pools for citizenid', identifier, json.encode(pools))

	return pools
end

local function markPlayerAmmoPoolsDirty(identifier)
	if not identifier then return end
	DirtyPlayerAmmoPools[identifier] = true
end

local function savePlayerAmmoPools(identifier, force)
	local pools = PlayerAmmoPools[identifier]

	if not identifier or not pools then return end
	if not force and not DirtyPlayerAmmoPools[identifier] then return end

	local payload = json.encode(sanitiseAmmoPools(pools))
	ammoDebug('saving ammo pools for citizenid', identifier, payload)
	local result = db.savePlayerAmmo(identifier, payload)
	ammoDebug('savePlayerAmmo result for citizenid', identifier, result)
	DirtyPlayerAmmoPools[identifier] = nil
end

local function saveDirtyPlayerAmmoPools()
	for identifier in pairs(DirtyPlayerAmmoPools) do
		savePlayerAmmoPools(identifier, true)
	end
end

function server.loadPlayerAmmoPools(identifier)
	return loadPlayerAmmoPools(identifier)
end

function server.savePlayerAmmoPools(playerIdOrIdentifier)
	local identifier = playerIdOrIdentifier

	if type(playerIdOrIdentifier) == 'number' then
		local inventory = Inventory(playerIdOrIdentifier)
		identifier = inventory?.owner
		ammoDebug('resolved player source to citizenid for save', playerIdOrIdentifier, identifier)
	end

	savePlayerAmmoPools(identifier, true)
end

function server.saveDirtyPlayerAmmoPools()
	saveDirtyPlayerAmmoPools()
end

function server.clearPlayerAmmoPools(playerIdOrIdentifier)
	local identifier = playerIdOrIdentifier

	if type(playerIdOrIdentifier) == 'number' then
		local inventory = Inventory(playerIdOrIdentifier)
		identifier = inventory?.owner
	end

	if identifier then
		PlayerAmmoPools[identifier] = nil
		DirtyPlayerAmmoPools[identifier] = nil
	end
end

local function serialiseWeaponMagazineInventory(inv)
	if not inv then return nil end

	local items = table.create(inv.slots, 0)

	for slot = 1, inv.slots do
		local item = inv.items[slot]
		items[slot] = item and table.clone(item) or { slot = slot }
	end

	return {
		id = tostring(inv.id),
		type = 'weaponmag',
		label = inv.label or 'Magazine',
		slots = inv.slots,
		weight = inv.weight,
		maxWeight = inv.maxWeight,
		items = items,
	}
end

---@param player table
---@param data table?
--- player requires source, identifier, and name
--- optionally, it should contain jobs/groups, sex, and dateofbirth
function server.setPlayerInventory(player, data)
	while not shared.ready do Wait(0) end

	if not data then
		data = db.loadPlayer(player.identifier)
	end

	local ammoPools = loadPlayerAmmoPools(player.identifier)

	local inventory = {}
	local totalWeight = 0

	if type(data) == 'table' then
		local ostime = os.time()

		for _, v in pairs(data) do
			if type(v) == 'number' or not v.count or not v.slot then
				if server.convertInventory then
					inventory, totalWeight = server.convertInventory(player.source, data)
					break
				else
					return error(('Inventory for player.%s (%s) contains invalid data. Ensure you have converted inventories to the correct format.'):format(player.source, GetPlayerName(player.source)))
				end
			else
				local item = Items(v.name)

				if item then
					v.metadata = Items.CheckMetadata(v.metadata or {}, item, v.name, ostime)
					local ammoPoolKey = getWeaponAmmoPoolKey(item)

					if ammoPoolKey then
						local ammoState = ammoPools[ammoPoolKey] or AmmoPoolTemplate[ammoPoolKey]
						v.metadata.ammo = ammoState.clip
						v.metadata.loadedMagazine = nil
						v.metadata.specialAmmo = nil
						v.metadata.reserve = ammoState.reserve
						v.metadata.maxReserve = ammoState.maxReserve
					end

					local weight = Inventory.SlotWeight(item, v)
					totalWeight = totalWeight + weight

					inventory[v.slot] = {name = item.name, label = item.label, weight = weight, slot = v.slot, count = v.count, description = item.description, metadata = v.metadata, stack = item.stack, close = item.close}
				end
			end
		end
	end

	player.source = tonumber(player.source)
	local inv = Inventory.Create(player.source, player.name, 'player', shared.playerslots, totalWeight, shared.playerweight, player.identifier, inventory)

	if inv then
		inv.player = server.setPlayerData(player)
		inv.player.ammoPools = sanitiseAmmoPools(ammoPools)
		inv.ammoPools = inv.player.ammoPools
		inv.player.ped = GetPlayerPed(player.source)

		if server.syncInventory then server.syncInventory(inv) end
		TriggerClientEvent('ox_inventory:setPlayerInventory', player.source, Inventory.Drops, inventory, totalWeight, inv.player)
	end
end
exports('setPlayerInventory', server.setPlayerInventory)
AddEventHandler('ox_inventory:setPlayerInventory', server.setPlayerInventory)

local registeredDumpsters = {}

---@param coords vector3
---@return string?
local function getDumpsterFromCoords(coords)
	local found

	for i = 1, #registeredDumpsters do
		local distance = #(coords - registeredDumpsters[i])

		if distance < 0.1 then
			found = i
			break
		end
	end

	return found
end

---@param playerPed number
---@param stash OxInventory
---@return vector3?
local function getClosestStashCoords(playerPed, stash)
	local playerCoords = GetEntityCoords(playerPed)
	local distance = stash.distance or 10
    local coordinates = stash.coords

    if not coordinates then return end

	if type(coordinates) == 'table' then
		for i = 1, #coordinates do
			local coords = coordinates[i] --[[@as vector3]]

			if #(coords - playerCoords) < distance then
				return coords
			end
		end

		return
	end

	return #(coordinates - playerCoords) < distance and coordinates or nil
end

---@param source number
---@param invType string
---@param data? string|number|table
---@param ignoreSecurityChecks boolean?
---@return table | false | nil, table | false | nil, string?
local function openInventory(source, invType, data, ignoreSecurityChecks)
	if Inventory.Lock then return false end

	local left = Inventory(source)
	local right, closestCoords

    if not left then return end

    left:closeInventory(true)
	Inventory.CloseAll(left, source)

    if invType == 'player' and data == source then
        data = nil
    end

    local playerPed = left.player.ped

	if data then
        local isDataTable = type(data) == 'table'

		if invType == 'stash' then
			right = Inventory(data, left, ignoreSecurityChecks)
			if right == false then return false end
		elseif isDataTable then
			if data.netid then
                local entity = NetworkGetEntityFromNetworkId(data.netid)

                if not entity then return end

                if not ignoreSecurityChecks then
                    if #(GetEntityCoords(playerPed) - GetEntityCoords(entity)) > 16 then return end
                end

                if invType == 'glovebox' then
                    if not ignoreSecurityChecks and GetVehiclePedIsIn(playerPed, false) ~= entity then
                        return
                    end
                end

                if invType == 'trunk' then
                    local lockStatus = ignoreSecurityChecks and 0 or GetVehicleDoorLockStatus(entity)

                    -- 0: no lock; 1: unlocked; 8: boot unlocked
                    if lockStatus > 1 and lockStatus ~= 8 then
                        return false, false, 'vehicle_locked'
                    end
                end

                local plate = (invType == 'glovebox' or invType == 'trunk') and GetVehicleNumberPlateText(entity)

                if plate then
                    if server.trimplate then plate = string.strtrim(plate) end

                    if not data.id  then
                        data.id = (invType == 'glovebox' and 'glove' or 'trunk') .. plate
                    end
                end

				data.type = invType
				right = Inventory(data)

				if right and data.netid ~= right.netid then
					local invEntity = NetworkGetEntityFromNetworkId(right.netid)

					if not (invEntity > 0 and DoesEntityExist(invEntity)) or (plate and not string.match(GetVehicleNumberPlateText(invEntity) or '', plate)) then
						Inventory.Remove(right)
						right = Inventory(data)
					end
				end
			elseif invType == 'drop' then
				right = Inventory(data.id)
			else
				return
			end
		elseif invType == 'policeevidence' then
			if ignoreSecurityChecks or server.hasGroup(left, shared.police) then
				right = Inventory(('evidence-%s'):format(data))
			end
		elseif invType == 'dumpster' then
			if shared.networkdumpsters then
				local dumpsterId = getDumpsterFromCoords(data)
				right = dumpsterId and Inventory(('dumpster-%s'):format(dumpsterId))

				if not right then
					dumpsterId = #registeredDumpsters + 1
					right = Inventory.Create(('dumpster-%s'):format(dumpsterId), locale('dumpster'), invType, 15, 0, 100000, false)
					registeredDumpsters[dumpsterId] = data
				end
			else
				---@cast data string
				right = Inventory(data)

				if not right then
					local netid = tonumber(data:sub(9))
	
					if netid and NetworkGetEntityFromNetworkId(netid) > 0 then
						right = Inventory.Create(data, locale('dumpster'), invType, 15, 0, 100000, false)
					end
				end
			end
		elseif invType == 'container' then
			left.containerSlot = data --[[@as number]]
			data = left.items[data]

			if data then
				local containerId = data.metadata?.container
				local containerSize = data.metadata?.size

				if not containerId and Items(data.name)?.weapon and data.metadata?.magContainer then
					containerId = data.metadata.magContainer
					containerSize = containerSize or { 1, 5000 }
					data.metadata.container = containerId
					data.metadata.size = containerSize
				end

				right = containerId and Inventory(containerId) or nil

				if not right and containerId and containerSize then
					right = Inventory.Create(containerId, data.label, invType, containerSize[1], 0, containerSize[2], false)
				end
			else left.containerSlot = nil end
		elseif invType == 'weaponmag' then
			left.weaponMagSlot = data --[[@as number]]
			data = left.items[data]

			if data and Items(data.name)?.weapon and data.metadata?.magContainer then
				Inventory.SyncWeaponMagazineInventory(data)
				right = Inventory(data.metadata.magContainer)

				if not right then
					right = Inventory.Create(data.metadata.magContainer, ('%s Magazine'):format(data.label or data.name), invType, 1, 0, 5000, false, {})
				end
			else
				left.weaponMagSlot = nil
			end
		else right = Inventory(data) end

		if not right then return end

		if not ignoreSecurityChecks and right.groups and not server.hasGroup(left, right.groups) then return end

		local hookPayload = {
			source = source,
			inventoryId = right.id,
			inventoryType = right.type,
		}

		if invType == 'container' then hookPayload.slot = left.containerSlot end
		if invType == 'weaponmag' then hookPayload.slot = left.weaponMagSlot end
		if isDataTable and data.netid then hookPayload.netId = data.netid end

		if not TriggerEventHooks('openInventory', hookPayload) then return end

        if left == right then return end

		if right.player then
			if right.open then return end

			right.coords = not ignoreSecurityChecks and GetEntityCoords(right.player.ped) or nil
		end

		if not ignoreSecurityChecks and right.coords then
			closestCoords = getClosestStashCoords(playerPed, right)

			if not closestCoords then return end
		end

		left:openInventory(right)

		local secondaryType = getSecondaryInventoryType(source, invType, right)
		local isSecondaryInventory = secondaryType ~= 'player'

		if isSecondaryInventory then
			local inventoryLabel = right.label or tostring(right.id)
			local logMessage = ('"%s" opened %s inventory "%s"'):format(left.label or GetPlayerName(source) or tostring(source), secondaryType, inventoryLabel)

			PureAdminLogger(source, 'ox_inventory_open_secondary_inventory', logMessage, {
				action = 'open_secondary_inventory',
				inventoryType = secondaryType,
				requestedType = invType,
				ignoreSecurityChecks = ignoreSecurityChecks == true,
				target = buildSecondaryInventoryTarget(source, right, invType),
				context = {
					leftInventoryId = left.id,
					leftInventoryType = left.type,
					containerSlot = invType == 'container' and left.containerSlot or nil,
					weaponMagSlot = invType == 'weaponmag' and left.weaponMagSlot or nil,
					coords = closestCoords or right.coords,
				},
			})
		end
	else
		left:openInventory(left)
	end

	local utilityPayload

	if Utility and Utility.getBackpackPayload then
		local targetPlayer

		if right and right.player and right.id ~= source then
			targetPlayer = right.id
		end

		utilityPayload = Utility.getBackpackPayload(source, targetPlayer)
	end

	local leftResponse = {
		id = left.id,
		label = left.label,
		type = left.type,
		slots = left.slots,
		weight = left.weight,
		maxWeight = left.maxWeight
	}

	if utilityPayload then
		leftResponse.backpack = utilityPayload.backpack
		leftResponse.utilitySlot = utilityPayload.utilitySlot
	end

	local rightResponse = right and {
		id = right.id,
		label = right.player and '' or right.label,
		type = right.player and 'otherplayer' or right.type,
		slots = right.slots,
		weight = right.weight,
		maxWeight = right.maxWeight,
		items = right.items,
		coords = closestCoords or right.coords,
		distance = right.distance
	}

	if rightResponse and utilityPayload and utilityPayload.otherBackpack then
		rightResponse.otherBackpack = utilityPayload.otherBackpack
	end

	return leftResponse, rightResponse
end

---@param source number
---@param invType string
---@param data string|number|table
lib.callback.register('ox_inventory:openInventory', function(source, invType, data)
	return openInventory(source, invType, data)
end)

---@param netId number
lib.callback.register('ox_inventory:isVehicleATrailer', function(source, netId)
	local entity = NetworkGetEntityFromNetworkId(netId)
	local retval = GetVehicleType(entity)
	return retval == 'trailer'
end)

---@param playerId number
---@param invType string
---@param data string|number|table
function server.forceOpenInventory(playerId, invType, data)
	local left, right = openInventory(playerId, invType, data, true)

	if left and right then
		TriggerClientEvent('ox_inventory:forceOpenInventory', playerId, left, right)
		return right.id
	end
end

exports('forceOpenInventory', server.forceOpenInventory)

local Licenses = lib.load('data.licenses')

lib.callback.register('ox_inventory:buyLicense', function(source, id)
	local license = Licenses[id]
	if not license then return end

	local inventory = Inventory(source)
	if not inventory then return end

	return server.buyLicense(inventory, license)
end)

lib.callback.register('ox_inventory:getItemCount', function(source, item, metadata, target)
	local inventory = target and Inventory(target) or Inventory(source)
	return (inventory and Inventory.GetItemCount(inventory, item, metadata, true))
end)

lib.callback.register('ox_inventory:addAmmoToPool', function(source, ammoSlot, weaponSlot)
	local inventory = Inventory(source)

	if not inventory then return false end

	local ammoItem = inventory.items[ammoSlot]
	local weapon = inventory.items[weaponSlot or inventory.weapon]

	if not ammoItem or not weapon then return false end

	local weaponItem = Items(weapon.name)
	local ammoData = Items(ammoItem.name)
	local ammoPoolKey = getWeaponAmmoPoolKey(weaponItem)

	if not ammoData?.ammo or not weaponItem?.weapon or not ammoPoolKey or weaponItem.ammoname ~= ammoItem.name then
		return false
	end

	local amount = math.max(0, tonumber(ammoItem.count) or 0)

	if amount < 1 or not Inventory.RemoveItem(inventory, ammoItem.name, amount, ammoItem.metadata, ammoItem.slot) then
		return false
	end

	local ammoPools = inventory.ammoPools or loadPlayerAmmoPools(inventory.owner)
	local ammoState = ammoPools[ammoPoolKey] or copyAmmoPoolState(AmmoPoolTemplate[ammoPoolKey])
	ammoState.reserve = math.min(ammoState.maxReserve, math.max(0, ammoState.reserve + amount))
	ammoPools[ammoPoolKey] = ammoState
	inventory.ammoPools = ammoPools
	PlayerAmmoPools[inventory.owner] = ammoPools
	markPlayerAmmoPoolsDirty(inventory.owner)

	weapon.metadata.reserve = ammoState.reserve
	weapon.metadata.loadedMagazine = nil
	weapon.metadata.specialAmmo = nil
	inventory.changed = true
	inventory:syncSlotsWithPlayer({
		{ item = weapon }
	}, inventory.weight)

	return ammoState
end)

RegisterNetEvent('ox_inventory:updateAmmoPool', function(poolKey, clip, reserve, slot)
	local inventory = Inventory(source)

	if not inventory or not AmmoPoolTemplate[poolKey] then return end

	local ammoPools = inventory.ammoPools or loadPlayerAmmoPools(inventory.owner)
	local ammoState = ammoPools[poolKey] or copyAmmoPoolState(AmmoPoolTemplate[poolKey])
	ammoState.clip = math.max(0, tonumber(clip) or 0)
	ammoState.reserve = math.min(ammoState.maxReserve, math.max(0, tonumber(reserve) or 0))
	ammoPools[poolKey] = ammoState
	inventory.ammoPools = ammoPools
	PlayerAmmoPools[inventory.owner] = ammoPools
	markPlayerAmmoPoolsDirty(inventory.owner)

	local weapon = inventory.items[slot or inventory.weapon]

	if weapon?.metadata then
		weapon.metadata.ammo = ammoState.clip
		weapon.metadata.reserve = ammoState.reserve
		weapon.metadata.loadedMagazine = nil
		weapon.metadata.specialAmmo = nil
		inventory.changed = true
	end
end)

local function addAmmoReserveToInventory(inventory, poolKey, amount)
	if not inventory or not AmmoPoolTemplate[poolKey] then return false end

	amount = math.max(0, math.floor(tonumber(amount) or 0))
	ammoDebug('addAmmoReserve sanitised amount', amount)

	if amount < 1 then return false end

	local ammoPools = inventory.ammoPools or loadPlayerAmmoPools(inventory.owner)
	local ammoState = ammoPools[poolKey] or copyAmmoPoolState(AmmoPoolTemplate[poolKey])
	ammoDebug('addAmmoReserve state before update', json.encode(ammoState))
	ammoState.reserve = math.min(ammoState.maxReserve, math.max(0, ammoState.reserve + amount))
	ammoPools[poolKey] = ammoState
	inventory.ammoPools = ammoPools
	PlayerAmmoPools[inventory.owner] = ammoPools
	markPlayerAmmoPoolsDirty(inventory.owner)
	ammoDebug('addAmmoReserve updated state for citizenid', inventory.owner, 'pool', poolKey, json.encode(ammoState))

	local weapon = inventory.items[inventory.weapon]

	if weapon?.metadata and getWeaponAmmoPoolKey(Items(weapon.name)) == poolKey then
		weapon.metadata.reserve = ammoState.reserve
		weapon.metadata.loadedMagazine = nil
		weapon.metadata.specialAmmo = nil
		inventory.changed = true
		inventory:syncSlotsWithPlayer({
			{ item = weapon }
		}, inventory.weight)
	end

	return ammoState
end

lib.callback.register('ox_inventory:addAmmoReserve', function(source, poolKey, amount)
	local inventory = Inventory(source)
	ammoDebug('addAmmoReserve called', 'source', source, 'pool', poolKey, 'amount', amount, 'inventory', inventory and inventory.id or 'nil')

	return addAmmoReserveToInventory(inventory, poolKey, amount)
end)

lib.callback.register('ox_inventory:getInventory', function(source, id)
	local inventory = Inventory(id or source)
	return inventory and {
		id = inventory.id,
		label = inventory.label,
		type = inventory.type,
		slots = inventory.slots,
		weight = inventory.weight,
		maxWeight = inventory.maxWeight,
		owned = inventory.owner and true or false,
		items = inventory.items
	}
end)

lib.callback.register('ox_inventory:getWeaponMagazineInventory', function(source, weaponSlot)
	return false
end)

RegisterNetEvent('ox_inventory:usedItemInternal', function(slot, inv)
	
	local inventory

	if inv and type(inv) == 'string' then
		inventory = Inventory(inv)
	end

	if not inventory then
		inventory = Inventory(source)
	end

	if not inventory then 
		return 
	end

	local item = inventory.usingItem

	if not item or item.slot ~= slot then
		---@todo
		DropPlayer(inventory.id, 'sussy')

		return
	end

	TriggerEvent('ox_inventory:usedItem', inventory.id, item.name, item.slot, next(item.metadata) and item.metadata, source)

	inventory.usingItem = nil
end)

---@param source number
---@param itemName string
---@param slot number?
---@param metadata { [string]: any }?
---@return table | boolean | nil
lib.callback.register('ox_inventory:useItem', function(source, itemName, slot, metadata, noAnim, inv)

	-- Determine target inventory: prefer explicit inv id (e.g., backpack/container), fall back to player's inventory
	local inventory = nil
	if inv and type(inv) == 'string' then
		inventory = Inventory(inv)
	end

	if not inventory then
		inventory = Inventory(source) --[[@as OxInventory]]
	end

	if inventory then
		local item = Items(itemName)
		local data = item and (slot and inventory.items[slot] or Inventory.GetSlotWithItem(inventory, item.name, metadata, true))

		if item?.ammoPool and item?.ammoAmount then
			ammoDebug('useItem called for ammo reserve item', 'source', source, 'item', itemName, 'slot', slot, 'inv', inv or 'player')
		end

		if not data then return end

		slot = data.slot
		local durability = data.metadata.durability --[[@as number|boolean|nil]]
		local consume = item.consume
		local label = data.metadata.label or item.label

		if durability and consume then
			if durability > 100 then
				local ostime = os.time()

				if ostime > durability then
                    Items.UpdateDurability(inventory, data, item, 0)
					return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = locale('no_durability', label) })
				elseif consume ~= 0 and consume < 1 then
					local degrade = (data.metadata.degrade or item.degrade) * 60
					local percentage = ((durability - ostime) * 100) / degrade

					if percentage < consume * 100 then
						return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = locale('not_enough_durability', label) })
					end
				end
			elseif durability <= 0 then
				return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = locale('no_durability', label) })
			elseif consume ~= 0 and consume < 1 and durability < consume * 100 then
				return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = locale('not_enough_durability', label) })
			end

			if data.count > 1 and consume < 1 and consume > 0 and not Inventory.GetEmptySlot(inventory) then
				return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = locale('cannot_use', label) })
			end
		end

		if item and data and data.count > 0 and data.name == item.name then
			data = {name=data.name, label=label, count=data.count, slot=slot, metadata=data.metadata, weight=data.weight}

			if item.ammoPool and item.ammoAmount then
				ammoDebug('useItem resolved ammo reserve item', 'source', source, 'item', item.name, 'slot', slot, 'count', data.count, 'pool', item.ammoPool, 'amount', item.ammoAmount)
			end

			if item.ammo then
				if inventory.weapon then
					local weapon = inventory.items[inventory.weapon]

					if weapon and weapon?.metadata.durability > 0 then
						consume = nil
					end
				else return false end
			elseif item.component or item.tint then
				consume = 1
				data.component = true
			elseif consume then
				if data.count >= consume then
					local result = item.cb and item.cb('usingItem', item, inventory, slot)

					if result == false then return end

					if result ~= nil then
						data.server = result
					end
				else
					return TriggerClientEvent('ox_lib:notify', source, { type = 'error', description = locale('item_not_enough', item.name) })
				end
			elseif not item.weapon and server.UseItem then
                inventory.usingItem = data
				-- This is used to call an external useItem function, i.e. ESX.UseItem
				-- If an error is being thrown on item use there is no internal solution. We previously kept a list
				-- of usable items which led to issues when restarting resources (for obvious reasons), but config
				-- developers complained the inventory broke their items. Safely invoking registered item callbacks
				-- should resolve issues, i.e. https://github.com/esx-framework/esx-legacy/commit/9fc382bbe0f5b96ff102dace73c424a53458c96e
				return pcall(server.UseItem, source, data.name, data)
			end

			data.consume = consume

            if not TriggerEventHooks('usingItem', {
				source = source,
                inventoryId = inventory and inventory.id,
                item = inventory.items[slot],
                consume = consume
			}) then return false end

            ---@type boolean
			local success = lib.callback.await('ox_inventory:usingItem', source, data, noAnim)

			if item.ammoPool and item.ammoAmount then
				ammoDebug('ox_inventory:usingItem returned for ammo reserve item', 'source', source, 'item', item.name, 'success', success and 'true' or 'false')
			end

			if item.weapon then
				inventory.weapon = success and slot or nil
			end

			if not success then return end

            inventory.usingItem = data

			if consume and consume ~= 0 and not data.component then
				data = inventory.items[data.slot]

				if not data then return end

				durability = consume ~= 0 and consume < 1 and data.metadata.durability --[[@as number | false]]

				if durability then
					if durability > 100 then
						local degrade = (data.metadata.degrade or item.degrade) * 60
						durability -= degrade * consume
					else
						durability -= consume * 100
					end

					if data.count > 1 then
						local emptySlot = Inventory.GetEmptySlot(inventory)

						if emptySlot then
							local newItem = Inventory.SetSlot(inventory, item, 1, table.deepclone(data.metadata), emptySlot)

							if newItem then
                                Items.UpdateDurability(inventory, newItem, item, durability)
							end
						end

						durability = 0
					else
                        Items.UpdateDurability(inventory, data, item, durability)
					end

					if durability <= 0 then
						durability = false
					end
				end

				if not durability then
					Inventory.RemoveItem(inventory.id, data.name, consume < 1 and 1 or consume, nil, data.slot)
				else
					inventory.changed = true

					if server.syncInventory then server.syncInventory(inventory) end
				end

				if item?.cb then
					item.cb('usedItem', item, inventory, data.slot)
				end
			end

			if item.ammoPool and item.ammoAmount then
				local ammoState = addAmmoReserveToInventory(inventory, item.ammoPool, item.ammoAmount)
				ammoDebug('server-side ammo reserve application after useItem', 'source', source, 'item', item.name, 'pool', item.ammoPool, 'amount', item.ammoAmount, 'state', ammoState and json.encode(ammoState) or 'nil')

				if ammoState then
					TriggerClientEvent('ox_inventory:updateAmmoReservePool', source, item.ammoPool, ammoState, item.ammoAmount)
				end
			end

			if item.ammoPool and item.ammoAmount then
				ammoDebug('useItem completed for ammo reserve item', 'source', source, 'item', item.name, 'remainingCount', inventory.items[data.slot] and inventory.items[data.slot].count or 0)
			end

			return true
		end
	end
end)

local function conversionScript()
	shared.ready = false

	local file = 'setup/convert.lua'
	local import = LoadResourceFile(shared.resource, file)
	local func = load(import, ('@@%s/%s'):format(shared.resource, file)) --[[@as function]]

	conversionScript = func()
end

RegisterCommand('convertinventory', function(source, args)
	if source ~= 0 then return warn('This command can only be executed with the server console.') end
	if type(conversionScript) == 'function' then conversionScript() end
	local arg = args[1]

	local convert = arg and conversionScript[arg]

	if not convert then
		return warn('Invalid conversion argument. Valid options: esx, esxproperty')
	end

	CreateThread(convert)
end, true)


lib.addCommand({'additem', 'giveitem'}, {
	help = 'Gives an item to a player with the given id',
	params = {
		{ name = 'target', type = 'playerId', help = 'The player to receive the item' },
		{ name = 'item', type = 'string', help = 'The name of the item' },
		{ name = 'count', type = 'number', help = 'The amount of the item to give', optional = true },
		{ name = 'type', help = 'Sets the "type" metadata to the value', optional = true },
	},
	restricted = "group.admin",
}, function(source, args)
	local executor = PureAdminBuildCommandActor(source)
	local rawCommand = PureAdminBuildRawCommand('additem', args)
	local item = Items(args.item)

	if item then
		local inventory = Inventory(args.target) --[[@as OxInventory]]
		local count = args.count or 1
		local success, response = Inventory.AddItem(inventory, item.name, count, args.type and { type = tonumber(args.type) or args.type })

		if not success then
			return Citizen.Trace(('Failed to give %sx %s to player %s (%s)'):format(count, item.name, args.target, response))
		end

		if server.loglevel > 0 then
			local logMessage = ('"%s" gave %sx %s to "%s"'):format(executor.label, count, item.name, inventory.label)
			lib.logger(executor.owner, 'admin', logMessage)
			PureAdminLogger(executor.source, 'ox_inventory_admin_giveitem', logMessage, {
				action = 'additem_command',
				actor = {
					label = executor.label,
					owner = executor.owner,
					source = executor.source,
					name = executor.name,
					identifiers = executor.identifiers,
				},
				target = attachTargetIdentifiers({
					label = inventory.label,
					owner = inventory.owner,
					id = inventory.id,
				}, args.target),
				item = item.name,
				count = count,
				metadata = args.type and { type = tonumber(args.type) or args.type } or nil,
				rawCommand = rawCommand,
			})
		end
	end
end)

lib.addCommand('removeitem', {
	help = 'Removes an item to a player with the given id',
	params = {
		{ name = 'target', type = 'playerId', help = 'The player to remove the item from' },
		{ name = 'item', type = 'string', help = 'The name of the item' },
		{ name = 'count', type = 'number', help = 'The amount of the item to take' },
		{ name = 'type', help = 'Only remove items with a matching metadata "type"', optional = true },
	},
	restricted = "group.admin",
}, function(source, args)
	local executor = PureAdminBuildCommandActor(source)
	local rawCommand = PureAdminBuildRawCommand('removeitem', args)
	local item = Items(args.item)

	if item and args.count > 0 then
		local inventory = Inventory(args.target) --[[@as OxInventory]]
		local success, response = Inventory.RemoveItem(inventory, item.name, args.count, args.type and { type = tonumber(args.type) or args.type }, nil, true)

		if not success then
			return Citizen.Trace(('Failed to remove %sx %s from player %s (%s)'):format(args.count, item.name, args.target, response))
		end

		if server.loglevel > 0 then
			local logMessage = ('"%s" removed %sx %s from "%s"'):format(executor.label, args.count, item.name, inventory.label)
			lib.logger(executor.owner, 'admin', logMessage)
			PureAdminLogger(executor.source, 'ox_inventory_admin_removeitem', logMessage, {
				action = 'removeitem_command',
				actor = {
					label = executor.label,
					owner = executor.owner,
					source = executor.source,
					name = executor.name,
					identifiers = executor.identifiers,
				},
				target = attachTargetIdentifiers({
					label = inventory.label,
					owner = inventory.owner,
					id = inventory.id,
				}, args.target),
				item = item.name,
				count = args.count,
				metadata = args.type and { type = tonumber(args.type) or args.type } or nil,
				rawCommand = rawCommand,
			})
		end
	end
end)

lib.addCommand('setitem', {
	help = 'Sets the item count for a player, removing or adding as needed',
	params = {
		{ name = 'target', type = 'playerId', help = 'The player to set the items for' },
		{ name = 'item', type = 'string', help = 'The name of the item' },
		{ name = 'count', type = 'number', help = 'The amount of items to set', optional = true },
		{ name = 'type', help = 'Add or remove items with the metadata "type"', optional = true },
	},
	restricted = "group.admin",
}, function(source, args)
	local executor = PureAdminBuildCommandActor(source)
	local rawCommand = PureAdminBuildRawCommand('setitem', args)
	local item = Items(args.item)

	if item then
		local inventory = Inventory(args.target) --[[@as OxInventory]]
		local success, response = Inventory.SetItem(inventory, item.name, args.count or 0, args.type and { type = tonumber(args.type) or args.type })

		if not success then
			return Citizen.Trace(('Failed to set %s count to %sx for player %s (%s)'):format(item.name, args.count, args.target, response))
		end

		if server.loglevel > 0 then
			local logMessage = ('"%s" set "%s" %s count to %sx'):format(executor.label, inventory.label, item.name, args.count)
			lib.logger(executor.owner, 'admin', logMessage)
			PureAdminLogger(executor.source, 'ox_inventory_admin_setitem', logMessage, {
				action = 'setitem_command',
				actor = {
					label = executor.label,
					owner = executor.owner,
					source = executor.source,
					name = executor.name,
					identifiers = executor.identifiers,
				},
				target = attachTargetIdentifiers({
					label = inventory.label,
					owner = inventory.owner,
					id = inventory.id,
				}, args.target),
				item = item.name,
				count = args.count,
				metadata = args.type and { type = tonumber(args.type) or args.type } or nil,
				rawCommand = rawCommand,
			})
		end
	end
end)

lib.addCommand('clearevidence', {
	help = 'Clears a police evidence locker with the given id',
	params = {
		{ name = 'locker', type = 'number', help = 'The locker id to clear' },
	},
}, function(source, args)
	if not server.isPlayerBoss then return end

	local inventory = Inventory(source)
	local group, grade = server.hasGroup(inventory, shared.police)
	local hasPermission = group and server.isPlayerBoss(source, group, grade)

	if hasPermission then
		MySQL.query('DELETE FROM ox_inventory WHERE name = ?', {('evidence-%s'):format(args.locker)})
	end
end)

lib.addCommand('takeinv', {
	help = 'Confiscates the target inventory, to restore with /restoreinv',
	params = {
		{ name = 'target', type = 'playerId', help = 'The player to confiscate items from' },
	},
	restricted = "group.admin",
}, function(source, args)
	local executor = PureAdminBuildCommandActor(source)
	local rawCommand = PureAdminBuildRawCommand('takeinv', args)
	local targetInventory = Inventory(args.target)

	if server.loglevel > 0 then
		local logMessage = ('"%s" confiscated inventory from "%s"'):format(executor.label, targetInventory and targetInventory.label or tostring(args.target))
		PureAdminLogger(executor.source, 'ox_inventory_admin_takeinv', logMessage, {
			action = 'takeinv_command',
			actor = {
				label = executor.label,
				owner = executor.owner,
				source = executor.source,
				name = executor.name,
				identifiers = executor.identifiers,
			},
			target = attachTargetIdentifiers(targetInventory and {
				label = targetInventory.label,
				owner = targetInventory.owner,
				id = targetInventory.id,
			} or {
				id = args.target,
			}, args.target),
			rawCommand = rawCommand,
		})
	end

	Inventory.Confiscate(args.target)
end)

lib.addCommand({'restoreinv', 'returninv'}, {
	help = 'Restores a previously confiscated inventory for the target',
	params = {
		{ name = 'target', type = 'playerId', help = 'The player to restore items to' },
	},
	restricted = "group.admin",
}, function(source, args)
	local executor = PureAdminBuildCommandActor(source)
	local rawCommand = PureAdminBuildRawCommand('restoreinv', args)
	local targetInventory = Inventory(args.target)

	if server.loglevel > 0 then
		local logMessage = ('"%s" restored inventory for "%s"'):format(executor.label, targetInventory and targetInventory.label or tostring(args.target))
		PureAdminLogger(executor.source, 'ox_inventory_admin_restoreinv', logMessage, {
			action = 'restoreinv_command',
			actor = {
				label = executor.label,
				owner = executor.owner,
				source = executor.source,
				name = executor.name,
				identifiers = executor.identifiers,
			},
			target = attachTargetIdentifiers(targetInventory and {
				label = targetInventory.label,
				owner = targetInventory.owner,
				id = targetInventory.id,
			} or {
				id = args.target,
			}, args.target),
			aliases = { 'returninv' },
			rawCommand = rawCommand,
		})
	end

	Inventory.Return(args.target)
end)

lib.addCommand({'clearinv', 'wipeinv', 'ci'}, {
	help = 'Wipes all items from the target inventory',
	params = {
		{ name = 'invId', help = 'The inventory to wipe items from' },
	},
	restricted = "group.admin",
}, function(source, args)
	local executor = PureAdminBuildCommandActor(source)
	local rawCommand = PureAdminBuildRawCommand('clearinv', args)
	local targetId = tonumber(args.invId) or args.invId == 'me' and source or args.invId
	local targetInventory = Inventory(targetId)

	if server.loglevel > 0 then
		local logMessage = ('"%s" cleared inventory "%s"'):format(executor.label, targetInventory and targetInventory.label or tostring(targetId))
		PureAdminLogger(executor.source, 'ox_inventory_admin_clearinv', logMessage, {
			action = 'clearinv_command',
			actor = {
				label = executor.label,
				owner = executor.owner,
				source = executor.source,
				name = executor.name,
				identifiers = executor.identifiers,
			},
			target = attachTargetIdentifiers(targetInventory and {
				label = targetInventory.label,
				owner = targetInventory.owner,
				id = targetInventory.id,
				type = targetInventory.type,
			} or {
				id = targetId,
			}, type(targetId) == 'number' and targetId or nil),
			rawCommand = rawCommand,
		})
	end

	Inventory.Clear(targetId)
end)

lib.addCommand('saveinv', {
	help = 'Save all pending inventory changes to the database',
	params = {
		{ name = 'lock', help = 'Lock inventory access, until restart or saved without a lock', optional = true },
	},
	restricted = "group.support",
}, function(source, args)
	local executor = PureAdminBuildCommandActor(source)
	local rawCommand = PureAdminBuildRawCommand('saveinv', args)

	if server.loglevel > 0 then
		local logMessage = ('"%s" triggered inventory save'):format(executor.label)
		PureAdminLogger(executor.source, 'ox_inventory_admin_saveinv', logMessage, {
			action = 'saveinv_command',
			actor = {
				label = executor.label,
				owner = executor.owner,
				source = executor.source,
				name = executor.name,
				identifiers = executor.identifiers,
			},
			lock = args.lock == 'true',
			rawCommand = rawCommand,
		})
	end

	Inventory.SaveInventories(args.lock == 'true', false)
end)

lib.addCommand('viewinv', {
	help = 'Inspect the target inventory without allowing interactions',
	params = {
		{ name = 'invId', help = 'The inventory to inspect' },
	},
	restricted = "group.support",
}, function(source, args)
	local executor = PureAdminBuildCommandActor(source)
	local rawCommand = PureAdminBuildRawCommand('viewinv', args)
	local targetId = tonumber(args.invId) or args.invId
	local targetInventory = Inventory(targetId)

	if server.loglevel > 0 then
		local logMessage = ('"%s" viewed inventory "%s"'):format(executor.label, targetInventory and targetInventory.label or tostring(targetId))
		PureAdminLogger(executor.source, 'ox_inventory_admin_viewinv', logMessage, {
			action = 'viewinv_command',
			actor = {
				label = executor.label,
				owner = executor.owner,
				source = executor.source,
				name = executor.name,
				identifiers = executor.identifiers,
			},
			target = attachTargetIdentifiers(targetInventory and {
				label = targetInventory.label,
				owner = targetInventory.owner,
				id = targetInventory.id,
				type = targetInventory.type,
			} or {
				id = targetId,
			}, type(targetId) == 'number' and targetId or nil),
			rawCommand = rawCommand,
		})
	end

	Inventory.InspectInventory(source, targetId)
end)
