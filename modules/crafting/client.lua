if not lib then return end
lib.locale()

local Items = require 'modules.items.client'
local Utils = require 'modules.utils.client'
local createBlip = Utils.CreateBlip

local Config = lib.load('data.crafting') or {}
local BenchTypes = Config.types or {}
local StaticBenches = Config.benches or {}

local CraftingBenches = {}
local BenchProps = {}
local BenchPoints = {}
local BenchZones = {}
local BenchTargetEntities = {}
local BenchMoving = {}
local BenchPermissions = {}
local markerColour = { 150, 150, 30 }
local currentResource = cache and cache.resource or GetCurrentResourceName()

local function getBenchPermissions(id)
	return BenchPermissions[id]
end

local function setBenchPermissionsCache(id, data)
	if not id or type(data) ~= 'table' then
		return
	end

	BenchPermissions[id] = {
		canUse = data.canUse ~= false,
		canMove = data.canMove == true,
		canPack = data.canPack == true,
		canManage = data.canManage == true,
		isOwner = data.isOwner == true,
		roleId = data.roleId,
		roleName = data.roleName,
	}
end

local function benchHasPermission(id, flag)
	local perms = BenchPermissions[id]
	if not perms then
		return flag == 'use'
	end

	if perms.isOwner then
		return true
	end

	if flag == 'use' then
		return perms.canUse or false
	elseif flag == 'move' then
		return perms.canMove or false
	elseif flag == 'pack' then
		return perms.canPack or false
	elseif flag == 'manage' then
		return perms.canManage or false
	end

	return false
end

local function attemptOpenBench(id, index)
	if not benchHasPermission(id, 'use') then
		lib.notify({ type = 'error', description = locale('crafting_no_permission') or 'No permission' })
		return
	end

	client.openInventory('crafting', { id = id, index = index or 1 })
end

local function openBenchPermissionsUI(id)
	if not benchHasPermission(id, 'manage') then
		lib.notify({ type = 'error', description = locale('crafting_no_permission') or 'No permission' })
		return
	end

	local payload, err = lib.callback.await('ox_inventory:crafting:getBenchPermissions', false, id)
	if not payload then
		if err then
			lib.notify({ type = 'error', description = locale(err) or tostring(err) })
		end
		return
	end

	SendNUIMessage({
		action = 'openBenchPermissions',
		data = payload,
	})
	SetNuiFocus(true, true)

	if payload.playerPermissions then
		setBenchPermissionsCache(id, payload.playerPermissions)
	end
end

local function buildBenchTargetOptions(id, bench, index, baseLabel, baseIcon, distance, includeOpen, includeExtras)
	local options = {}
	local optionDistance = distance or bench.targetDistance or 2.0

	if includeOpen ~= false then
		options[#options + 1] = {
			label = baseLabel or bench.label or locale('open_crafting_bench'),
			icon = baseIcon or 'fas fa-wrench',
			distance = optionDistance,
			canInteract = function()
				if bench.groups and not client.hasGroup(bench.groups) then
					return false
				end
				return benchHasPermission(id, 'use')
			end,
			onSelect = function()
				attemptOpenBench(id, index)
			end,
		}
	end

	if bench.dynamic and includeExtras ~= false then
		options[#options + 1] = {
			icon = 'fas fa-users-cog',
			label = locale('crafting_manage_permissions') or 'Manage bench',
			distance = optionDistance,
			canInteract = function()
				return benchHasPermission(id, 'manage')
			end,
			onSelect = function()
				openBenchPermissionsUI(id)
			end,
		}

		options[#options + 1] = {
			icon = 'fas fa-arrows-alt',
			label = locale('crafting_move_bench') or 'Move bench',
			distance = optionDistance,
			canInteract = function()
				return benchHasPermission(id, 'move')
			end,
			onSelect = function()
				TriggerServerEvent('ox_inventory:crafting:requestMoveBench', id)
			end,
		}

		options[#options + 1] = {
			icon = 'fas fa-box',
			label = locale('crafting_pack_bench') or 'Pack bench',
			distance = optionDistance,
			canInteract = function()
				return benchHasPermission(id, 'pack')
			end,
			onSelect = function()
				TriggerServerEvent('ox_inventory:crafting:packBench', id)
			end,
		}
	end

	return options
end

local function buildBenchContextOptions(id, bench, index)
	local options = {}
	local label = bench.label or locale('open_crafting_bench')

	if benchHasPermission(id, 'use') then
		options[#options + 1] = {
			title = label,
			icon = 'fas fa-wrench',
			description = locale('crafting_permission_use'),
			onSelect = function()
				attemptOpenBench(id, index)
			end,
		}
	end

	if bench.dynamic and includeExtras ~= false then
		if benchHasPermission(id, 'manage') then
			options[#options + 1] = {
				title = locale('crafting_manage_permissions') or 'Manage bench',
				icon = 'fas fa-users-cog',
				description = locale('crafting_permission_manage'),
				onSelect = function()
					openBenchPermissionsUI(id)
				end,
			}
		end

		if benchHasPermission(id, 'move') then
			options[#options + 1] = {
				title = locale('crafting_move_bench') or 'Move bench',
				icon = 'fas fa-arrows-alt',
				description = locale('crafting_permission_move'),
				onSelect = function()
					TriggerServerEvent('ox_inventory:crafting:requestMoveBench', id)
				end,
			}
		end

		if benchHasPermission(id, 'pack') then
			options[#options + 1] = {
				title = locale('crafting_pack_bench') or 'Pack bench',
				icon = 'fas fa-box',
				description = locale('crafting_permission_pack'),
				onSelect = function()
					TriggerServerEvent('ox_inventory:crafting:packBench', id)
				end,
			}
		end
	end

	return options
end

local function handleBenchInteraction(id, index)
	local bench = CraftingBenches[id]
	if not bench then
		lib.notify({ type = 'error', description = locale('crafting_not_found') or 'Bench not found.' })
		return
	end

	local options = buildBenchContextOptions(id, bench, index or 1)

	if #options == 0 then
		lib.notify({ type = 'error', description = locale('crafting_no_permission') or 'No permission' })
		return
	end

	if #options == 1 then
		local entry = options[1]
		if entry and entry.onSelect then
			entry.onSelect()
		end
		return
	end

	local contextId = ('ox_inventory:bench:%s'):format(id)
	lib.hideTextUI()
	lib.registerContext({
		id = contextId,
		title = bench.label or locale('crafting_permissions_title') or 'Bench',
		options = options,
	})
	lib.showContext(contextId)
end

local function shallowCopy(tbl)
	if not tbl then return {} end
	local copy = {}
	for k, v in pairs(tbl) do
		copy[k] = v
	end
	return copy
end

local function deepCopy(value)
	if type(value) ~= 'table' then return value end
	if table.deepclone then
		return table.deepclone(value)
	end

	local result = {}
	for k, v in pairs(value) do
		result[k] = deepCopy(v)
	end

	return result
end

exports('receiveBlueprint', function(metadataKey, metadataValue)
	TriggerServerEvent('ox_inventory:crafting:requestBlueprint', metadataKey, metadataValue)
end)

local function removeBenchTarget(id)
	local entity = BenchTargetEntities[id]
	if entity and DoesEntityExist(entity) then
		pcall(function()
			exports.ox_target:removeLocalEntity(entity)
		end)
	end
	BenchTargetEntities[id] = nil
end

local function attachTargetToBench(id, bench, entity)
	if not shared.target or entity == 0 then return end

	if BenchZones[id] then
		return
	end

	removeBenchTarget(id)

	local options = buildBenchTargetOptions(
		id,
		bench,
		1,
		bench.label or locale('open_crafting_bench'),
		bench.targetIcon or 'fas fa-wrench',
		bench.targetDistance,
		true
	)

	if next(options) then
		exports.ox_target:addLocalEntity(entity, options)
		BenchTargetEntities[id] = entity
	end
end
local prompt = {
	options = { icon = 'fa-wrench' },
	message = ('**%s**  \n%s'):format(locale('open_crafting_bench'), locale('interact_prompt', GetControlInstructionalButton(0, 38, true):sub(3)))
}

local function ensureRecipeMetadata(id, data)
	local recipes = data.items

	if not recipes then
		return
	end

	data.slots = #recipes

	for i = 1, data.slots do
		local recipe = recipes[i]
		local recipeName = recipe.name
		local item = recipeName and Items[recipeName]

		if not item and type(recipeName) == 'string' then
			local lowerName = recipeName:lower()

			if lowerName:sub(1, 7) == 'weapon_' then
				item = Items[lowerName:upper()]
			end
		end

		recipe.slot = i
		recipe.weight = item and item.weight or recipe.weight or 0

		if item then
			if recipe.metadata then
				recipe.metadata.label = recipe.metadata.label or item.label
				recipe.metadata.description = recipe.metadata.description or item.description
			else
				recipe.metadata = {
					label = item.label,
					description = item.description,
				}
			end
		else
			warn(('failed to setup crafting recipe (bench: %s, slot: %s) - item "%s" does not exist'):format(id, i, recipeName))
		end
	end
end

local function removeTargetZone(id)
	local zoneHandles = BenchZones[id]

	if not zoneHandles then return end

	if shared.target and type(zoneHandles) == 'table' then
		for _, zoneName in ipairs(zoneHandles) do
			if zoneName then
				pcall(function()
					exports.ox_target:removeZone(zoneName)
				end)
			end
		end
	end

	BenchZones[id] = nil
end

local function removeBenchPoint(id)
	local points = BenchPoints[id]

	if not points then return end

	for _, point in ipairs(points) do
		if point and point.remove then
			point:remove()
		end
	end

	BenchPoints[id] = nil
end

local function deleteBenchProp(id)
	removeBenchTarget(id)

	local entity = BenchProps[id]
	if not entity or not DoesEntityExist(entity) then
		BenchProps[id] = nil
		return
	end

	DeleteEntity(entity)
	BenchProps[id] = nil
end

local function ensureBenchProp(id, bench)
	if BenchMoving[id] then return end

	if not bench.model or not bench.spawnRange then
		return
	end

	local playerCoords = GetEntityCoords(cache.ped)
	local coords = bench.coords

	if not coords then
		if bench.points and bench.points[1] then
			local c = bench.points[1]
			coords = vec3(c.x, c.y, c.z)
		elseif bench.zones and bench.zones[1] and bench.zones[1].coords then
			local z = bench.zones[1].coords
			coords = vec3(z.x, z.y, z.z)
		end
	end

	if not coords then
		return
	end

	local distance = #(playerCoords - coords)
	local existing = BenchProps[id]

	if distance <= bench.spawnRange then
		if existing and DoesEntityExist(existing) then
			if not BenchTargetEntities[id] then
				attachTargetToBench(id, bench, existing)
			end
			return
		end

		local model = lib.requestModel(bench.model)
		if not model then return end

		local object = CreateObject(model, coords.x, coords.y, coords.z, false, false, false)

		if object == 0 then
			return
		end

		SetEntityHeading(object, bench.heading or 0.0)
		PlaceObjectOnGroundProperly(object)
		FreezeEntityPosition(object, true)
		SetEntityInvincible(object, true)
		SetModelAsNoLongerNeeded(model)

		BenchProps[id] = object
		attachTargetToBench(id, bench, object)
		BenchMoving[id] = nil
	elseif existing then
		deleteBenchProp(id)
	end
end

CreateThread(function()
	while true do
		local ped = cache.ped

		if ped and ped ~= 0 then
			for id, bench in pairs(CraftingBenches) do
				if bench.spawnRange and bench.model then
					ensureBenchProp(id, bench)
				end
			end
		end

		Wait(1000)
	end
end)

local function setupTargetInteractions(id, data)
	if BenchZones[id] then
		removeTargetZone(id)
	end

	if BenchTargetEntities[id] then
		removeBenchTarget(id)
	end

	removeBenchPoint(id)

	local handles = {}

	if shared.target then
		data.points = nil

		if data.zones then
			for i = 1, #data.zones do
				local zone = shallowCopy(data.zones[i])
				zone.name = ("craftingbench_%s:%s"):format(id, i)
				zone.id = id
				zone.index = i
				zone.options = buildBenchTargetOptions(
					id,
					data,
					i,
					zone.label or locale('open_crafting_bench'),
					zone.icon or 'fas fa-wrench',
					zone.distance,
					true
				)

				exports.ox_target:addBoxZone(zone)
				handles[#handles + 1] = zone.name

				if data.blip then
					createBlip(data.blip, zone.coords)
				end
			end
		elseif data.coords then
			local coords = data.coords
			if type(coords) == 'vector3' then
				coords = vec3(coords.x, coords.y, coords.z)
			elseif type(coords) == 'table' then
				coords = vec3(coords.x or 0.0, coords.y or 0.0, coords.z or 0.0)
			else
				coords = nil
			end

			if coords then
				local zoneName = ("craftingbench_%s:dynamic"):format(id)
				local radius = data.targetRadius or 1.5

				exports.ox_target:addSphereZone({
					name = zoneName,
					coords = coords,
					radius = radius,
					debug = data.debugTarget,
					options = buildBenchTargetOptions(
						id,
						data,
						1,
						data.label or locale('open_crafting_bench'),
						'fas fa-wrench',
						radius,
						true
					)
				})

				handles[#handles + 1] = zoneName

				if data.blip then
					createBlip(data.blip, coords)
				end
			end
		end
	else
		if data.points then
			local points = {}

			for i = 1, #data.points do
				local coords = data.points[i]

				points[#points + 1] = lib.points.new({
					coords = coords,
					distance = 16,
					benchid = id,
					index = i,
					inv = 'crafting',
					prompt = prompt,
					marker = markerColour,
					nearby = Utils.nearbyMarker,
					onInteract = function()
						handleBenchInteraction(id, i)
					end
				})

				if data.blip then
					createBlip(data.blip, coords)
				end
			end

			BenchPoints[id] = points
		elseif data.coords then
			local coords = data.coords
			local point = lib.points.new({
				coords = coords,
				distance = 16,
				benchid = id,
				index = 1,
				inv = 'crafting',
				prompt = prompt,
				marker = markerColour,
				nearby = Utils.nearbyMarker,
				onInteract = function()
					handleBenchInteraction(id, 1)
				end
			})

			BenchPoints[id] = { point }

			if data.blip then
				createBlip(data.blip, coords)
			end
		end
	end

	if next(handles) then
		BenchZones[id] = handles
	else
		BenchZones[id] = nil
	end
end

local function registerBench(id, benchData)
	if CraftingBenches[id] then
		removeTargetZone(id)
		removeBenchTarget(id)
		removeBenchPoint(id)
		deleteBenchProp(id)
	end

	benchData.groups = benchData.groups or benchData.jobs or benchData.job or benchData.gangs or benchData.gang

	local typeId = benchData.type or benchData.typeId
	local typeConfig = typeId and BenchTypes[typeId]
	if typeConfig then
		benchData.label = benchData.label or typeConfig.label
		benchData.model = benchData.model or typeConfig.model
		benchData.spawnRange = benchData.spawnRange or typeConfig.spawnRange
		benchData.storage = benchData.storage or typeConfig.storage
		benchData.items = benchData.items or typeConfig.recipes
		benchData.hideLocked = benchData.hideLocked or typeConfig.hideLocked
	end

	benchData.items = deepCopy(benchData.items or {})

	ensureRecipeMetadata(id, benchData)
	
	if benchData.coords then
		if type(benchData.coords) == 'vector3' then
			benchData.coords = vec3(benchData.coords.x, benchData.coords.y, benchData.coords.z)
		elseif type(benchData.coords) == 'table' then
			benchData.coords = vec3(benchData.coords.x or 0.0, benchData.coords.y or 0.0, benchData.coords.z or 0.0)
		end
	end
	
	CraftingBenches[id] = benchData

	if benchData.permissions then
		setBenchPermissionsCache(id, benchData.permissions)
		benchData.permissions = nil
	end

	setupTargetInteractions(id, benchData)
	BenchMoving[id] = nil
end

local function removeBench(id)
	removeTargetZone(id)
	removeBenchPoint(id)
	removeBenchTarget(id)
	deleteBenchProp(id)
	BenchPermissions[id] = nil
	CraftingBenches[id] = nil
end

local function startPlacement(data)
	if type(data) ~= 'table' then return end

	local typeName = data.type
	local typeConfig = typeName and BenchTypes[typeName]
	if not typeConfig then return end

	local model = data.model or typeConfig.model
	if not model then
		lib.notify({ type = 'error', description = locale('cannot_perform') })
		TriggerServerEvent('ox_inventory:crafting:placementCancelled')
		return
	end

	local hash = lib.requestModel(model)

	if not hash then
		lib.notify({ type = 'error', description = locale('cannot_perform') })
		TriggerServerEvent('ox_inventory:crafting:placementCancelled')
		return
	end

	local ped = cache.ped
	local offset = GetEntityCoords(ped) + GetEntityForwardVector(ped) * 2.0
	local ghost = CreateObject(hash, offset.x, offset.y, offset.z, false, false, false)

	if ghost == 0 then
		lib.notify({ type = 'error', description = locale('cannot_perform') })
		TriggerServerEvent('ox_inventory:crafting:placementCancelled')
		return
	end

	SetEntityAlpha(ghost, 150, false)
	SetEntityCollision(ghost, false, false)
	SetEntityHeading(ghost, GetEntityHeading(ped))
	SetModelAsNoLongerNeeded(hash)

	local usingGizmo = false

	if GetResourceState('object_gizmo') == 'started' then
		usingGizmo = true
		exports.object_gizmo:useGizmo(ghost)
	else
		PlaceObjectOnGroundProperly(ghost)
		FreezeEntityPosition(ghost, true)
	end

	lib.showTextUI(locale('crafting_place_controls') or '[E] Confirm  |  [Backspace] Cancel', { position = 'bottom-center' })

	local confirmed = false
	while true do
		if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38) then
			confirmed = true
			break
		end

		if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 202) then
			break
		end

		Wait(0)
	end

	lib.hideTextUI()

	if not DoesEntityExist(ghost) then
		if not confirmed then
			TriggerServerEvent('ox_inventory:crafting:placementCancelled')
		end
		return
	end

	local coords = GetEntityCoords(ghost)
	local heading = GetEntityHeading(ghost)
	DeleteObject(ghost)

	if confirmed then
		TriggerServerEvent('ox_inventory:crafting:placeBench', {
			type = typeName,
			coords = { x = coords.x, y = coords.y, z = coords.z },
			heading = heading,
			label = typeConfig.label,
			inventory = data.inventory,
		})
	else
		TriggerServerEvent('ox_inventory:crafting:placementCancelled')
	end
end

local function startMoveBench(data)
	if type(data) ~= 'table' then return end

	local benchId = data.id
	if not benchId then return end

	local bench = CraftingBenches[benchId]
	if not bench then return end

	BenchMoving[benchId] = true

	local model = data.model or bench.model
	if not model then
		lib.notify({ type = 'error', description = locale('cannot_perform') })
		ensureBenchProp(benchId, bench)
		BenchMoving[benchId] = nil
		return
	end

	deleteBenchProp(benchId)

	local coordsData = data.coords or {}
	local coords = vec3(coordsData.x or 0.0, coordsData.y or 0.0, coordsData.z or 0.0)
	local heading = data.heading or 0.0

	local hash = lib.requestModel(model)
	if not hash then
		ensureBenchProp(benchId, bench)
		BenchMoving[benchId] = nil
		return
	end

	local ghost = CreateObject(hash, coords.x, coords.y, coords.z, false, false, false)
	if ghost == 0 then
		ensureBenchProp(benchId, bench)
		BenchMoving[benchId] = nil
		return
	end

	SetEntityHeading(ghost, heading)
	SetEntityAlpha(ghost, 150, false)
	SetEntityCollision(ghost, false, false)
	SetModelAsNoLongerNeeded(hash)

	if GetResourceState('object_gizmo') == 'started' then
		exports.object_gizmo:useGizmo(ghost)
	else
		PlaceObjectOnGroundProperly(ghost)
		FreezeEntityPosition(ghost, true)
	end

	lib.showTextUI(locale('crafting_move_controls') or '[E] Confirm  |  [Backspace] Cancel', { position = 'bottom-center' })

	local confirmed = false
	while true do
		if IsControlJustPressed(0, 38) or IsDisabledControlJustPressed(0, 38) then
			confirmed = true
			break
		end

		if IsControlJustPressed(0, 177) or IsControlJustPressed(0, 202) then
			break
		end

		Wait(0)
	end

	lib.hideTextUI()

	if not DoesEntityExist(ghost) then
		if not confirmed then
			ensureBenchProp(benchId, bench)
		end
		BenchMoving[benchId] = nil
		return
	end

	local newCoords = GetEntityCoords(ghost)
	local newHeading = GetEntityHeading(ghost)
	DeleteObject(ghost)

	if confirmed then
		TriggerServerEvent('ox_inventory:crafting:moveBench', benchId, {
			coords = { x = newCoords.x, y = newCoords.y, z = newCoords.z },
			heading = newHeading,
		})
	else
		ensureBenchProp(benchId, bench)
	end

	BenchMoving[benchId] = nil
end

RegisterNetEvent('ox_inventory:crafting:startPlacement', startPlacement)
RegisterNetEvent('ox_inventory:crafting:startMove', startMoveBench)
RegisterNetEvent('ox_inventory:crafting:updatePermissions', function(payload)
	if type(payload) ~= 'table' or not payload.id then
		return
	end

	if payload.removed then
		BenchPermissions[payload.id] = nil
		return
	end

	setBenchPermissionsCache(payload.id, payload)
end)
RegisterNetEvent('ox_inventory:crafting:addBench', function(bench)
	if not bench or type(bench) ~= 'table' then return end

	local id = bench.id or bench.name
	if not id then return end

	if bench.removed then
		removeBench(id)
		return
	end

	if bench.coords then
		bench.coords = vec3(bench.coords.x, bench.coords.y, bench.coords.z)
	end

	registerBench(id, bench)
end)

RegisterNetEvent('ox_inventory:crafting:removeBench', function(benchId)
	if not benchId then return end
	removeBench(benchId)
end)

RegisterNetEvent('ox_inventory:crafting:updateBlueprints', function(blueprints)
	SendNUIMessage({
		action = 'updateBlueprints',
		data = blueprints
	})
end)

exports.ox_inventory:displayMetadata("blueprint", "Type")

RegisterNetEvent('ox_inventory:crafting:queueUpdated', function(queue)
    SendNUIMessage({
        action = 'updateCraftQueue',
        data = queue
    })
end)

local function registerStaticBenches()
	if type(StaticBenches) ~= 'table' then return end

	for index, bench in ipairs(StaticBenches) do
		local id = bench.name or ('bench_static_%s'):format(index)
		registerBench(id, deepCopy(bench))
	end
end

CreateThread(function()
	registerStaticBenches()
	TriggerServerEvent('ox_inventory:crafting:requestBenches')
end)

AddEventHandler('onResourceStop', function(resourceName)
	if resourceName ~= currentResource then return end

	local ids = {}

	for id in pairs(CraftingBenches) do
		ids[#ids + 1] = id
	end

	for i = 1, #ids do
		removeBench(ids[i])
	end

	table.wipe(CraftingBenches)
	table.wipe(BenchZones)
	table.wipe(BenchPoints)
	table.wipe(BenchTargetEntities)
	table.wipe(BenchProps)
	table.wipe(BenchMoving)
end)

return CraftingBenches






