if not lib then return end

require 'modules.bridge.client'
require 'modules.interface.client'

local Utils = require 'modules.utils.client'
local Weapon = require 'modules.weapon.client'
local Utility = require 'modules.utility.client'
local Items
local currentWeapon
local playerBackpack
local MagazineData = lib.load('data.magazines') or {}
local MagazineItems = {}
local weightDebugEnabled = false

local function weightDebug(...)
	if not weightDebugEnabled then return end
	print('[ox_inventory][weight]', ...)
end

for ammoType, data in pairs(MagazineData) do
	data.ammoType = ammoType
	MagazineItems[data.name] = data
end

exports('getCurrentWeapon', function()
	return currentWeapon
end)

RegisterNetEvent('ox_inventory:disarm', function(noAnim)
	currentWeapon = Weapon.Disarm(currentWeapon, noAnim)
end)

RegisterNetEvent('ox_inventory:clearWeapons', function()
	Weapon.ClearAll(currentWeapon)
end)

RegisterNetEvent('ox_inventory:utility:setBackpack', function(backpack)
	playerBackpack = backpack or nil
	SendNUIMessage({
		action = 'setPlayerBackpack',
		data = backpack
	})
end)

local StashTarget

exports('setStashTarget', function(id, owner)
	StashTarget = id and { id = id, owner = owner }
end)

---@type boolean | number
local invBusy = true

---@type boolean?
local invOpen = false
local plyState = LocalPlayer.state
local IsPedCuffed = IsPedCuffed
local playerPed = cache.ped

local dropObjects = {}
local dropObjectsByNetId = {}
client.dropObjects = dropObjects
client.dropObjectsByNetId = dropObjectsByNetId
local weaponModelFromName
local giveItemToTarget
local isGiveTargetValid

local function throwDebug(...)
	if not shared.ammodebug then return end

	local parts = table.pack(...)
	for i = 1, parts.n do
		parts[i] = tostring(parts[i])
	end

	lib.print.info('[throw-debug]', table.unpack(parts, 1, parts.n))
end

local function placeDropEntity(entity, coords, disableCollision)
	if not entity or not DoesEntityExist(entity) then return end

	SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)
	PlaceObjectOnGroundOrObjectProperly(entity)
	FreezeEntityPosition(entity, true)

	if disableCollision == nil or disableCollision then
		SetEntityCollision(entity, false, false)
	else
		SetEntityCollision(entity, true, true)
	end
end

local function addDropTarget(entity, dropId)
	if not entity or not DoesEntityExist(entity) then return end

	exports.ox_target:addLocalEntity(entity, {
		{
			name = 'pickup_drop',
			icon = 'fa-solid fa-box-open',
			label = 'Open Drop',
			distance = 3.5,
			onSelect = function()
				exports.ox_inventory:openInventory('drop', dropId)
			end
		}
	})
end

local function resolveThrowPreviewModel(item, props)
	if item?.name then
		local weaponModel = weaponModelFromName(tostring(item.name))
		if weaponModel then
			return weaponModel
		end
	end

	local model = props?.modelp or props?.prop

	if type(model) == 'table' then
		model = model.modelp or model.model
	end

	if type(model) == 'string' then
		model = joaat(model)
	end

	if model and model ~= 0 and (IsModelValid(model) or IsModelInCdimage(model)) then
		return model
	end
end

local function getThrowWeightProfile(itemWeight)
	local weight = math.max(0, tonumber(itemWeight) or 0)
	local weightKg = weight / 1000.0
	local heavyScale = math.min(weightKg / 4.5, 1.0)
	local lightScale = 1.0 - heavyScale
	local throwDistance = 1.0 + (lightScale * 12.0)
	local previewDistance = 2.0 + (lightScale * 1.5)
	local basePeakHeight = 0.65 + (lightScale * 1.05)
	local durationScale = 0.88 + (lightScale * 0.28)

	throwDebug('throw_weight_profile', 'weight', weight, 'weightKg', string.format('%.2f', weightKg), 'heavyScale',
		string.format('%.2f', heavyScale), 'throwDistance', string.format('%.2f', throwDistance), 'previewDistance',
		string.format('%.2f', previewDistance), 'basePeakHeight', string.format('%.2f', basePeakHeight),
		'durationScale', string.format('%.2f', durationScale))

return {
		weight = weight,
		weightKg = weightKg,
		heavyScale = heavyScale,
		lightScale = lightScale,
		throwDistance = throwDistance,
		previewDistance = previewDistance,
		basePeakHeight = basePeakHeight,
		durationScale = durationScale,
	}
end

local function resolveTargetGroundCoords(targetCoords)
	local startCoords = vec3(targetCoords.x, targetCoords.y, targetCoords.z + 12.0)
	local endCoords = vec3(targetCoords.x, targetCoords.y, targetCoords.z - 80.0)
	local groundHandle = StartShapeTestLosProbe(startCoords.x, startCoords.y, startCoords.z, endCoords.x, endCoords.y,
		endCoords.z, 511, cache.ped, 4)

	while true do
		Wait(0)
		local groundRetval, groundHit, groundEndCoords = GetShapeTestResult(groundHandle)

		if groundRetval ~= 1 then
			if groundHit then
				return vec3(groundEndCoords.x, groundEndCoords.y, groundEndCoords.z + 0.02)
			end

			return vec3(targetCoords.x, targetCoords.y, targetCoords.z)
		end
	end
end

local function getThrowPreviewCoords(itemWeight, ignoredEntity)
	local profile = getThrowWeightProfile(itemWeight)
	local camCoords = GetGameplayCamCoord()
	local camRot = GetGameplayCamRot(2)
	local pitch = math.rad(camRot.x)
	local yaw = math.rad(camRot.z)
	local forward = vec3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
	local destination = camCoords + (forward * profile.throwDistance)
	local restoreVisibility
	local minDistance = math.max(0.5, profile.throwDistance * 0.28)

	if ignoredEntity and DoesEntityExist(ignoredEntity) then
		restoreVisibility = IsEntityVisible(ignoredEntity)
		SetEntityVisible(ignoredEntity, false, false)
	end

	local handle = StartShapeTestLosProbe(camCoords.x, camCoords.y, camCoords.z, destination.x, destination.y, destination.z, 511, cache.ped, 4)

	while true do
		Wait(0)
		local retval, hit, endCoords, _, hitEntity = GetShapeTestResult(handle)

		if retval ~= 1 then
			if ignoredEntity and DoesEntityExist(ignoredEntity) then
				SetEntityVisible(ignoredEntity, restoreVisibility ~= false, false)
			end

			if hit then
				local hitCoords = vec3(endCoords.x, endCoords.y, endCoords.z + 0.02)
				local hitDistance = #(hitCoords - camCoords)

				if hitEntity and hitEntity ~= 0 and hitEntity ~= ignoredEntity then
					return hitCoords
				end

				if hitDistance >= minDistance then
					return hitCoords
				end

				local adjustedCoords = resolveTargetGroundCoords(destination)
				throwDebug('throw_target_adjusted', 'originalDistance', string.format('%.2f', hitDistance), 'minimumDistance',
					string.format('%.2f', minDistance), 'adjustedTarget', json.encode(adjustedCoords))
				return adjustedCoords
			end

			return resolveTargetGroundCoords(destination)
		end
	end
end

local function getThrowPreviewPoint(maxDistance, itemWeight)
	local profile = getThrowWeightProfile(itemWeight)
	local camCoords = GetGameplayCamCoord()
	local camRot = GetGameplayCamRot(2)
	local pitch = math.rad(camRot.x)
	local yaw = math.rad(camRot.z)
	local forward = vec3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
	local destination = camCoords + (forward * math.min(maxDistance or profile.previewDistance, profile.previewDistance))
	local handle = StartShapeTestLosProbe(camCoords.x, camCoords.y, camCoords.z, destination.x, destination.y, destination.z, 511, cache.ped, 4)

	while true do
		Wait(0)
		local retval, hit, endCoords, _, hitEntity = GetShapeTestResult(handle)

		if retval ~= 1 then
			if hit then
				return vec3(endCoords.x, endCoords.y, endCoords.z + 0.02), hitEntity, true
			end

			local fallback = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 1.75, 0.0)
			return vec3(fallback.x, fallback.y, fallback.z), nil, false
		end
	end
end

local function getPlacePreviewCoords(itemWeight, ignoredEntity)
	local profile = getThrowWeightProfile(itemWeight)
	local camCoords = GetGameplayCamCoord()
	local camRot = GetGameplayCamRot(2)
	local pitch = math.rad(camRot.x)
	local yaw = math.rad(camRot.z)
	local forward = vec3(-math.sin(yaw) * math.cos(pitch), math.cos(yaw) * math.cos(pitch), math.sin(pitch))
	local maxPlaceDistance = 5.0
	local destination = camCoords + (forward * math.min(profile.throwDistance, maxPlaceDistance))
	local restoreVisibility

	if ignoredEntity and DoesEntityExist(ignoredEntity) then
		restoreVisibility = IsEntityVisible(ignoredEntity)
		SetEntityVisible(ignoredEntity, false, false)
	end

	local handle = StartShapeTestLosProbe(camCoords.x, camCoords.y, camCoords.z, destination.x, destination.y,
		destination.z, 511, cache.ped, 4)

	while true do
		Wait(0)
		local retval, hit, endCoords = GetShapeTestResult(handle)

		if retval ~= 1 then
			if ignoredEntity and DoesEntityExist(ignoredEntity) then
				SetEntityVisible(ignoredEntity, restoreVisibility ~= false, false)
			end

			if hit then
				return vec3(endCoords.x, endCoords.y, endCoords.z + 0.02)
			end

			return resolveTargetGroundCoords(destination)
		end
	end
end

local function startNativeBallCleanup(ped, baseballPropHash, debugScope, durationMs, focusCoords, radius)
	CreateThread(function()
		local expiresAt = GetGameTimer() + (durationMs or 2200)
		local searchRadius = radius or 20.0
		local lastLoggedEntity

		while GetGameTimer() < expiresAt do
			local searchCoords = focusCoords or GetEntityCoords(ped)
			local nativeBall = GetClosestObjectOfType(searchCoords.x, searchCoords.y, searchCoords.z, searchRadius,
				baseballPropHash, false, false, false)

			if nativeBall and nativeBall ~= 0 and DoesEntityExist(nativeBall) then
				SetEntityVisible(nativeBall, false, false)
				SetEntityCollision(nativeBall, false, false)
				DeleteEntity(nativeBall)

				if nativeBall ~= lastLoggedEntity then
					lastLoggedEntity = nativeBall
					throwDebug(debugScope .. ':native_ball_cleanup', 'entity', nativeBall)
				end
			end

			Wait(0)
		end
	end)
end

local function animateThrownEntity(entity, startCoords, targetCoords, itemWeight, debugScope)
	if not entity or not DoesEntityExist(entity) or not startCoords or not targetCoords then return end

	local profile = getThrowWeightProfile(itemWeight)
	local dx = targetCoords.x - startCoords.x
	local dy = targetCoords.y - startCoords.y
	local dz = targetCoords.z - startCoords.z
	local distance = math.sqrt((dx * dx) + (dy * dy) + (dz * dz))
	local duration = math.max(260, math.min(900, math.floor((240 + (distance * 110.0)) * profile.durationScale)))
	local peakHeight = profile.basePeakHeight + math.min(distance * 0.16, 1.2)
	local heading = distance > 0.001 and GetHeadingFromVector_2d(dx, dy) or GetEntityHeading(entity)

	throwDebug(debugScope .. ':arc_start', 'entity', entity, 'distance', string.format('%.2f', distance), 'duration',
		duration, 'peakHeight', string.format('%.2f', peakHeight), 'target', json.encode(targetCoords))

	CreateThread(function()
		local startedAt = GetGameTimer()

		SetEntityCollision(entity, false, false)
		SetEntityDynamic(entity, false)
		FreezeEntityPosition(entity, true)

		while DoesEntityExist(entity) do
			local elapsed = GetGameTimer() - startedAt
			local t = math.min(elapsed / duration, 1.0)
			local invT = 1.0 - t
			local arcHeight = 4.0 * peakHeight * t * invT
			local x = startCoords.x + (dx * t)
			local y = startCoords.y + (dy * t)
			local z = startCoords.z + (dz * t) + arcHeight

			SetEntityCoordsNoOffset(entity, x, y, z, false, false, false)
			SetEntityHeading(entity, heading)

			if t >= 1.0 then
				break
			end

			Wait(0)
		end

		if DoesEntityExist(entity) then
			SetEntityCoordsNoOffset(entity, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false)
			throwDebug(debugScope .. ':cleanup_timeout', 'entity', entity, 'coords', json.encode(GetEntityCoords(entity)))
			DeleteEntity(entity)
		end
	end)
end

local function startBaseballThrowMode(model, itemWeight)
	if not model then return false end

	local ped = cache.ped
	local baseballHash = `WEAPON_BALL`
	local baseballPropHash = joaat('w_am_baseball')
	local threw = false
	local throwStartCoords
	local throwTargetCoords

	throwDebug('startBaseballThrowMode:start', 'model', model, 'weight', itemWeight, 'selectedWeaponBefore',
		GetSelectedPedWeapon(ped))

	lib.requestModel(model)

	GiveWeaponToPed(ped, baseballHash, 1, false, true)
	SetPedAmmo(ped, baseballHash, 1)
	SetPedInfiniteAmmoClip(ped, true)
	SetCurrentPedWeapon(ped, baseballHash, true)
	SetPedCurrentWeaponVisible(ped, false, false, false, false)
	throwDebug('startBaseballThrowMode:weapon_prepared', 'weapon', baseballHash, 'hasWeapon',
		HasPedGotWeapon(ped, baseballHash, false) and 'true' or 'false', 'selectedWeaponAfter',
		GetSelectedPedWeapon(ped), 'ammo', GetAmmoInPedWeapon(ped, baseballHash))

	local handCoords = GetPedBoneCoords(ped, 57005, 0.1, 0.0, 0.0)
	local entity = CreateObject(model, handCoords.x, handCoords.y, handCoords.z, true, true, false)

	if not entity or not DoesEntityExist(entity) then
		throwDebug('startBaseballThrowMode:create_failed', 'model', model)
		SetModelAsNoLongerNeeded(model)
		RemoveWeaponFromPed(ped, baseballHash)
		SetPedInfiniteAmmoClip(ped, false)
		SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
		SetPedCurrentWeaponVisible(ped, true, false, false, false)
		return false
	end

	SetEntityAsMissionEntity(entity, true, true)
	SetEntityCollision(entity, false, false)
	SetEntityDynamic(entity, false)
	SetEntityInvincible(entity, true)
	NetworkRegisterEntityAsNetworked(entity)

	local netId = NetworkGetNetworkIdFromEntity(entity)

	if netId and netId ~= 0 then
		SetNetworkIdCanMigrate(netId, true)
		SetNetworkIdExistsOnAllMachines(netId, true)
	end

	AttachEntityToEntity(entity, ped, GetPedBoneIndex(ped, 57005), 0.14, 0.02, -0.02, 0.0, 92.0, 8.0,
		false, false, false, false, 2, true)
	throwDebug('startBaseballThrowMode:entity_attached', 'entity', entity, 'netId', netId or 0)
	SetModelAsNoLongerNeeded(model)

	startNativeBallCleanup(ped, baseballPropHash, 'startBaseballThrowMode', 2200, nil, 22.0)

	local timeoutAt = GetGameTimer() + 4500

	while DoesEntityExist(entity) and GetGameTimer() < timeoutAt do
		DisableFrontendThisFrame()
		SetCurrentPedWeapon(ped, baseballHash, true)
		SetPedAmmo(ped, baseballHash, 1)
		SetPedCurrentWeaponVisible(ped, false, false, false, false)

		if IsControlJustReleased(2, 200) then
			throwDebug('startBaseballThrowMode:cancelled', 'entity', entity)
			break
		end

		if IsPedShooting(ped) then
			threw = true
			throwStartCoords = GetPedBoneCoords(ped, 57005, 0.18, 0.0, 0.0)
			throwTargetCoords = getThrowPreviewCoords(itemWeight, entity)

			throwDebug('startBaseballThrowMode:shot_detected', 'entity', entity, 'start', json.encode(throwStartCoords),
				'target', json.encode(throwTargetCoords), 'selectedWeapon', GetSelectedPedWeapon(ped))

			DetachEntity(entity, true, true)
			Wait(0)

			if DoesEntityExist(entity) then
				SetEntityInvincible(entity, true)
				animateThrownEntity(entity, throwStartCoords, throwTargetCoords, itemWeight, 'startBaseballThrowMode')
				startNativeBallCleanup(ped, baseballPropHash, 'startBaseballThrowMode', 2600, throwTargetCoords,
					math.max(18.0, #(throwTargetCoords - throwStartCoords) + 8.0))
			end

			break
		end

		Wait(0)
	end

	if not threw and DoesEntityExist(entity) then
		DetachEntity(entity, true, true)
		DeleteEntity(entity)
	end

	RemoveWeaponFromPed(ped, baseballHash)
	SetPedInfiniteAmmoClip(ped, false)
	SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
	SetPedCurrentWeaponVisible(ped, true, false, false, false)
	throwDebug('startBaseballThrowMode:cleanup_complete', 'threw', threw and 'true' or 'false', 'selectedWeaponEnd',
		GetSelectedPedWeapon(ped))

	return threw, throwStartCoords, throwTargetCoords
end

local function playNetworkedThrowVisual(model, startCoords, targetCoords, itemWeight)
	if not model or not startCoords or not targetCoords then return end

	throwDebug('playNetworkedThrowVisual:start', 'model', model, 'start', json.encode(startCoords), 'target',
		json.encode(targetCoords), 'weight', itemWeight)

	CreateThread(function()
		local ped = cache.ped
		local baseballHash = `WEAPON_BALL`
		local baseballPropHash = joaat('w_am_baseball')

		throwDebug('playNetworkedThrowVisual:thread_started', 'ped', ped, 'playerPed', playerPed, 'selectedWeaponBefore',
			GetSelectedPedWeapon(ped))

		lib.requestModel(model)

		GiveWeaponToPed(ped, baseballHash, 1, false, true)
		SetPedAmmo(ped, baseballHash, 1)
		SetPedInfiniteAmmoClip(ped, true)
		SetCurrentPedWeapon(ped, baseballHash, true)
		SetPedCurrentWeaponVisible(ped, false, false, false, false)
		throwDebug('playNetworkedThrowVisual:weapon_prepared', 'weapon', baseballHash, 'selectedWeaponAfter',
			GetSelectedPedWeapon(ped), 'ammo', GetAmmoInPedWeapon(ped, baseballHash))

		local entity = CreateObject(model, startCoords.x, startCoords.y, startCoords.z, true, true, false)

		if not entity or not DoesEntityExist(entity) then
			throwDebug('playNetworkedThrowVisual:create_failed', 'model', model)
			SetModelAsNoLongerNeeded(model)
			RemoveWeaponFromPed(ped, baseballHash)
			SetPedInfiniteAmmoClip(ped, false)
			SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
			SetPedCurrentWeaponVisible(ped, true, false, false, false)
			return
		end

		throwDebug('playNetworkedThrowVisual:created', 'entity', entity, 'coords', json.encode(GetEntityCoords(entity)))

		SetEntityAsMissionEntity(entity, true, true)
		SetEntityCollision(entity, false, false)
		SetEntityDynamic(entity, false)
		SetEntityInvincible(entity, true)
		NetworkRegisterEntityAsNetworked(entity)

		local netId = NetworkGetNetworkIdFromEntity(entity)

		if netId and netId ~= 0 then
			SetNetworkIdCanMigrate(netId, true)
			SetNetworkIdExistsOnAllMachines(netId, true)
		end

		AttachEntityToEntity(entity, ped, GetPedBoneIndex(ped, 57005), 0.14, 0.02, -0.02, 0.0, 92.0, 8.0,
			false, false, false, false, 2, true)

		throwDebug('playNetworkedThrowVisual:attached', 'entity', entity, 'netId', netId or 0)
		SetModelAsNoLongerNeeded(model)

		startNativeBallCleanup(ped, baseballPropHash, 'playNetworkedThrowVisual', 2200, nil, 22.0)

		local threw = false
		local timeoutAt = GetGameTimer() + 2500
		local lastSelectedWeapon
		local loggedWeaponMismatch = false

		while DoesEntityExist(entity) and GetGameTimer() < timeoutAt do
			SetCurrentPedWeapon(ped, baseballHash, true)
			SetPedAmmo(ped, baseballHash, 1)
			SetPedCurrentWeaponVisible(ped, false, false, false, false)

			local selectedWeapon = GetSelectedPedWeapon(ped)

			if lastSelectedWeapon ~= selectedWeapon then
				lastSelectedWeapon = selectedWeapon
				throwDebug('playNetworkedThrowVisual:selected_weapon_changed', 'selectedWeapon', selectedWeapon, 'expected',
					baseballHash)
			end

			if not loggedWeaponMismatch and selectedWeapon ~= baseballHash then
				loggedWeaponMismatch = true
				throwDebug('playNetworkedThrowVisual:weapon_mismatch_detected', 'selectedWeapon', selectedWeapon, 'expected',
					baseballHash)
			end

			if IsPedShooting(ped) then
				threw = true
				throwDebug('playNetworkedThrowVisual:shot_detected', 'selectedWeapon', selectedWeapon, 'entity', entity)
				DetachEntity(entity, true, true)
				Wait(0)

				if DoesEntityExist(entity) then
					SetEntityInvincible(entity, true)
					animateThrownEntity(entity, startCoords, targetCoords, itemWeight, 'playNetworkedThrowVisual')
					startNativeBallCleanup(ped, baseballPropHash, 'playNetworkedThrowVisual', 2600, targetCoords,
						math.max(18.0, #(targetCoords - startCoords) + 8.0))
				end

				break
			end

			Wait(0)
		end

		if not threw and DoesEntityExist(entity) then
			throwDebug('playNetworkedThrowVisual:cleanup_no_shot', 'entity', entity, 'selectedWeaponFinal',
				GetSelectedPedWeapon(ped), 'ammoFinal', GetAmmoInPedWeapon(ped, baseballHash))
			DetachEntity(entity, true, true)
			DeleteEntity(entity)
		end

		RemoveWeaponFromPed(ped, baseballHash)
		SetPedInfiniteAmmoClip(ped, false)
		SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
		SetPedCurrentWeaponVisible(ped, true, false, false, false)
		throwDebug('playNetworkedThrowVisual:cleanup_complete', 'selectedWeaponEnd', GetSelectedPedWeapon(ped))
	end)
end

RegisterNetEvent('ox_inventory:playThrowVisual', function(model, startCoords, targetCoords, itemWeight)
	playNetworkedThrowVisual(model, startCoords, targetCoords, itemWeight)
end)

local function findClosestGiveTarget()
	local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(playerPed), 3.0)
	local closestServerId
	local closestDistance

	for i = 1, #nearbyPlayers do
		local option = nearbyPlayers[i]

		if isGiveTargetValid(option.ped, option.coords) then
			local distance = #(GetEntityCoords(playerPed, true) - option.coords)

			if not closestDistance or distance < closestDistance then
				closestDistance = distance
				closestServerId = GetPlayerServerId(option.id)
			end
		end
	end

	return closestServerId
end

local function getThrowItemWeight(item, props, amount)
	local definition = item?.name and Items[item.name]
	local unitWeight = tonumber(item?.weight)

	if not unitWeight or unitWeight <= 0 then
		unitWeight = tonumber(props?.weight)
	end

	if (not unitWeight or unitWeight <= 0) and definition then
		unitWeight = tonumber(definition.weight)
	end

	return math.max(0, unitWeight or 0) * math.max(amount or 1, 1)
end

local function computeUtilityWeight(items)
	if not Utility.enabled then return 0 end

	local total = 0

	-- Use the canonical utility state to avoid missing items (e.g., armour) when slot offsets/metadata differ
	local utilityState = Utility.collect(items)

	if not utilityState or not utilityState.items then
		return 0
	end

	for _, slotData in pairs(utilityState.items) do
		if slotData and slotData.name then
			local def = Items and Items[slotData.name]
			local unitWeight = tonumber(slotData.weight)
			local weightSource = 'slotData.weight'

			-- Fall back to metadata-provided weights (containers/utility often inject size/weight)
			if (not unitWeight or unitWeight <= 0) and slotData.metadata then
				unitWeight = tonumber(slotData.metadata.weight)
					or tonumber(slotData.metadata?.size and slotData.metadata.size[2])
				if unitWeight and unitWeight > 0 then
					weightSource = 'metadata'
				end
			end

			-- Final fallback: static item definition
			if not unitWeight or unitWeight <= 0 then
				unitWeight = def and tonumber(def.weight) or 0
				weightSource = 'definition'
			end

			local count = slotData.count or 1
			weightDebug(('slot %s (%s) x%s -> %sg (%s)'):format(
				tostring(slotData.slot or '?'),
				slotData.name,
				count,
				unitWeight * count,
				weightSource
			))
			total += unitWeight * count
		end
	end

	weightDebug('utility total', total)
	return total
end

local function applyUtilityWeight(baseWeight, items)
	local utilityWeight = computeUtilityWeight(items or PlayerData.inventory)
	weightDebug('server weight', baseWeight or 0, 'utility breakdown', utilityWeight)

	if (baseWeight or 0) ~= PlayerData.weight then
		client.setPlayerData('weight', baseWeight or 0)
	end

	return utilityWeight
end

local function startItemThrowPreview(item, props, amount, data)
	local model = resolveThrowPreviewModel(item, props)
	local itemWeight = getThrowItemWeight(item, props, amount)
	local throwProfile = getThrowWeightProfile(itemWeight)

	if not model then return false end

	lib.requestModel(model)
	local previewCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 1.5, 0.0)
	local previewEntity = CreateObject(model, previewCoords.x, previewCoords.y, previewCoords.z, false, false, false)

	if not previewEntity or not DoesEntityExist(previewEntity) then
		SetModelAsNoLongerNeeded(model)
		return false
	end

	SetEntityAsMissionEntity(previewEntity, true, true)
	SetEntityCollision(previewEntity, false, false)
	SetEntityDynamic(previewEntity, false)
	SetEntityInvincible(previewEntity, true)
	SetEntityAlpha(previewEntity, 190, false)
	SetModelAsNoLongerNeeded(model)

	lib.showTextUI('[RMB] aim throw\n[N] place\n[G] give closest\n[ESC] cancel', {
		position = 'bottom-center',
	})

	local placed = false
	local response

	while DoesEntityExist(previewEntity) do
		DisableFrontendThisFrame()
		DisableControlAction(0, 14, true)
		DisableControlAction(0, 15, true)

		local targetCoords = getPlacePreviewCoords(itemWeight, previewEntity)
		SetEntityCoordsNoOffset(previewEntity, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false)

		local placePressed249 = IsControlJustPressed(0, 249)
		local placePressed306 = IsControlJustPressed(0, 306)
		local placePressedDisabled249 = IsDisabledControlJustPressed(0, 249)
		local placePressedDisabled306 = IsDisabledControlJustPressed(0, 306)

		if IsControlJustReleased(2, 200) then
			break
		end

		if IsControlJustPressed(0, 47) then
			local targetId = findClosestGiveTarget()

			if targetId then
				giveItemToTarget(targetId, item.slot or data.slot, amount, item.inventory)
				placed = true
				break
			else
				lib.notify({ type = 'error', description = 'No nearby player to give to.' })
			end
		end

		if placePressed249 or placePressed306 or placePressedDisabled249 or placePressedDisabled306 then
			local success
			local placeStartCoords = GetPedBoneCoords(cache.ped, 57005, 0.18, 0.0, 0.0)
			local pressedControl = placePressed249 and 249 or placePressed306 and 306 or placePressedDisabled249 and 'disabled_249' or 'disabled_306'

			throwDebug('throw_place_key_pressed', 'control', pressedControl, 'slot', item.slot or data.slot, 'amount', amount,
				'previewTarget', json.encode(targetCoords), 'playerCoords', json.encode(GetEntityCoords(cache.ped)))
			throwDebug('throw_place_controls_state', '249', placePressed249 and 'true' or 'false', '306',
				placePressed306 and 'true' or 'false', 'disabled_249', placePressedDisabled249 and 'true' or 'false',
				'disabled_306', placePressedDisabled306 and 'true' or 'false')
			throwDebug('throw_place_requested', 'slot', item.slot or data.slot, 'count', amount, 'target',
				json.encode(targetCoords), 'start', json.encode(placeStartCoords), 'instance', currentInstance or 'nil',
				'model', model, 'weight', itemWeight, 'previewDistance', string.format('%.2f', throwProfile.previewDistance),
				'throwDistance', string.format('%.2f', throwProfile.throwDistance))
			success, response = lib.callback.await('ox_inventory:throwItemDrop', false, {
				slot = item.slot or data.slot,
				count = amount,
				coords = targetCoords,
				instance = currentInstance,
				model = model,
				startCoords = placeStartCoords,
			})
			throwDebug('throw_place_response', 'success', success and 'true' or 'false', 'target',
				json.encode(targetCoords), 'responseWeight', response and response.weight or 'nil', 'items',
				response and response.items and json.encode(response.items) or 'nil')
			placed = success and true or false
			break
		end

		if IsControlPressed(0, 25) or IsPlayerFreeAiming(cache.playerId) then
			throwDebug('startItemThrowPreview:enter_throw_mode', 'slot', item.slot or data.slot, 'model', model, 'weight',
				itemWeight, 'throwDistance', string.format('%.2f', throwProfile.throwDistance), 'playerWeapon',
				GetSelectedPedWeapon(cache.ped))
			lib.hideTextUI()

			if DoesEntityExist(previewEntity) then
				DeleteEntity(previewEntity)
			end

			lib.showTextUI('[LMB] throw\n[ESC] cancel', {
				position = 'bottom-center',
			})
			local success
			local threw, throwStartCoords, throwTargetCoords = startBaseballThrowMode(model, itemWeight)

			lib.hideTextUI()

			if threw and throwStartCoords and throwTargetCoords then
				throwDebug('throw_callback_request', 'slot', item.slot or data.slot, 'start', json.encode(throwStartCoords),
					'target', json.encode(throwTargetCoords), 'weight', itemWeight, 'throwDistance',
					string.format('%.2f', throwProfile.throwDistance))
				success, response = lib.callback.await('ox_inventory:throwItemDrop', false, {
					slot = item.slot or data.slot,
					count = amount,
					coords = throwTargetCoords,
					instance = currentInstance,
					model = model,
					startCoords = throwStartCoords,
					itemWeight = itemWeight,
				})
				throwDebug('throw_callback_response', 'success', success and 'true' or 'false', 'target',
					json.encode(throwTargetCoords), 'responseWeight', response and response.weight or 'nil', 'items',
					response and response.items and json.encode(response.items) or 'nil')
				placed = success and true or false
			else
				throwDebug('startItemThrowPreview:throw_cancelled_or_failed', 'slot', item.slot or data.slot, 'model', model)
			end

			SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
			SetPedCurrentWeaponVisible(cache.ped, true, false, false, false)

			return placed, response
		end

		Wait(0)
	end

	lib.hideTextUI()

	if DoesEntityExist(previewEntity) then
		DeleteEntity(previewEntity)
	end

	StopAnimTask(cache.ped, 'weapons@projectile@', 'aimlive_m_fb_stand', 1.0)
	SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
	SetPedCurrentWeaponVisible(cache.ped, true, false, false, false)

	return placed, response
end

lib.onCache('ped', function(ped)
	playerPed = ped
	Utils.WeaponWheel()
end)

plyState:set('invBusy', true, true)
plyState:set('invHotkeys', false, false)
plyState:set('canUseWeapons', false, false)

local function canOpenInventory()
	if not PlayerData.loaded then
		return shared.info('cannot open inventory', '(player inventory has not loaded)')
	end

	if IsPauseMenuActive() then return end

	if invBusy or invOpen == nil or (currentWeapon?.timer or 0) > 0 then
		return shared.info('cannot open inventory', '(is busy)')
	end

	if PlayerData.dead or IsPedFatallyInjured(playerPed) then
		return shared.info('cannot open inventory', '(fatal injury)')
	end

	if PlayerData.cuffed or IsPedCuffed(playerPed) then
		return shared.info('cannot open inventory', '(cuffed)')
	end

	return true
end

---@param ped number
---@return boolean
local function canOpenTarget(ped)
	return IsPedFatallyInjured(ped)
		or IsEntityPlayingAnim(ped, 'dead', 'dead_a', 3)
		or IsPedCuffed(ped)
		or IsEntityPlayingAnim(ped, 'mp_arresting', 'idle', 3)
		or IsEntityPlayingAnim(ped, 'missminuteman_1ig_2', 'handsup_base', 3)
		or IsEntityPlayingAnim(ped, 'missminuteman_1ig_2', 'handsup_enter', 3)
		or IsEntityPlayingAnim(ped, 'random@mugging3', 'handsup_standing_base', 3)
end

local defaultInventory = {
	type = 'newdrop',
	slots = shared.playerslots,
	weight = 0,
	maxWeight = shared.playerweight,
	items = {}
}

local currentInventory = defaultInventory
local Theme = lib.load('data.ui') or {}
local Rarity = lib.load('data.rarity')


local function closeTrunk()
	if currentInventory?.type == 'trunk' then
		local coords = GetEntityCoords(playerPed, true)
		---@todo animation for vans?
		Utils.PlayAnimAdvanced(0, 'anim@heists@fleeca_bank@scope_out@return_case', 'trevor_action', coords.x, coords.y,
			coords.z, 0.0, 0.0, GetEntityHeading(playerPed), 2.0, 2.0, 1000, 49, 0.25)

		CreateThread(function()
			local entity = currentInventory.entity
			local door = currentInventory.door
			Wait(900)

			if type(door) == 'table' then
				for i = 1, #door do
					SetVehicleDoorShut(entity, door[i], false)
				end
			else
				SetVehicleDoorShut(entity, door, false)
			end
		end)
	end
end

local CraftingBenches = require 'modules.crafting.client'
local Vehicles = lib.load('data.vehicles')
local Inventory = require 'modules.inventory.client'
local getKeybindLabel
local buildUtilityHotkeyLabels
local buildInventoryTabHotkeys
local applyDynamicUtilityConfig

---@param inv string?
---@param data any?
---@return boolean?
function client.openInventory(inv, data)
	if invOpen then
		if not inv and currentInventory.type == 'newdrop' then
			return client.closeInventory()
		end

		if IsNuiFocused() then
			if inv == 'container' and type(data) == 'number' then
				local containerItem = PlayerData.inventory[data]
				local containerId = containerItem and containerItem.metadata and containerItem.metadata.container
				local isWeaponMagazineContainer = containerItem and Items(containerItem.name)?.weapon and containerItem.metadata?.magContainer

				if not isWeaponMagazineContainer and containerId and currentInventory.id == containerId then
					return client.closeInventory()
				end
			end

			if inv == 'weaponmag' and type(data) == 'number' then
				local weaponSlot = PlayerData.inventory[data]
				local magContainer = weaponSlot and weaponSlot.metadata and weaponSlot.metadata.magContainer

				if magContainer and currentInventory.type == 'weaponmag' and currentInventory.id == magContainer then
					return client.closeInventory()
				end
			end

			if currentInventory.type == 'drop' and (not data or currentInventory.id == (type(data) == 'table' and data.id or data)) then
				return client.closeInventory()
			end

			if inv ~= 'drop' and inv ~= 'container' and inv ~= 'weaponmag' then
				if (data?.id or data) == currentInventory?.id then
					-- Triggering exports.ox_inventory:openInventory('stash', 'mystash') twice in rapid succession is weird behaviour
					return warn(("script tried to open inventory, but it is already open\n%s"):format(Citizen
						.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString())))
				else
					return client.closeInventory()
				end
			end
		end
	elseif IsNuiFocused() then
		-- If triggering from another nui, may need to wait for focus to end.
		Wait(100)

		-- People still complain about this being an "error" and ask "how fix" despite being a warning
		-- for people with above room-temperature iqs to look into resource conflicts on their own.
		-- if IsNuiFocused() then
		-- 	warn('other scripts have nui focus and may cause issues (e.g. disable focus, prevent input, overlap inventory window)')
		-- end
	end

	if inv == 'dumpster' and cache.vehicle then
		return lib.notify({ id = 'inventory_right_access', type = 'error', description = locale('inventory_right_access') })
	end

	if not canOpenInventory() then
		return lib.notify({
			id = 'inventory_player_access',
			type = 'error',
			description = locale(
				'inventory_player_access')
		})
	end

	local left, right, accessError, craftingStorage

	if inv == 'player' and data ~= cache.serverId then
		local targetId, targetPed

		if not data then
			targetId, targetPed = Utils.GetClosestPlayer()
			data = targetId and GetPlayerServerId(targetId)
		else
			local serverId = type(data) == 'table' and data.id or data

			if serverId == cache.serverId then return end

			targetId = serverId and GetPlayerFromServerId(serverId)
			targetPed = targetId and GetPlayerPed(targetId)
		end

		local targetCoords = targetPed and GetEntityCoords(targetPed)

		if not targetCoords or #(targetCoords - GetEntityCoords(playerPed)) > 1.8 or not (client.hasGroup(shared.police) or canOpenTarget(targetPed)) then
			return lib.notify({
				id = 'inventory_right_access',
				type = 'error',
				description = locale(
					'inventory_right_access')
			})
		end
	end

	if inv == 'shop' and invOpen == false then
		if cache.vehicle then
			return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
		end

		left, right, accessError = lib.callback.await('ox_inventory:openShop', 200, data)
	elseif inv == 'crafting' then
		if cache.vehicle then
			return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
		end

		lib.print.debug('[ox_inventory] Opening crafting bench - id:', data.id, 'index:', data.index)

		left, right, accessError = lib.callback.await('ox_inventory:openCraftingBench', 200, data.id, data.index)

		lib.print.debug('[ox_inventory] Crafting bench callback result - left:', left and 'exists' or 'nil', 'right:',
			right and 'exists' or 'nil', 'accessError:', accessError)

		if left then
			lib.print.debug('[ox_inventory] Processing crafting bench data')

			local craftingInfo = left.crafting
			local storagePayload = left.storage

			lib.print.debug('[ox_inventory] Crafting info:', craftingInfo and 'exists' or 'nil', 'Storage payload:',
				storagePayload and 'exists' or 'nil')

			-- ensure the local craftingStorage (used later when wiring the UI) is set
			craftingStorage = storagePayload
			left.crafting = nil
			left.storage = nil

			local benchTemplate = CraftingBenches[data.id]

			lib.print.debug('[ox_inventory] Bench template:', benchTemplate and 'exists' or 'nil')

			if not benchTemplate?.items then
				lib.print.debug('[ox_inventory] No bench template items found for id:', data.id)
				return
			end

			local coords, distance

			if shared.target and benchTemplate.zones then
				local zone = benchTemplate.zones[data.index]
				if zone then
					coords = zone.coords
					distance = zone.distance or 2
					lib.print.debug('[ox_inventory] Using zone coords:', coords, 'distance:', distance)
				end
			elseif benchTemplate.points then
				coords = benchTemplate.points[data.index]
				distance = 2
				lib.print.debug('[ox_inventory] Using point coords:', coords, 'distance:', distance)
			end

			if not coords then
				coords = GetEntityCoords(cache.ped)
				distance = distance or 2
				lib.print.debug('[ox_inventory] Using player coords:', coords, 'distance:', distance)
			end

			right = {
				type = 'crafting',
				id = data.id,
				label = benchTemplate.label or locale('crafting_bench'),
				index = data.index,
				slots = benchTemplate.slots,
				items = benchTemplate.items,
				coords = coords,
				distance = distance,
				storage = storagePayload,
				crafting = craftingInfo
			}

			lib.print.debug('[ox_inventory] Created right inventory for crafting bench:', right.type, right.id,
				right.label)
		end
	elseif invOpen ~= nil then
		if inv == 'policeevidence' then
			if not data then
				local input = lib.inputDialog(locale('police_evidence'), {
					{ label = locale('locker_number'), type = 'number', required = true, icon = 'calculator' }
				}) --[[@as number[]? ]]

				if not input then return end

				data = input[1]
			end
		end

		left, right, accessError = lib.callback.await('ox_inventory:openInventory', false, inv, data)
	end

	if accessError then
		return lib.notify({ id = accessError, type = 'error', description = locale(accessError) })
	end

	-- Stash does not exist
	if not left then
		if left == false then return false end

		if invOpen == false then
			return lib.notify({
				id = 'inventory_right_access',
				type = 'error',
				description = locale(
					'inventory_right_access')
			})
		end

		if invOpen then return client.closeInventory() end
	end


	if not cache.vehicle then
		if inv == 'player' then
			Utils.PlayAnim(0, 'mp_common', 'givetake1_a', 8.0, 1.0, 2000, 50, 0.0, 0, 0, 0)
		elseif inv ~= 'trunk' then
			Utils.PlayAnim(0, 'pickup_object', 'putdown_low', 5.0, 1.5, 1000, 48, 0.0, 0, 0, 0)
		end
	end

	plyState.invOpen = true

	SetInterval(client.interval, 100)
	SetNuiFocus(true, true)
	SetNuiFocusKeepInput(true)
	closeTrunk()

	if client.screenblur then TriggerScreenblurFadeIn(0) end

	currentInventory = right or defaultInventory
	left.items = PlayerData.inventory
	left.groups = PlayerData.groups

	if currentInventory and currentInventory.type == 'crafting' then
		if craftingStorage then
			left.backpack = craftingStorage
		else
			left.backpack = nil
		end

		if currentInventory then
			currentInventory.backpack = nil
			currentInventory.otherBackpack = nil
			currentInventory.storage = craftingStorage
		end
	else
		left.backpack = left.backpack or nil

		if currentInventory then
			if currentInventory.otherBackpack then
				currentInventory.backpack = currentInventory.otherBackpack
			else
				currentInventory.backpack = nil
				currentInventory.otherBackpack = nil
			end

			currentInventory.storage = nil
		end
	end

	if Utility.enabled then
		left.utility = applyDynamicUtilityConfig(Utility.collect(PlayerData.inventory))
		left.utilityConfig = left.utility and left.utility.config or Utility.config

		if currentInventory then
			if currentInventory.items and (currentInventory.type == 'player' or currentInventory.type == 'inspect') then
				currentInventory.utility = applyDynamicUtilityConfig(Utility.collect(currentInventory.items))
			else
				currentInventory.utility = nil
			end
		end
	end

	left.weight = PlayerData.weight

	SendNUIMessage({
		action = 'setupInventory',
		data = {
			leftInventory = left,
			rightInventory = currentInventory
		}
	})

	if not currentInventory.coords and not inv == 'container' then
		currentInventory.coords = GetEntityCoords(playerPed)
	end

	if inv == 'trunk' then
		SetTimeout(200, function()
			---@todo animation for vans?
			Utils.PlayAnim(0, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 3.0, 3.0, -1, 49, 0.0, 0, 0,
				0)

			local entity = data.entity or NetworkGetEntityFromNetworkId(data.netid)
			currentInventory.entity = entity
			currentInventory.door = data.door

			if not currentInventory.door then
				local vehicleHash = GetEntityModel(entity)
				local vehicleClass = GetVehicleClass(entity)
				currentInventory.door = vehicleClass == 12 and { 2, 3 } or Vehicles.Storage[vehicleHash] and 4 or 5
			end

			while currentInventory?.entity == entity and invOpen and DoesEntityExist(entity) and Inventory.CanAccessTrunk(entity) do
				Wait(100)
			end

			if invOpen then client.closeInventory() end
		end)
	end

	return true
end

RegisterNetEvent('ox_inventory:openInventory', client.openInventory)
exports('openInventory', client.openInventory)

RegisterNetEvent('ox_inventory:forceOpenInventory', function(left, right)
	if source == '' then return end

	plyState.invOpen = true

	SetInterval(client.interval, 100)
	SetNuiFocus(true, true)
	SetNuiFocusKeepInput(true)
	closeTrunk()

	if client.screenblur then TriggerScreenblurFadeIn(0) end

	currentInventory = right or defaultInventory
	currentInventory.ignoreSecurityChecks = true
	left.items = PlayerData.inventory
	left.groups = PlayerData.groups
	left.weight = PlayerData.weight

	if Utility.enabled then
		left.utility = applyDynamicUtilityConfig(Utility.collect(PlayerData.inventory))
		left.utilityConfig = left.utility and left.utility.config or Utility.config

		if currentInventory and currentInventory.items then
			currentInventory.utility = applyDynamicUtilityConfig(Utility.collect(currentInventory.items))
		end
	end

	SendNUIMessage({
		action = 'setupInventory',
		data = {
			leftInventory = left,
			rightInventory = currentInventory
		}
	})
end)

local Animations = lib.load('data.animations')
Items = require 'modules.items.client'
local usingItem = false

---@param data { name: string, label: string, count: number, slot: number, metadata: table<string, any>, weight: number }
lib.callback.register('ox_inventory:usingItem', function(data, noAnim)
	local item = Items[data.name]

	if item and usingItem then
		if not item.client then return true end
		---@cast item +OxClientProps
		item = item.client

		if type(item.anim) == 'string' then
			item.anim = Animations.anim[item.anim]
		end

		if item.prop then
			if item.prop[1] then
				for i = 1, #item.prop do
					if type(item.prop) == 'string' then
						item.prop = Animations.prop[item.prop[i]]
					end
				end
			elseif type(item.prop) == 'string' then
				item.prop = Animations.prop[item.prop]
			end
		end

		if not item.disable then
			item.disable = { combat = true }
		elseif item.disable.combat == nil then
			item.disable.combat = true
		end

		local success = (not item.usetime or noAnim or lib.progressBar({
			duration = item.usetime,
			label = item.label or locale('using', data.metadata.label or data.label),
			useWhileDead = item.useWhileDead,
			canCancel = item.cancel,
			disable = item.disable,
			anim = item.anim or item.scenario,
			prop = item.prop --[[@as ProgressProps]]
		})) and not PlayerData.dead

		if success then
			if item.notification then
				lib.notify({ description = item.notification })
			end

			if item.status then
				if client.setPlayerStatus then
					client.setPlayerStatus(item.status)
				end
			end

			return true
		end
	end
end)

local function canUseItem(isAmmo)
	local ped = cache.ped

	return not usingItem
		and (not isAmmo or currentWeapon)
		and PlayerData.loaded
		and not PlayerData.dead
		and not invBusy
		and not lib.progressActive()
		and not IsPedRagdoll(ped)
		and not IsPedFalling(ped)
		and not IsPedShooting(playerPed)
end

local function getMagazineByAmmo(ammoType)
	return MagazineData[ammoType]
end

local function getMagazineByItem(itemName)
	return MagazineItems[itemName]
end

local function getMagazineRounds(slotData, config)
	if not slotData then return 0 end

	local metadata = slotData.metadata or {}
	local capacity = metadata.capacity or config?.capacity or 0
	local rounds = metadata.ammo or metadata.rounds or 0

	if rounds > capacity then
		rounds = capacity
	end

	return rounds
end

local function getAmmoSpecialType(slotData)
	return slotData?.metadata?.type
end

local function findCompatibleMagazineSlot(ammoType, specialAmmo, requireRounds)
	local magazine = getMagazineByAmmo(ammoType)

	if not magazine then return end

	local exactSlot
	local exactRounds = -1
	local fallbackSlot
	local fallbackRounds = -1
	local partialSlot
	local emptySlot

	for i = 1, #PlayerData.inventory do
		local slotData = PlayerData.inventory[i]

		if slotData and slotData.name == magazine.name then
			local metadata = slotData.metadata or {}
			local rounds = getMagazineRounds(slotData, magazine)
			local capacity = metadata.capacity or magazine.capacity
			local loadedSpecial = metadata.specialAmmo

			if requireRounds then
				if rounds > 0 then
					if specialAmmo and loadedSpecial == specialAmmo and rounds > exactRounds then
						exactSlot = i
						exactRounds = rounds
					elseif (not specialAmmo or not loadedSpecial) and rounds > fallbackRounds then
						fallbackSlot = i
						fallbackRounds = rounds
					end
				end
			elseif rounds < capacity then
				if specialAmmo and loadedSpecial == specialAmmo then
					exactSlot = exactSlot or i
				elseif rounds > 0 and not loadedSpecial then
					partialSlot = partialSlot or i
				elseif rounds == 0 then
					emptySlot = emptySlot or i
				end
			end
		end
	end

	if requireRounds then
		return exactSlot or fallbackSlot
	end

	return exactSlot or partialSlot or emptySlot
end

local function findCompatibleAmmoSlotForMagazine(magazineSlot)
	local slotData = PlayerData.inventory[magazineSlot]

	if not slotData then return end

	local magazineData = getMagazineByItem(slotData.name)

	if not magazineData then return end

	local metadata = slotData.metadata or {}
	local rounds = getMagazineRounds(slotData, magazineData)
	local loadedSpecial = metadata.specialAmmo

	for i = 1, #PlayerData.inventory do
		local ammoSlot = PlayerData.inventory[i]

		if ammoSlot and ammoSlot.name == magazineData.ammoType and (ammoSlot.count or 0) > 0 then
			local ammoSpecial = getAmmoSpecialType(ammoSlot)

			if rounds == 0 or ammoSpecial == loadedSpecial then
				return i
			end
		end
	end
end

local function getMagazineFillDetails(ammoSlot, magazineSlot, requestedAmount)
	local ammoSlotData = PlayerData.inventory[ammoSlot]
	local magazineSlotData = PlayerData.inventory[magazineSlot]

	if not ammoSlotData or not magazineSlotData then return nil, 'Invalid ammo or magazine slot.' end

	local ammoData = Items[ammoSlotData.name]
	local magazineData = getMagazineByItem(magazineSlotData.name)

	if not ammoData?.ammo or not magazineData then return nil, 'This ammo cannot be loaded into that item.' end
	if magazineData.ammoType ~= ammoSlotData.name then return nil, 'This ammo does not fit that magazine.' end

	local currentRounds = getMagazineRounds(magazineSlotData, magazineData)
	local capacity = magazineSlotData.metadata?.capacity or magazineData.capacity or 0
	local remaining = capacity - currentRounds

	if remaining < 1 then
		return nil, 'That magazine is already full.'
	end

	local ammoSpecial = getAmmoSpecialType(ammoSlotData)
	local loadedSpecial = magazineSlotData.metadata?.specialAmmo

	if currentRounds > 0 and loadedSpecial ~= ammoSpecial then
		return nil, 'This ammo does not match the rounds already loaded.'
	end

	local amount = math.min(requestedAmount or ammoSlotData.count or 0, ammoSlotData.count or 0, remaining)

	if amount < 1 then
		return nil, 'There is not enough ammo to load.'
	end

	return {
		amount = amount,
		ammoSpecial = ammoSpecial,
		magazineLabel = magazineSlotData.metadata?.label or ammoSlotData.metadata?.label or magazineSlotData.label or ammoSlotData.label,
	}
end

local function loadAmmoIntoMagazine(ammoSlot, magazineSlot, requestedAmount)
	local fillData, err = getMagazineFillDetails(ammoSlot, magazineSlot, requestedAmount)

	if not fillData then
		if err then
			lib.notify({ type = 'error', description = err })
		end

		return false
	end

	local success = lib.progressBar({
		duration = fillData.amount * 500,
		label = ('Loading %s'):format(fillData.magazineLabel or 'magazine'),
		useWhileDead = false,
		canCancel = true,
		disable = {
			sprint = true,
			car = true,
			combat = true,
		},
		anim = {
			dict = 'anim@heists@narcotics@trash',
			clip = 'idle',
			flag = 49,
		}
	})

	if not success then return false end

	return lib.callback.await('ox_inventory:fillMagazine', false, ammoSlot, magazineSlot, fillData.amount, fillData.ammoSpecial) and true or false
end

local function loadMagazineIntoWeapon(magazineSlot, weapon)
	local magazineItem = PlayerData.inventory[magazineSlot]

	if not magazineItem or not weapon then return false end

	local success = lib.progressBar({
		duration = 2000,
		label = ('Loading %s'):format(magazineItem.metadata?.label or magazineItem.label or 'magazine'),
		useWhileDead = false,
		canCancel = true,
		disable = {
			sprint = true,
			car = true,
			combat = true,
		},
		anim = {
			dict = 'anim@amb@nightclub@mini@drinking@drinking_shots@ped_a@normal',
			clip = 'pickup',
			flag = 49,
		}
	})

	if not success then return false end

	return lib.callback.await('ox_inventory:loadMagazine', false, magazineSlot, weapon.slot)
end

local function updateLoadedMagazineRounds(weapon, rounds)
	if weapon?.metadata?.loadedMagazine then
		weapon.metadata.loadedMagazine.ammo = rounds
		weapon.metadata.loadedMagazine.rounds = rounds
		weapon.metadata.loadedMagazine.specialAmmo = weapon.metadata.specialAmmo
	end
end

local function applyWeaponSpecialAmmo(weapon, specialAmmo)
	local weaponData = Items[weapon.name]

	if not weaponData?.model then
		weapon.metadata.specialAmmo = specialAmmo
		return
	end

	local clipComponentKey = ('%s_CLIP'):format(weaponData.model:gsub('WEAPON_', 'COMPONENT_'))
	local previousSpecial = weapon.metadata.specialAmmo

	if previousSpecial and previousSpecial ~= specialAmmo then
		local oldClip = ('%s_%s'):format(clipComponentKey, previousSpecial:upper())

		if HasPedGotWeaponComponent(playerPed, weapon.hash, oldClip) then
			RemoveWeaponComponentFromPed(playerPed, weapon.hash, oldClip)
		end
	end

	if specialAmmo then
		local specialClip = ('%s_%s'):format(clipComponentKey, specialAmmo:upper())

		if DoesWeaponTakeWeaponComponent(weapon.hash, specialClip) and not HasPedGotWeaponComponent(playerPed, weapon.hash, specialClip) then
			GiveWeaponComponentToPed(playerPed, weapon.hash, specialClip)
		end
	end

	weapon.metadata.specialAmmo = specialAmmo
end

local AmmoPoolTemplate = {
	pistol = { clip = 0, reserve = 0, maxReserve = 250 },
	rifle = { clip = 0, reserve = 0, maxReserve = 350 },
	shotgun = { clip = 0, reserve = 0, maxReserve = 125 },
	smg = { clip = 0, reserve = 0, maxReserve = 350 },
	sniper = { clip = 0, reserve = 0, maxReserve = 150 },
}

local function sanitiseAmmoPools(pools)
	local data = {}

	for key, defaults in pairs(AmmoPoolTemplate) do
		local state = pools and pools[key] or defaults
		local maxReserve = math.max(0, tonumber(state?.maxReserve) or tonumber(defaults?.maxReserve) or 0)
		data[key] = {
			clip = math.max(0, tonumber(state?.clip) or 0),
			reserve = math.min(math.max(0, tonumber(state?.reserve) or 0), maxReserve),
			maxReserve = maxReserve,
		}
	end

	return data
end

local function getWeaponAmmoPoolKey(weapon)
	local weaponHash = weapon?.hash or weapon?.name and joaat(weapon.name)

	if not weaponHash or weaponHash == `WEAPON_UNARMED` then return end

	local weaponGroup = GetWeapontypeGroup(weaponHash)

	if weaponGroup == `GROUP_PISTOL` or weaponGroup == `GROUP_STUNGUN` then
		return 'pistol'
	elseif weaponGroup == `GROUP_SMG` then
		return 'smg'
	elseif weaponGroup == `GROUP_SHOTGUN` then
		return 'shotgun'
	elseif weaponGroup == `GROUP_SNIPER` then
		return 'sniper'
	elseif weaponGroup == `GROUP_RIFLE` or weaponGroup == `GROUP_MG` then
		return 'rifle'
	end
end

local function getWeaponAmmoPoolState(weapon)
	local key = getWeaponAmmoPoolKey(weapon)
	local pools = PlayerData?.ammoPools

	if not key then return end

	pools = sanitiseAmmoPools(pools)
	PlayerData.ammoPools = pools

	return key, pools[key]
end

local function getWeaponHash(weapon)
	if type(weapon) == 'number' then
		return weapon
	elseif type(weapon) == 'string' then
		return joaat(weapon)
	elseif type(weapon) == 'table' then
		return weapon.hash or (weapon.name and joaat(weapon.name)) or (weapon.weapon and joaat(weapon.weapon))
	end
end

local function getAmmoReserveData(weapon)
	local targetWeapon = weapon or currentWeapon

	if type(targetWeapon) == 'number' then
		targetWeapon = { hash = targetWeapon }
	elseif type(targetWeapon) == 'string' then
		targetWeapon = { name = targetWeapon }
	end

	local poolKey, ammoState = getWeaponAmmoPoolState(targetWeapon)

	if not poolKey or not ammoState then
		return nil
	end

	local clip = ammoState.clip or 0
	local reserve = ammoState.reserve or 0
	local targetHash = getWeaponHash(targetWeapon)
	local currentHash = currentWeapon?.hash or GetSelectedPedWeapon(playerPed)

	-- Keep reserve cache-first. Ammo boxes update PlayerData.ammoPools before the
	-- ped ammo natives necessarily reflect the new reserve value.
	-- For the currently equipped weapon we only refresh the live clip count here.
	if targetHash and currentHash == targetHash then
		local _, clipAmmo = GetAmmoInClip(playerPed, targetHash)
		clip = clipAmmo or 0
	end

	return {
		pool = poolKey,
		clip = clip,
		reserve = reserve,
		maxReserve = ammoState.maxReserve or 0,
		total = clip + reserve,
	}
end

exports('getAmmoReserveData', getAmmoReserveData)

exports('getAmmoReserve', function(weapon)
	local data = getAmmoReserveData(weapon)
	return data and data.reserve or 0
end)

local function setCurrentWeaponAmmoFromPool(weapon, ammoState)
	if not weapon?.metadata or not ammoState then return end

	local clipAmmo = tonumber(ammoState.clip) or tonumber(weapon.metadata.ammo) or 0
	local reserveAmmo = math.max(0, tonumber(ammoState.reserve) or 0)

	if currentWeapon and currentWeapon.hash == weapon.hash then
		local _, liveClipAmmo = GetAmmoInClip(playerPed, weapon.hash)
		clipAmmo = liveClipAmmo or clipAmmo
	end

	clipAmmo = math.max(0, tonumber(clipAmmo) or 0)

	weapon.metadata.ammo = clipAmmo
	weapon.metadata.loadedMagazine = nil
	weapon.metadata.specialAmmo = nil
	weapon.metadata.reserve = reserveAmmo
	weapon.metadata.maxReserve = ammoState.maxReserve

	SetPedAmmo(playerPed, weapon.hash, clipAmmo + reserveAmmo)
	SetAmmoInClip(playerPed, weapon.hash, clipAmmo)

	if shared.ammodebug then
		local pedTotalAmmo = GetAmmoInPedWeapon(playerPed, weapon.hash) or 0
		local _, pedClipAmmo = GetAmmoInClip(playerPed, weapon.hash)
		print(('[ox_inventory DEBUG] setCurrentWeaponAmmoFromPool | weapon: %s | clip: %s | reserve: %s | pedClip: %s | pedTotal: %s'):format(
			tostring(weapon.hash),
			tostring(clipAmmo),
			tostring(reserveAmmo),
			tostring(pedClipAmmo or 0),
			tostring(pedTotalAmmo)
		))
	end
end

local function syncCurrentWeaponReserveFromPoolCache(weapon)
	if not weapon?.metadata then return end

	local _, ammoState = getWeaponAmmoPoolState(weapon)

	if not ammoState then
		return
	end

	local clipAmmo = ammoState.clip or weapon.metadata.ammo or 0

	if currentWeapon and currentWeapon.hash == weapon.hash then
		local _, liveClipAmmo = GetAmmoInClip(playerPed, weapon.hash)
		clipAmmo = liveClipAmmo or clipAmmo
	end

	weapon.metadata.ammo = clipAmmo
	weapon.metadata.reserve = ammoState.reserve or 0
	weapon.metadata.maxReserve = ammoState.maxReserve or 0

	return ammoState
end

local function calculateReserveFromPoolDelta(previousClip, previousReserve, currentClip)
	previousClip = math.max(0, tonumber(previousClip) or 0)
	previousReserve = math.max(0, tonumber(previousReserve) or 0)
	currentClip = math.max(0, tonumber(currentClip) or 0)

	if currentClip > previousClip then
		return math.max(0, previousReserve - (currentClip - previousClip))
	end

	return previousReserve
end

local function applyClipChangeToAmmoPool(weapon, previousClip, previousReserve, currentClip)
	if not weapon?.metadata then return end

	local poolKey, ammoState = getWeaponAmmoPoolState(weapon)

	if not poolKey or not ammoState then return end

	previousClip = math.max(0, tonumber(previousClip) or 0)
	previousReserve = math.max(0, tonumber(previousReserve) or 0)
	currentClip = math.max(0, tonumber(currentClip) or 0)

	local updatedReserve = calculateReserveFromPoolDelta(previousClip, previousReserve, currentClip)
	ammoState.clip = currentClip
	ammoState.reserve = math.min(ammoState.maxReserve, math.max(0, updatedReserve))

	weapon.metadata.ammo = currentClip
	weapon.metadata.reserve = ammoState.reserve
	weapon.metadata.loadedMagazine = nil
	weapon.metadata.specialAmmo = nil

	TriggerServerEvent('ox_inventory:updateWeapon', 'ammo', currentClip)
	TriggerServerEvent('ox_inventory:updateAmmoPool', poolKey, currentClip, ammoState.reserve, weapon.slot)

	return ammoState
end

local pendingReloadSync = {
	active = false,
	weaponHash = nil,
	startClip = 0,
	startReserve = 0,
	expiresAt = 0,
	requestedAt = 0,
}

local function clearPendingReloadSync()
	pendingReloadSync.active = false
	pendingReloadSync.weaponHash = nil
	pendingReloadSync.startClip = 0
	pendingReloadSync.startReserve = 0
	pendingReloadSync.expiresAt = 0
	pendingReloadSync.requestedAt = 0
end

local function beginPendingReloadSync(weapon, ammoState)
	if not weapon?.hash then return end

	local _, liveClip = GetAmmoInClip(playerPed, weapon.hash)
	liveClip = math.max(0, tonumber(liveClip) or 0)

	pendingReloadSync.active = true
	pendingReloadSync.weaponHash = weapon.hash
	pendingReloadSync.startClip = liveClip
	pendingReloadSync.startReserve = tonumber(ammoState and ammoState.reserve) or tonumber(weapon.metadata?.reserve) or 0
	pendingReloadSync.expiresAt = GetGameTimer() + 4000
	pendingReloadSync.requestedAt = GetGameTimer()

	weapon.metadata.ammo = liveClip
end

local function completePendingReloadSync(weapon, currentClip)
	if not pendingReloadSync.active or not weapon?.hash or weapon.hash ~= pendingReloadSync.weaponHash then
		return nil
	end

	local ammoState = applyClipChangeToAmmoPool(weapon, pendingReloadSync.startClip, pendingReloadSync.startReserve, currentClip)
	clearPendingReloadSync()
	return ammoState
end

CreateThread(function()
	while true do
		Wait(25)

		if pendingReloadSync.active then
			if not currentWeapon or currentWeapon.hash ~= pendingReloadSync.weaponHash or GetGameTimer() > pendingReloadSync.expiresAt then
				clearPendingReloadSync()
			else
				local _, currentClip = GetAmmoInClip(playerPed, currentWeapon.hash)
				currentClip = currentClip or 0

				if currentClip > pendingReloadSync.startClip then
					local previousClip = pendingReloadSync.startClip
					local ammoState = completePendingReloadSync(currentWeapon, currentClip)

					if shared.ammodebug then
						print(('[ox_inventory DEBUG] reload sync applied | weapon: %s | clip: %s -> %s | reserve: %s'):format(
							tostring(currentWeapon.hash),
							tostring(previousClip),
							tostring(currentClip),
							tostring(ammoState and ammoState.reserve or currentWeapon.metadata?.reserve or 0)
						))
					end
				end
			end
		else
			Wait(100)
		end
	end
end)

local function syncCurrentWeaponAmmoPool(force)
	if not currentWeapon?.ammo or not currentWeapon?.metadata then return end

	local poolKey, ammoState = getWeaponAmmoPoolState(currentWeapon)

	if not poolKey or not ammoState then return end

	local _, clipAmmo = GetAmmoInClip(playerPed, currentWeapon.hash)
	local previousClip = tonumber(ammoState.clip) or tonumber(currentWeapon.metadata.ammo) or 0
	local previousReserve = tonumber(ammoState.reserve) or tonumber(currentWeapon.metadata.reserve) or 0
	local reserveAmmo = calculateReserveFromPoolDelta(previousClip, previousReserve, clipAmmo)

	if not force and ammoState.clip == clipAmmo and ammoState.reserve == reserveAmmo then
		return
	end

	ammoState.clip = clipAmmo
	ammoState.reserve = math.min(ammoState.maxReserve, math.max(0, reserveAmmo))
	currentWeapon.metadata.ammo = clipAmmo
	currentWeapon.metadata.reserve = ammoState.reserve
	currentWeapon.metadata.loadedMagazine = nil
	currentWeapon.metadata.specialAmmo = nil

	TriggerServerEvent('ox_inventory:updateWeapon', 'ammo', clipAmmo)
	TriggerServerEvent('ox_inventory:updateAmmoPool', poolKey, clipAmmo, ammoState.reserve, currentWeapon.slot)
end

client.syncCurrentWeaponAmmoPool = syncCurrentWeaponAmmoPool

local function ammoDebug(...)
	if not shared.ammodebug then return end

	local parts = table.pack(...)
	for i = 1, parts.n do
		parts[i] = tostring(parts[i])
	end

	lib.print.info('[ammo-debug]', table.unpack(parts, 1, parts.n))
end

-- forward declarations for cross-calls
local useItem
local useSlot

local function addAmmoReserveFromItem(item, data, noAnim)
	if not canUseItem(false) then return end

	local ammoPools = sanitiseAmmoPools(PlayerData.ammoPools)
	local ammoState = ammoPools[data.ammoPool]
	ammoDebug('attempting ammo reserve use', item.name, 'slot', item.slot, 'pool', data.ammoPool, 'amount', data.ammoAmount,
		'currentState', json.encode(ammoState))

	if ammoState and ammoState.reserve >= ammoState.maxReserve then
		return lib.notify({ type = 'error', description = ('Your %s reserve is already full.'):format(data.ammoPool) })
	end

	local useData = {
		name = item.name,
		label = item.label,
		slot = item.slot,
		close = data.close,
		consume = data.consume,
		weapon = data.weapon,
		stack = data.stack,
		client = data.client,
		server = data.server,
	}

	useItem(useData, function(result)
		ammoDebug('useItem callback for ammo reserve item', item.name, 'result', result and 'success' or 'failed')
		if not result then return end
	end, noAnim, true)
end

RegisterNetEvent('ox_inventory:updateAmmoReservePool', function(poolKey, ammoState, amount)
	if not poolKey or not ammoState then return end

	PlayerData.ammoPools = sanitiseAmmoPools(PlayerData.ammoPools)
	PlayerData.ammoPools[poolKey] = ammoState
	ammoDebug('received ammo reserve update from server', 'pool', poolKey, 'amount', amount, 'state', json.encode(ammoState))

	if shared.ammodebug then
		print(('[ox_inventory DEBUG] updateAmmoReservePool | pool: %s | amount: %s | clip: %s | reserve: %s'):format(
			tostring(poolKey),
			tostring(amount or 0),
			tostring(ammoState.clip or 0),
			tostring(ammoState.reserve or 0)
		))
	end

	lib.notify({
		type = 'success',
		description = ('Added %s reserve ammo to %s.'):format(math.groupdigits(amount or 0), poolKey)
	})

	if currentWeapon and getWeaponAmmoPoolKey(currentWeapon) == poolKey then
		setCurrentWeaponAmmoFromPool(currentWeapon, ammoState)

		if shared.ammodebug then
			local _, clipAmmo = GetAmmoInClip(playerPed, currentWeapon.hash)
			local totalAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash) or 0
			print(('[ox_inventory DEBUG] synced current weapon from ammo pool | weapon: %s | clip: %s | reserve: %s | pedTotalAmmo: %s'):format(
				tostring(currentWeapon.hash),
				tostring(clipAmmo or 0),
				tostring(ammoState.reserve or 0),
				tostring(totalAmmo)
			))
		end
	end
end)

---@param data table
---@param cb fun(response: SlotWithItem | false)?
---@param noAnim? boolean
---@param fromUseSlot? boolean
function useItem(data, cb, noAnim, fromUseSlot)
	local inventoryId = data.inventory
	local slotData

	if not canUseItem(data.ammo and true) then
		if currentWeapon then
			return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
		end

		return
	end

	if inventoryId and inventoryId ~= 'player' then
		if data.slotData and type(data.slotData) == 'table' and data.slotData.slot then
			slotData = data.slotData
		else
			local inv = lib.callback.await('ox_inventory:getInventory', 200, inventoryId)

			if not inv or not inv.items then
				return
			end

			for _, it in pairs(inv.items) do
				if it and it.slot == (data.slot or data.item and data.item.slot) then
					slotData = {
						slot = it.slot,
						name = it.name,
						count = it.count,
						weight = it.weight,
						metadata = it
							.metadata or {}
					}
					break
				end
			end

			if not slotData then
				for _, it in pairs(inv.items) do
					if it and it.name == (data.item and data.item.name) and it.count == (data.item and data.item.count) then
						slotData = {
							slot = it.slot,
							name = it.name,
							count = it.count,
							weight = it.weight,
							metadata = it
								.metadata or {}
						}
						break
					end
				end
			end

			if not slotData then return end
		end
	else
		slotData = PlayerData.inventory[data.slot]
	end

	if not slotData then return end

	slotData.metadata = slotData.metadata or {}

	if not fromUseSlot then
		local itemData = Items[slotData.name]
		local isPlayerInventory = not inventoryId
			or inventoryId == 'player'
			or inventoryId == PlayerData.id
			or inventoryId == PlayerData.source

		if isPlayerInventory and (itemData?.weapon or slotData.metadata?.container or itemData?.component) then
			return useSlot(slotData.slot, noAnim)
		end
	end

	if currentWeapon and currentWeapon.timer ~= 0 then
		if not currentWeapon.timer or currentWeapon.timer - GetGameTimer() > 100 then return end

		DisablePlayerFiring(cache.playerId, true)
	end

	if invOpen and data.close then client.closeInventory() end

	usingItem = true
	---@type boolean?
	result = lib.callback.await('ox_inventory:useItem', 200, data.name, data.slot, slotData.metadata, noAnim, inventoryId)

	if result and cb then
		local success, response = pcall(cb, result and slotData)

		if not success and response then
			warn(('^1An error occurred while calling item "%s" callback!\n^1SCRIPT ERROR: %s^0'):format(slotData.name,
				response))
		end
	end

	if result then
		TriggerEvent('ox_inventory:usedItem', slotData.name, slotData.slot, next(slotData.metadata) and slotData
			.metadata, inventoryId)
	end

	Wait(500)
	usingItem = false
end

AddEventHandler('ox_inventory:usedItem', function(name, slot, metadata, inventoryId)
	TriggerServerEvent('ox_inventory:usedItemInternal', slot, inventoryId)
end)

AddEventHandler('ox_inventory:item', useItem)
exports('useItem', useItem)

---@param slot number
---@return boolean?
function useSlot(slot, noAnim)
	local item = PlayerData.inventory[slot]
	if not item then return end

	local data = Items[item.name]
	if not data then return end

	if data.ammoPool and data.ammoAmount then
		return addAmmoReserveFromItem(item, data, noAnim)
	end

	if data.ammo then
		if not canUseItem(false) then return end
		return lib.notify({
			type = 'error',
			description = 'Loose ammo can no longer be loaded directly. Use an ammo box to add reserve ammo.'
		})
	end

	if canUseItem(data.ammo and true) then
		if data.component and not currentWeapon then
			return lib.notify({ id = 'weapon_hand_required', type = 'error', description = locale('weapon_hand_required') })
		end

		local durability = item.metadata.durability --[[@as number?]]
		local consume = data.consume --[[@as number?]]
		local label = item.metadata.label or item.label --[[@as string]]

		-- Naive durability check to get an early exit
		-- People often don't call the 'useItem' export and then complain about "broken" items being usable
		-- This won't work with degradation since we need access to os.time on the server
		if durability and durability <= 100 and consume then
			if durability <= 0 then
				return lib.notify({ type = 'error', description = locale('no_durability', label) })
			elseif consume ~= 0 and consume < 1 and durability < consume * 100 then
				return lib.notify({ type = 'error', description = locale('not_enough_durability', label) })
			end
		end

		data.slot = slot

		if data.weapon then
			if EnableWeaponWheel or not plyState.canUseWeapons then return end

			if IsCinematicCamRendering() then SetCinematicModeActive(false) end

			if currentWeapon then
				if not currentWeapon.timer or currentWeapon.timer ~= 0 then return end

				local weaponSlot = currentWeapon.slot
				currentWeapon = Weapon.Disarm(currentWeapon)

				if weaponSlot == data.slot then return end
			end

			GiveWeaponToPed(playerPed, data.hash, 0, false, true)
			SetCurrentPedWeapon(playerPed, data.hash, false)

			if data.hash ~= GetSelectedPedWeapon(playerPed) then
				lib.print.info(('failed to equip %s (cause unknown)'):format(item.name))
				return lib.notify({ type = 'error', description = locale('cannot_use', data.label) })
			end

			RemoveWeaponFromPed(cache.ped, data.hash)

			return useItem(data, function(result)
				if result then
					if invOpen then client.closeInventory() end -- close inventory once weapon is equipped
					local sleep
					currentWeapon, sleep = Weapon.Equip(item, data, noAnim)
					local _, ammoState = getWeaponAmmoPoolState(currentWeapon)

					if ammoState then
						setCurrentWeaponAmmoFromPool(currentWeapon, ammoState)
					end

					if sleep then Wait(sleep) end
				end
			end, noAnim, true)
		elseif item.metadata.container then
			return client.openInventory('container', item.slot)
		elseif data.client then
			if invOpen and data.close then client.closeInventory() end

			if data.export then
				return data.export(data, { name = item.name, slot = item.slot, metadata = item.metadata })
			elseif data.client.event then -- re-add it, so I don't need to deal with morons taking screenshots of errors when using trigger event
				return TriggerEvent(data.client.event, data,
					{ name = item.name, slot = item.slot, metadata = item.metadata })
			end
		end

		if data.effect then
			data:effect({ name = item.name, slot = item.slot, metadata = item.metadata })
		elseif currentWeapon then
			if data.ammo then
				return lib.notify({
					type = 'error',
					description = 'Loose ammo can no longer be loaded directly. Use an ammo box to add reserve ammo.'
				})
			elseif data.magazine then
				return lib.notify({ type = 'error', description = 'Magazines are disabled while the ammo pool system is active.' })
			elseif data.component then
				local components = data.client.component

				if not components then return end

				local componentType = data.type
				local weaponComponents = PlayerData.inventory[currentWeapon.slot].metadata.components

				-- Checks if the weapon already has the same component type attached
				for componentIndex = 1, #weaponComponents do
					if componentType == Items[weaponComponents[componentIndex]].type then
						return lib.notify({
							id = 'component_slot_occupied',
							type = 'error',
							description = locale(
								'component_slot_occupied', componentType)
						})
					end
				end

				for i = 1, #components do
					local component = components[i]

					if DoesWeaponTakeWeaponComponent(currentWeapon.hash, component) then
						if HasPedGotWeaponComponent(playerPed, currentWeapon.hash, component) then
							lib.notify({
								id = 'component_has',
								type = 'error',
								description = locale('component_has',
									label)
							})
						else
							useItem(data, function(data)
								if data then
									local success = lib.callback.await('ox_inventory:updateWeapon', false, 'component',
										tostring(data.slot), currentWeapon.slot)

									if success then
										GiveWeaponComponentToPed(playerPed, currentWeapon.hash, component)
										TriggerEvent('ox_inventory:updateWeaponComponent', 'added', component, data.name)
									end
								end
							end, nil, true)
						end
						return
					end
				end
				lib.notify({ id = 'component_invalid', type = 'error', description = locale('component_invalid', label) })
			elseif data.allowArmed then
				useItem(data, nil, nil, true)
			else
				print("THIS")
				return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
			end
		elseif not data.ammo and not data.component and not data.magazine then
			useItem(data, nil, nil, true)
		end
	end
end

exports('useSlot', useSlot)

---@param id number
---@param slot number
local function useButton(id, slot)
	if PlayerData.loaded and not invBusy and not lib.progressActive() then
		local item = PlayerData.inventory[slot]
		if not item then return end

		local data = Items[item.name]
		local buttons = data?.buttons

		if buttons and buttons[id]?.action then
			buttons[id].action(slot)
		end
	end
end

local function openNearbyInventory() client.openInventory('player') end

exports('openNearbyInventory', openNearbyInventory)

local function refreshInventoryDisplay()
	SendNUIMessage({
		action = 'setupInventory',
		data = {
			leftInventory = {
				id = cache.serverId,
				type = 'player',
				slots = shared.playerslots,
				maxWeight = shared.playerweight,
				weight = PlayerData.weight,
				items = PlayerData.inventory,
				groups = PlayerData.groups,
				backpack = playerBackpack,
				utility = Utility.enabled and applyDynamicUtilityConfig(Utility.collect(PlayerData.inventory)) or nil,
				utilityConfig = Utility.enabled and {
					quickSlotLabels = buildUtilityHotkeyLabels(),
					tabHotkeys = buildInventoryTabHotkeys(),
				} or nil,
			},
			rightInventory = currentInventory
		}
	})
end

local function toggleWeaponMagazinePanel(slot)
	return lib.notify({ type = 'error', description = 'Magazine inventory has been removed. Weapons now use ammo pools only.' })
end

RegisterNetEvent('ox_inventory:openWeaponMagazineButton', function(slot)
	lib.notify({ type = 'error', description = 'Magazine inventory has been removed. Weapons now use ammo pools only.' })
end)

local currentInstance
local playerCoords
local Shops = require 'modules.shops.client'

---@todo remove or replace when the bridge module gets restructured
function OnPlayerData(key, val)
	if key ~= 'groups' and key ~= 'ped' and key ~= 'dead' then return end

	if key == 'groups' then
		Inventory.Stashes()
		Inventory.Evidence()
		Shops.refreshShops()
	elseif key == 'dead' and val then
		currentWeapon = Weapon.Disarm(currentWeapon)
		client.closeInventory()
	end

	Utils.WeaponWheel()
end

-- People consistently ignore errors when one of the "modules" failed to load
if not Utils or not Weapon or not Items or not Inventory then return end

local invHotkeys = false
local utilityHotbarSlots = Utility.config.hotbarSlots or { 1, 2, 3, 4, 5 }
local utilityHotkeys = Utility.config.hotkeys or {}
local utilitySlotKeybinds = {}
local inventoryTabPrevKeybind
local inventoryTabNextKeybind

getKeybindLabel = function(keybind, fallback)
	local key = keybind and keybind.currentKey or fallback or ''

	if type(key) ~= 'string' or key == '' then
		return fallback or ''
	end

	key = key:gsub('^t_', ''):gsub('^b_', '')
	return key:upper()
end

buildUtilityHotkeyLabels = function()
	local hotkeys = {}

	for i = 1, #utilityHotbarSlots do
		hotkeys[i] = getKeybindLabel(utilitySlotKeybinds[i], tostring(i))
	end

	return hotkeys
end

buildInventoryTabHotkeys = function()
	return {
		inventory = getKeybindLabel(inventoryTabPrevKeybind, 'Q'),
		utility = getKeybindLabel(inventoryTabNextKeybind, 'E'),
	}
end

applyDynamicUtilityConfig = function(state)
	if not state or not state.config then return state end

	state.config.quickSlotLabels = buildUtilityHotkeyLabels()
	state.config.tabHotkeys = buildInventoryTabHotkeys()

	return state
end

local function getUtilityInventorySlotByIndex(index)
	local utilitySlot = utilityHotbarSlots[index]

	if type(utilitySlot) ~= 'number' or not Utility.getReservedSlot then
		return nil, utilitySlot
	end

	return Utility.getReservedSlot(utilitySlot), utilitySlot
end

local function buildHotbarPayload()
	local items = {}
	local hotkeys = {}
	local inventory = PlayerData and PlayerData.inventory or {}
	local currentHotkeys = buildUtilityHotkeyLabels()

	for i = 1, #utilityHotbarSlots do
		local reservedSlot = getUtilityInventorySlotByIndex(i)
		local slotData = reservedSlot and inventory[reservedSlot]

		items[i] = slotData and slotData.name and slotData or { slot = reservedSlot or i }
		hotkeys[i] = currentHotkeys[i] or tostring(i)
	end

	return {
		open = true,
		items = items,
		hotkeys = hotkeys,
	}
end

local function cycleInventoryTab(direction)
	if not invOpen then return end

	SendNUIMessage({
		action = 'cycleInventoryTab',
		data = {
			direction = direction,
		}
	})
end

---@type function?
local function registerCommands()
	RegisterCommand('steal', openNearbyInventory, false)

	local function openGlovebox(vehicle)
		if not IsPedInAnyVehicle(playerPed, false) or not NetworkGetEntityIsNetworked(vehicle) then return end

		local vehicleHash = GetEntityModel(vehicle)
		local vehicleClass = GetVehicleClass(vehicle)
		local checkVehicle = Vehicles.Storage[vehicleHash]

		-- No storage or no glovebox
		if (checkVehicle == 0 or checkVehicle == 2) or (not Vehicles.glovebox[vehicleClass] and not Vehicles.glovebox.models[vehicleHash]) then return end

		local isOpen = client.openInventory('glovebox', { netid = NetworkGetNetworkIdFromEntity(vehicle) })

		if isOpen then
			currentInventory.entity = vehicle
		end
	end

	local primary = lib.addKeybind({
		name = 'inv',
		description = locale('open_player_inventory'),
		defaultKey = client.keys[1],
		onPressed = function()
			if invOpen then
				return client.closeInventory()
			end

			if cache.vehicle then
				return openGlovebox(cache.vehicle)
			end

			local closest = lib.points.getClosestPoint()

			if closest and closest.currentDistance < 1.2 and (not closest.instance or closest.instance == currentInstance) then
				if closest.inv == 'crafting' then
					return client.openInventory('crafting', { id = closest.id, index = closest.index })
				elseif closest.inv ~= 'license' and closest.inv ~= 'policeevidence' then
					return client.openInventory(closest.inv or 'drop', { id = closest.invId, type = closest.type })
				end
			end

			return client.openInventory()
		end
	})

	lib.addKeybind({
		name = 'inv2',
		description = locale('open_secondary_inventory'),
		defaultKey = client.keys[2],
		onPressed = function(self)
			if primary:getCurrentKey() == self:getCurrentKey() then
				return warn(("secondary inventory keybind '%s' disabled (keybind cannot match primary inventory keybind)")
					:format(self:getCurrentKey()))
			end

			if invOpen then return end

			if invBusy or not canOpenInventory() then
				return lib.notify({
					id = 'inventory_player_access',
					type = 'error',
					description = locale(
						'inventory_player_access')
				})
			end

			if StashTarget then
				return client.openInventory('stash', StashTarget)
			end

			if cache.vehicle then
				return openGlovebox(cache.vehicle)
			end

			local entity, entityType = Utils.Raycast(2|16)

			if not entity then return end

			if not shared.target and entityType == 3 then
				local model = GetEntityModel(entity)

				if Inventory.Dumpsters:includes(model) then
					return Inventory.OpenDumpster(entity)
				end
			end

			if entityType ~= 2 then return end

			Inventory.OpenTrunk(entity)
		end
	})

	lib.addKeybind({
		name = 'reloadweapon',
		description = locale('reload_weapon'),
		defaultKey = 'r',
		onPressed = function(self)
			if not currentWeapon or EnableWeaponWheel or not canUseItem(true) then return end

			if currentWeapon.ammo then
				if currentWeapon.metadata.durability > 0 then
					if currentWeapon.timer and currentWeapon.timer > GetGameTimer() then
						if shared.debug then
							print(('[ox_inventory DEBUG] reload blocked during post-shot timer | weapon: %s | timerRemaining: %s'):format(
								tostring(currentWeapon.hash),
								tostring(currentWeapon.timer - GetGameTimer())
							))
						end

						return
					end

					local ammoState = syncCurrentWeaponReserveFromPoolCache(currentWeapon)
					local reserveAmmo = ammoState and (ammoState.reserve or 0) or (currentWeapon.metadata.reserve or 0)
					local pedTotalAmmoBeforeReload = GetAmmoInPedWeapon(playerPed, currentWeapon.hash) or 0

					if reserveAmmo <= 0 then
						return lib.notify({
							id = 'no_ammo',
							type = 'error',
							description = locale('no_ammo')
						})
					end

					setCurrentWeaponAmmoFromPool(currentWeapon, ammoState)
					local pedTotalAmmoAfterPoolSync = GetAmmoInPedWeapon(playerPed, currentWeapon.hash) or 0

					if shared.ammodebug then
						print(('[ox_inventory DEBUG] reload requested from ammo pool | weapon: %s | clip: %s | reserve: %s | pedTotalBefore: %s | pedTotalAfter: %s'):format(
							tostring(currentWeapon.hash),
							tostring(ammoState.clip or currentWeapon.metadata.ammo or 0),
							tostring(ammoState.reserve or 0),
							tostring(pedTotalAmmoBeforeReload),
							tostring(pedTotalAmmoAfterPoolSync)
						))
					end

					beginPendingReloadSync(currentWeapon, ammoState)
					MakePedReload(playerPed)
				else
					lib.notify({
						id = 'no_durability',
						type = 'error',
						description = locale('no_durability',
							currentWeapon.label)
					})
				end
			end
		end
	})

	lib.addKeybind({
		name = 'hotbar',
		description = locale('disable_hotbar'),
		defaultKey = client.keys[3],
		onPressed = function()
			if EnableWeaponWheel or IsNuiFocused() or lib.progressActive() then return end
			SendNUIMessage({ action = 'toggleHotbar', data = buildHotbarPayload() })
		end
	})

	inventoryTabPrevKeybind = lib.addKeybind({
		name = 'inventorytabprev',
		description = locale('prev_inventory_tab'),
		defaultKey = 'q',
		onPressed = function()
			if lib.progressActive() then return end
			cycleInventoryTab(-1)
		end
	})

	inventoryTabNextKeybind = lib.addKeybind({
		name = 'inventorytabnext',
		description = locale('next_inventory_tab'),
		defaultKey = 'e',
		onPressed = function()
			if lib.progressActive() then return end
			cycleInventoryTab(1)
		end
	})

	for i = 1, 5 do
		local _, utilitySlot = getUtilityInventorySlotByIndex(i)

		utilitySlotKeybinds[i] = lib.addKeybind({
			name = ('hotkey%s'):format(i),
			description = locale('use_quickslot', i),
			defaultKey = utilityHotkeys[utilitySlot] or tostring(i),
			onPressed = function()
				if invOpen or EnableWeaponWheel or not invHotkeys or IsNuiFocused() then return end

				local reservedSlot = getUtilityInventorySlotByIndex(i)

				if reservedSlot then
					useSlot(reservedSlot)
				end
			end
		})
	end

	registerCommands = nil
end

function client.closeInventory(server)
	-- because somehow people are triggering this when the inventory isn't loaded
	-- and they're incapable of debugging, and I can't repro on a fresh install
	if not client.interval then return end

	if invOpen then
		invOpen = nil
		SetNuiFocus(false, false)
		SetNuiFocusKeepInput(false)
		TriggerScreenblurFadeOut(0)
		closeTrunk()
		SendNUIMessage({ action = 'closeInventory' })
		SetInterval(client.interval, 200)
		Wait(200)

		if invOpen ~= nil then return end

		if not server and currentInventory then
			TriggerServerEvent('ox_inventory:closeInventory')
		end

		currentInventory = nil
		plyState.invOpen = false
		defaultInventory.coords = nil
	end
end

RegisterNetEvent('ox_inventory:closeInventory', client.closeInventory)
exports('closeInventory', client.closeInventory)

---@param data updateSlot[]
---@param weight number
local function updateInventory(data, weight)
	local changes = {}
	---@type table<string, number>
	local itemCount = {}
	local playerUtilityChanged = false

	for i = 1, #data do
		local v = data[i]

		if not v.inventory or v.inventory == cache.serverId then
			v.inventory = 'player'
			local item = v.item

			if currentWeapon?.slot == item?.slot then
				if item.count and item.metadata and item.name == currentWeapon.name then
					currentWeapon.metadata = item.metadata
					TriggerEvent('ox_inventory:currentWeapon', currentWeapon)
				else
					currentWeapon = Weapon.Disarm(currentWeapon, true)
				end
			end

			local curItem = PlayerData.inventory[item.slot]

			if curItem and curItem.name then
				itemCount[curItem.name] = (itemCount[curItem.name] or 0) - curItem.count
			end

			if item.count then
				itemCount[item.name] = (itemCount[item.name] or 0) + item.count
			end

			changes[item.slot] = item.count and item or false
			if not item.count then item.name = nil end
			PlayerData.inventory[item.slot] = item.name and item or nil

			if Utility.enabled then
				local utilitySlot = Utility.getUtilitySlot(item.metadata, item.slot)

				if (utilitySlot and utilitySlot >= 1) or (Utility.slotOffset > 0 and item.slot and item.slot >= Utility.slotOffset) then
					playerUtilityChanged = true
				end
			end
		end
	end

	local payload = {
		items = data,
		itemCount = itemCount
	}

	if Utility.enabled and playerUtilityChanged then
		payload.leftUtility = applyDynamicUtilityConfig(Utility.collect(PlayerData.inventory))
		Utility.refreshArmorFromInventory(PlayerData.inventory)
		Utility.refreshBackpackFromInventory(PlayerData.inventory)
		Utility.refreshParachuteFromInventory(PlayerData.inventory)
	end

	-- Recalculate when base weight changes or any utility slot changed (backpack, armour, phone, weapons, parachute, etc.)
	local shouldUpdateWeight = (weight ~= PlayerData.weight) or (Utility.enabled and playerUtilityChanged)

	if shouldUpdateWeight then
		applyUtilityWeight(weight, PlayerData.inventory)
		payload.weight = {
			inventoryId = 'player',
			weight = PlayerData.weight,
		}
	end

	SendNUIMessage({ action = 'refreshSlots', data = payload })

	for itemName, count in pairs(itemCount) do
		local item = Items(itemName)

		if item then
			item.count += count

			TriggerEvent('ox_inventory:itemCount', item.name, item.count)

			if count < 0 then
				if shared.framework == 'esx' then
					TriggerEvent('esx:removeInventoryItem', item.name, item.count)
				end

				if item.client?.remove then
					item.client.remove(item.count)
				end
			elseif count > 0 then
				if shared.framework == 'esx' then
					TriggerEvent('esx:addInventoryItem', item.name, item.count)
				end

				if item.client?.add then
					item.client.add(item.count)
				end
			end
		end
	end

	client.setPlayerData('inventory', PlayerData.inventory)
	TriggerEvent('ox_inventory:updateInventory', changes)
end

RegisterNetEvent('ox_inventory:updateSlots', function(items, weights)
	if source ~= '' and next(items) then updateInventory(items, weights) end
end)

RegisterNetEvent('ox_inventory:inventoryReturned', function(data)
	if source == '' then return end
	if currentWeapon then currentWeapon = Weapon.Disarm(currentWeapon) end

	lib.notify({ description = locale('items_returned') })
	client.closeInventory()

	local num, items = 0, {}

	for _, slotData in pairs(data[1]) do
		num += 1
		items[num] = { item = slotData, inventory = cache.serverId }
	end

	updateInventory(items, data[3])
end)

RegisterNetEvent('ox_inventory:inventoryConfiscated', function(message)
	if source == '' then return end
	if message then lib.notify({ description = locale('items_confiscated') }) end
	if currentWeapon then currentWeapon = Weapon.Disarm(currentWeapon) end

	client.closeInventory()

	local num, items = 0, {}

	for slot in pairs(PlayerData.inventory) do
		num += 1
		items[num] = { item = { slot = slot }, inventory = cache.serverId }
	end

	updateInventory(items, 0)
end)


---@param point CPoint
local function nearbyDrop(point)
	if not point.instance or point.instance == currentInstance then
		---@diagnostic disable-next-line: param-type-mismatch
		-- DrawMarker(2, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 150, 30, 30, 222, false, false, 0, true, false, false, false)
	end
end

---@param point CPoint
local function onEnterDrop(point)
	print("ONENTERDROP FUNCTIOn")
	if point.instance and point.instance ~= currentInstance then return end

	point.entities = point.entities or {}

	-- Spawn per-item props when provided, otherwise fall back to a single drop model
	if point.itemProps and next(point.itemProps) then
		for i = 1, #point.itemProps do
			local entry = point.itemProps[i]
			local uid = entry.uniqueId or
				('%s_%s_%s'):format(point.invId or 'drop', entry.itemName or 'item', entry.slot or i)

			local entity = point.entities[uid]

			if not entity or not DoesEntityExist(entity) then
				local model = entry.modelp or point.model or client.dropmodel

				-- Prevent breaking inventory on invalid models; fall back to default drop model
				if not IsModelValid(model) and not IsModelInCdimage(model) then
					model = client.dropmodel
				end

				lib.requestModel(model)
				local coords = entry.coords or point.coords
				entity = CreateObject(model, coords.x, coords.y, coords.z, true, true, true)
				SetEntityAsMissionEntity(entity, true, true)
				placeDropEntity(entity, coords, true)
				addDropTarget(entity, point.invId)

				point.entities[uid] = entity
			end
		end
	elseif not point.entity then
		local model = point.model or client.dropmodel

		-- Prevent breaking inventory on invalid point.model instead use default client.dropmodel
		if not IsModelValid(model) and not IsModelInCdimage(model) then
			model = client.dropmodel
		end
		lib.requestModel(model)

		local entity = CreateObject(model, point.coords.x, point.coords.y, point.coords.z, false, true, true)

		SetModelAsNoLongerNeeded(model)

		placeDropEntity(entity, point.coords, true)
		addDropTarget(entity, point.invId)

		point.entity = entity
	end
end

local function onExitDrop(point)
	-- Clean up per-item props
	if point.entities then
		for uid, entity in pairs(point.entities) do
			if entity and DoesEntityExist(entity) then
				Utils.DeleteEntity(entity)
			end

			point.entities[uid] = nil
		end
	end

	if point.entity then
		Utils.DeleteEntity(point.entity)
		point.entity = nil
	end
end

local function createDrop(dropId, data)
	throwDebug('createDrop', 'dropId', dropId, 'coords', data and data.coords and json.encode(data.coords) or 'nil',
		'instance', data and data.instance or 'nil', 'model', data and (data.model or data.modelp) or 'nil',
		'hasPropObjects', data and data.hasPropObjects and 'true' or 'false')

	local point = lib.points.new({
		coords = data.coords,
		distance = 16,
		invId = dropId,
		instance = data.instance,
		model = data.model or data.modelp
	})

	point.itemProps = data.itemProps
	point.hasPropObjects = data.hasPropObjects or (point.itemProps and next(point.itemProps) ~= nil) or false

	if point.itemProps and next(point.itemProps) then
		point.distance = 30
		point.onEnter = onEnterDrop
		point.onExit = onExitDrop
	elseif point.model then
		point.distance = 30
		point.onEnter = onEnterDrop
		point.onExit = onExitDrop
	elseif client.dropprops and not point.hasPropObjects then
		point.distance = 30
		point.onEnter = onEnterDrop
		point.onExit = onExitDrop
	else
		if client.dropprops then
			point.distance = 30
		end

		point.nearby = nearbyDrop
	end

	point.entities = point.entities or {}
	client.drops[dropId] = point
end

RegisterNetEvent('ox_inventory:updateDropProps', function(dropId, itemProps)
	local point = client.drops and client.drops[dropId]
	if not point then return end

	point.itemProps = itemProps or {}
	point.hasPropObjects = next(point.itemProps) ~= nil
	point.entities = point.entities or {}

	local valid = {}
	for i = 1, #point.itemProps do
		local entry = point.itemProps[i]
		if entry.uniqueId then
			valid[entry.uniqueId] = true
		end
	end

	for uid, ent in pairs(point.entities) do
		if not valid[uid] then
			if ent and DoesEntityExist(ent) then
				Utils.DeleteEntity(ent)
			end
			point.entities[uid] = nil
		end
	end

	-- If player is already nearby, spawn any new props immediately
	if point.currentDistance and point.currentDistance <= point.distance then
		onEnterDrop(point)
	end
end)

local function removeDropObject(uniqueId, netId)
	local record = uniqueId and dropObjects[uniqueId]
	local point

	if not record and netId then
		local uid = dropObjectsByNetId[netId]

		if uid then
			uniqueId = uid
			record = dropObjects[uid]
		end
	end

	if uniqueId then
		for dropId, p in pairs(client.drops or {}) do
			if p.entities and p.entities[uniqueId] then
				point = p
				break
			end
		end
	end

	if record and netId and record.netId and record.netId ~= netId then
		record = nil
	end

	if record then
		local entity = record.entity

		if not entity or not DoesEntityExist(entity) then
			local resolvedNetId = record.netId or netId
			entity = resolvedNetId and NetworkGetEntityFromNetworkId(resolvedNetId) or entity
		end

		if entity and DoesEntityExist(entity) then
			Utils.DeleteEntity(entity)
		end

		if record.netId then
			dropObjectsByNetId[record.netId] = nil
		end

		if uniqueId then
			dropObjects[uniqueId] = nil
		end

		if record.dropId then
			point = point or (client.drops and client.drops[record.dropId])

			if point and point.entities then
				point.entities[uniqueId] = nil

				if not next(point.entities) then
					point.hasPropObjects = false
				end
			end
		end
	else
		if netId then
			dropObjectsByNetId[netId] = nil
			local entity = NetworkGetEntityFromNetworkId(netId)

			if entity and DoesEntityExist(entity) then
				Utils.DeleteEntity(entity)
			end
		end

		if point and point.entities and uniqueId then
			local ent = point.entities[uniqueId]

			if ent and DoesEntityExist(ent) then
				Utils.DeleteEntity(ent)
			end

			point.entities[uniqueId] = nil
		end
	end

	-- Remove from cached itemProps so re-entering doesn't respawn removed items
	if point and point.itemProps and uniqueId then
		for i = #point.itemProps, 1, -1 do
			if point.itemProps[i].uniqueId == uniqueId then
				table.remove(point.itemProps, i)
				break
			end
		end

		if not point.entities or not next(point.entities) then
			point.hasPropObjects = false
		end
	end
end

local function spawnDropProp(dropId, uniqueId, model, coords)
	print("SpawnDropProp function called")
	if uniqueId and dropObjects[uniqueId] then
		removeDropObject(uniqueId)
	end

	if type(model) == 'string' then
		model = joaat(model)
	end

	if not model or model == 0 or (not IsModelValid(model) and not IsModelInCdimage(model)) then
		model = client.dropmodel
	end

	lib.requestModel(model)
	local entity = CreateObject(model, coords.x, coords.y, coords.z, true, true, false)

	if not DoesEntityExist(entity) then
		SetModelAsNoLongerNeeded(model)
		return
	end

	SetEntityHeading(entity, math.random(0, 359))
	SetModelAsNoLongerNeeded(model)
	placeDropEntity(entity, coords, true)

	local netId = NetworkGetNetworkIdFromEntity(entity)
	local record = {
		netId = netId,
		entity = entity,
		dropId = dropId
	}

	dropObjects[uniqueId] = record

	if netId and netId ~= 0 then
		dropObjectsByNetId[netId] = uniqueId
	end

	local point = client.drops and client.drops[dropId]

	if point then
		point.hasPropObjects = true
		point.entities = point.entities or {}

		if point.entity then
			Utils.DeleteEntity(point.entity)
			point.entity = nil
		end

		point.entities[uniqueId] = entity
	end

	return netId, entity
end

RegisterNetEvent('ox_inventory:createDrop', function(dropId, data, owner, slot)
	throwDebug('createDrop:event', 'dropId', dropId, 'owner', owner, 'slot', slot, 'coords',
		data and data.coords and json.encode(data.coords) or 'nil')

	if client.drops then
		createDrop(dropId, data)
	end

	if owner == cache.serverId then
		if currentWeapon?.slot == slot then
			currentWeapon = Weapon.Disarm(currentWeapon)
		end

		if invOpen and #(GetEntityCoords(playerPed) - data.coords) <= 1 then
			if not cache.vehicle then
				client.openInventory('drop', dropId)
			else
				SendNUIMessage({
					action = 'setupInventory',
					data = { rightInventory = currentInventory }
				})
			end
		end
	end
end)

RegisterNetEvent('ox_inventory:createDropProp', function(data)
	print("CreateDropProp event called")
	if not data or not data.coords then return end

	local uniqueId = data.uniqueId
	if not uniqueId then return end

	local dropId = data.dropId
	local netId, entity = spawnDropProp(dropId, uniqueId, data.modelp, data.coords)

	if entity then
		local finalCoords = GetEntityCoords(entity)
		TriggerServerEvent('ox_inventory:registerDropProp', uniqueId, netId or 0, finalCoords)
	end
end)

RegisterNetEvent('ox_inventory:updateDropProp', function(data)
	print("UpdateDropProp event called")
	if not data or not data.uniqueId or not data.netId or data.netId == 0 then return end

	local dropId = data.dropId
	local uniqueId = data.uniqueId
	local netId = data.netId
	local coords = data.coords

	local entity = NetworkGetEntityFromNetworkId(netId)

	if entity and DoesEntityExist(entity) then
		dropObjects[uniqueId] = {
			netId = netId,
			entity = entity,
			dropId = dropId
		}

		dropObjectsByNetId[netId] = uniqueId

		if coords then
			SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)
		end

		local point = client.drops and client.drops[dropId]

		if point then
			point.hasPropObjects = true
			point.entities = point.entities or {}
			point.entities[uniqueId] = entity
		end
	end
end)

RegisterNetEvent('ox_inventory:removeDrop', function(dropId)
	if client.drops then
		local point = client.drops[dropId]

		if point then
			if point.entities then
				for uniqueId in pairs(point.entities) do
					removeDropObject(uniqueId)
				end
			end

			client.drops[dropId] = nil
			point:remove()

			if point.entity then Utils.DeleteEntity(point.entity) end
		end
	end
end)

RegisterNetEvent('ox_inventory:removeDropProp', function(netId, uniqueId)
	removeDropObject(uniqueId, netId)
end)

---@type function?
local function setStateBagHandler(stateId)
	AddStateBagChangeHandler('invOpen', stateId, function(_, _, value)
		invOpen = value
	end)

	AddStateBagChangeHandler('invBusy', stateId, function(_, _, value)
		invBusy = value
	end)

	AddStateBagChangeHandler('canUseWeapons', stateId, function(_, _, value)
		if not value and currentWeapon then
			currentWeapon = Weapon.Disarm(currentWeapon)
		end
	end)

	AddStateBagChangeHandler('instance', stateId, function(_, _, value)
		currentInstance = value

		if client.drops then
			-- Iterate over known drops and remove any points in a different instance (ignoring no instance)
			for dropId, point in pairs(client.drops) do
				if point.instance then
					if point.instance ~= value then
						if point.entity then
							Utils.DeleteEntity(point.entity)
							point.entity = nil
						end

						point:remove()
					else
						-- Recreate the drop using data from the old point
						createDrop(dropId, point)
					end
				end
			end
		end
	end)

	AddStateBagChangeHandler('dead', stateId, function(_, _, value)
		Utils.WeaponWheel()
		PlayerData.dead = value
	end)

	AddStateBagChangeHandler('invHotkeys', stateId, function(_, _, value)
		invHotkeys = value
	end)

	setStateBagHandler = nil
end

lib.onCache('seat', function(seat)
	if seat then
		local hasWeapon = GetCurrentPedVehicleWeapon(cache.ped)

		if hasWeapon then
			return Utils.WeaponWheel(true)
		end
	end

	Utils.WeaponWheel(false)
end)

lib.onCache('vehicle', function()
	if invOpen and (not currentInventory.entity or currentInventory.entity == cache.vehicle) then
		return client.closeInventory()
	end
end)

RegisterNetEvent('ox_inventory:setPlayerInventory', function(currentDrops, inventory, weight, player)
	if source == '' then return end

	---@class PlayerData
	---@field inventory table<number, SlotWithItem?>
	---@field weight number
	---@field groups table<string, number>
	PlayerData = player
	PlayerData.id = cache.playerId
	PlayerData.source = cache.serverId
	PlayerData.maxWeight = shared.playerweight
	PlayerData.ammoPools = sanitiseAmmoPools(PlayerData.ammoPools)

	setmetatable(PlayerData, {
		__index = function(self, key)
			if key == 'ped' then
				return PlayerPedId()
			end
		end
	})

	if setStateBagHandler then setStateBagHandler(('player:%s'):format(cache.serverId)) end

	TriggerServerEvent('ox_inventory:crafting:refreshPermissions')

	local ItemData = table.create(0, #Items)

	for _, v in pairs(Items --[[@as table<string, OxClientItem>]]) do
		local buttons = v.buttons and {} or nil

		if buttons then
			for i = 1, #v.buttons do
				buttons[i] = { label = v.buttons[i].label, group = v.buttons[i].group }
			end
		end

		ItemData[v.name] = {
			label = v.label,
			stack = v.stack,
			close = v.close,
			count = 0,
			description = v.description,
			buttons = buttons,
			weapon = v.weapon,
			ammoName = v.ammoname,
			image = v.client?.image,
			rarity = v.rarity
		}
	end

	for _, data in pairs(inventory) do
		local item = Items[data.name]

		if item then
			item.count += data.count
			ItemData[data.name].count += data.count
			local add = item.client?.add

			if add then
				add(item.count)
			end
		end
	end

	local phone = Items.phone

	if phone and phone.count < 1 then
		pcall(function()
			return exports.npwd:setPhoneDisabled(true)
		end)
	end

	client.setPlayerData('inventory', inventory)
	applyUtilityWeight(weight, inventory)
	currentWeapon = nil
	Weapon.ClearAll()

	local locales = lib.getLocales()

	local uiLocales = {}

	for k, v in pairs(locales) do
		if type(v) == 'string' then
			uiLocales[k] = v
		end
	end

	uiLocales['$'] = locales['$']
	uiLocales.ammo_type = locales.ammo_type

	client.drops = currentDrops

	for dropId, data in pairs(currentDrops) do
		createDrop(dropId, data)
	end

	for dropId, data in pairs(currentDrops) do
		local props = data.itemProps

		if props then
			for i = 1, #props do
				local entry = props[i]
				local uniqueId = entry.uniqueId

				if uniqueId then
					local coords = entry.coords or data.coords
					local model = entry.modelp or data.modelp
					local netId = entry.netId
					local entity

					if netId and NetworkDoesNetworkIdExist(netId) then
						entity = NetworkGetEntityFromNetworkId(netId)
					end

					if entity and DoesEntityExist(entity) then
						dropObjects[uniqueId] = {
							netId = netId,
							entity = entity,
							dropId = dropId
						}

						if netId and netId ~= 0 then
							dropObjectsByNetId[netId] = uniqueId
						end

						local point = client.drops and client.drops[dropId]

						if point then
							point.hasPropObjects = true
							point.entities = point.entities or {}
							point.entities[uniqueId] = entity
						end
					else
						-- If we don't have a network id yet, wait for the host client to spawn the prop
						-- and receive ox_inventory:updateDropProp instead of spawning another copy locally.
					end
				end
			end
		end
	end

	local hasTextUi
	local uiOptions = { icon = 'fa-id-card' }

	---@param point CPoint
	local function nearbyLicense(point)
		---@diagnostic disable-next-line: param-type-mismatch
		-- DrawMarker(2, point.coords.x, point.coords.y, point.coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.2, 0.15, 30, 150, 30, 222, false, false, 0, true, false, false, false)

		if point.isClosest and point.currentDistance < 1.2 then
			if not hasTextUi then
				hasTextUi = point
				lib.showTextUI(point.message, uiOptions)
			end

			if IsControlJustReleased(0, 38) then
				lib.callback('ox_inventory:buyLicense', 1000, function(success, message)
					if success ~= nil then
						lib.notify({
							id = message,
							type = success == false and 'error' or 'success',
							description = locale(message, locale('license', point.type:gsub("^%l", string.upper)))
						})
					end
				end, point.invId)
			end
		elseif hasTextUi == point then
			hasTextUi = false
			lib.hideTextUI()
		end
	end

	for id, data in pairs(lib.load('data.licenses') or {}) do
		lib.points.new({
			coords = data.coords,
			distance = 16,
			inv = 'license',
			type = data.name,
			price = data.price,
			invId = id,
			nearby = nearbyLicense,
			message = ('**%s**  \n%s'):format(locale('purchase_license', data.name),
				locale('interact_prompt', GetControlInstructionalButton(0, 38, true):sub(3)))
		})
	end

	while not client.uiLoaded do Wait(50) end

	SendNUIMessage({
		action = 'init',
		data = {
			locale = uiLocales,
			items = ItemData,
			leftInventory = {
				id = cache.playerId,
				slots = shared.playerslots,
				items = PlayerData.inventory,
				maxWeight = shared.playerweight,
				weight = PlayerData.weight,
			},
			imagepath = client.imagepath,
			theme = Theme,
			rarity = Rarity
		}
	})

	PlayerData.loaded = true

	lib.notify({ description = locale('inventory_setup') })
	Shops.refreshShops()
	Inventory.Stashes()
	Inventory.Evidence()

	if registerCommands then registerCommands() end

	TriggerEvent('ox_inventory:updateInventory', PlayerData.inventory)

	TriggerEvent('ox_inventory:updateInventory', PlayerData.inventory)

	client.onLogin()

	client.interval = SetInterval(function()
		if invOpen == false then
			playerCoords = GetEntityCoords(playerPed)

			if currentWeapon and IsPedUsingActionMode(playerPed) then
				SetPedUsingActionMode(playerPed, false, -1, 'DEFAULT_ACTION')
			end
		elseif invOpen == true then
			if not canOpenInventory() then
				client.closeInventory()
			else
				playerCoords = GetEntityCoords(playerPed)

				if currentInventory and not currentInventory.ignoreSecurityChecks then
					local maxDistance = (currentInventory.distance or currentInventory.type == 'stash' and 4.8 or 1.8) +
						0.2

					if currentInventory.type == 'otherplayer' then
						local id = GetPlayerFromServerId(currentInventory.id)
						local ped = GetPlayerPed(id)
						local pedCoords = GetEntityCoords(ped)

						if not id or #(playerCoords - pedCoords) > maxDistance or not (client.hasGroup(shared.police) or canOpenTarget(ped)) then
							client.closeInventory()
							lib.notify({
								id = 'inventory_lost_access',
								type = 'error',
								description = locale(
									'inventory_lost_access')
							})
						else
							TaskTurnPedToFaceCoord(playerPed, pedCoords.x, pedCoords.y, pedCoords.z, 50)
						end
					elseif currentInventory.coords and (#(playerCoords - currentInventory.coords) > maxDistance or canOpenTarget(playerPed)) then
						client.closeInventory()
						lib.notify({
							id = 'inventory_lost_access',
							type = 'error',
							description = locale(
								'inventory_lost_access')
						})
					end
				end
			end
		end

		local parachuteState = GetPedParachuteState(playerPed)
		if client.parachute and parachuteState and parachuteState > 0 then
			if not (Utility and Utility.handleParachuteDeployment and Utility.handleParachuteDeployment()) then
				Utils.DeleteEntity(client.parachute[1])
				client.parachute = false
			end
		end

		if EnableWeaponWheel then return end

		local weaponHash = GetSelectedPedWeapon(playerPed)

		if currentWeapon then
			if currentWeapon.ammo then
				SetWeaponsNoAutoreload(true)
			end

			if weaponHash ~= currentWeapon.hash and currentWeapon.timer ~= nil then
				local weaponCount = Items[currentWeapon.name]?.count

				if weaponCount > 0 then
					SetCurrentPedWeapon(playerPed, currentWeapon.hash, true)
					SetPedAmmo(playerPed, currentWeapon.hash, (currentWeapon.metadata.ammo or 0) + (currentWeapon.metadata.reserve or 0))
					SetAmmoInClip(playerPed, currentWeapon.hash, currentWeapon.metadata.ammo or 0)
					SetPedCurrentWeaponVisible(playerPed, true, false, false, false)

					weaponHash = GetSelectedPedWeapon(playerPed)
				end

				if weaponHash ~= currentWeapon.hash then
					lib.print.info(('%s was forcibly unequipped (caused by game behaviour or another resource)'):format(
						currentWeapon.name))
					currentWeapon = Weapon.Disarm(currentWeapon, true)
				end
			end
		elseif client.weaponmismatch and not client.ignoreweapons[weaponHash] then
			local weaponType = GetWeapontypeGroup(weaponHash)

			if weaponType ~= 0 and weaponType ~= `GROUP_UNARMED` then
				Weapon.Disarm(currentWeapon, true)
			end
		end
	end, 200)

	local playerId = cache.playerId
	local EnableKeys = client.enablekeys
	local DisablePlayerVehicleRewards = DisablePlayerVehicleRewards
	local DisableAllControlActions = DisableAllControlActions
	local HideHudAndRadarThisFrame = HideHudAndRadarThisFrame
	local EnableControlAction = EnableControlAction
	local DisablePlayerFiring = DisablePlayerFiring
	local HudWeaponWheelIgnoreSelection = HudWeaponWheelIgnoreSelection
	local DisableControlAction = DisableControlAction
	local IsPedShooting = IsPedShooting
	local IsControlJustReleased = IsControlJustReleased

	client.tick = SetInterval(function()
		DisablePlayerVehicleRewards(playerId)

		if invOpen then
			DisableAllControlActions(0)
			HideHudAndRadarThisFrame()

			for i = 1, #EnableKeys do
				EnableControlAction(0, EnableKeys[i], true)
			end

			if currentInventory.type == 'newdrop' then
				EnableControlAction(0, 30, true)
				EnableControlAction(0, 31, true)
			end
		else
			if invBusy then
				DisableControlAction(0, 23, true)
				DisableControlAction(0, 36, true)
			end

			if usingItem or invOpen or IsPedCuffed(playerPed) then
				DisablePlayerFiring(playerId, true)
			end

			if not EnableWeaponWheel then
				HudWeaponWheelIgnoreSelection()
				DisableControlAction(0, 37, true)
			end

			if currentWeapon and currentWeapon.timer ~= nil and currentWeapon.timer ~= 0 then
				DisableControlAction(0, 80, true)
				DisableControlAction(0, 140, true)

				if currentWeapon.metadata.durability <= 0 then
					DisablePlayerFiring(playerId, true)
				elseif client.aimedfiring and not currentWeapon.melee and currentWeapon.group ~= `GROUP_PETROLCAN` and not IsPlayerFreeAiming(playerId) then
					DisablePlayerFiring(playerId, true)
				end

				local weaponAmmo = currentWeapon.metadata.ammo
				local ammoState = syncCurrentWeaponReserveFromPoolCache(currentWeapon)
				local weaponReserve = ammoState and (ammoState.reserve or 0) or (currentWeapon.metadata.reserve or 0)
				local weaponTotalAmmo = (weaponAmmo or 0) + weaponReserve

				if not invBusy and currentWeapon.timer ~= 0 and currentWeapon.timer < GetGameTimer() then
					currentWeapon.timer = 0

					if currentWeapon.ammo then
						syncCurrentWeaponAmmoPool(true)
					elseif currentWeapon.metadata.durability then
						TriggerServerEvent('ox_inventory:updateWeapon', 'melee', currentWeapon.melee)
						currentWeapon.melee = 0
					end
				elseif currentWeapon.ammo then
					if IsPedShooting(playerPed) then
						local currentAmmo
						local durabilityDrain = Items[currentWeapon.name].durability

						if currentWeapon.group == `GROUP_PETROLCAN` or currentWeapon.group == `GROUP_FIREEXTINGUISHER` then
							currentAmmo = weaponAmmo - durabilityDrain < 0 and 0 or weaponAmmo - durabilityDrain
							currentWeapon.metadata.durability = currentAmmo
							currentWeapon.metadata.ammo = (weaponAmmo < currentAmmo) and 0 or currentAmmo

							if currentAmmo <= 0 then
								SetPedInfiniteAmmo(playerPed, false, currentWeapon.hash)
							end
						else
							local _, currentClip = GetAmmoInClip(playerPed, currentWeapon.hash)
							local currentReserve = calculateReserveFromPoolDelta(weaponAmmo, weaponReserve, currentClip)
							currentAmmo = currentClip + currentReserve

							if currentAmmo < weaponTotalAmmo or currentClip ~= weaponAmmo or currentReserve ~= weaponReserve then
								currentWeapon.metadata.ammo = currentClip
								currentWeapon.metadata.reserve = currentReserve
								updateLoadedMagazineRounds(currentWeapon, currentClip)
								currentWeapon.metadata.durability = currentWeapon.metadata.durability -
									(durabilityDrain * math.abs((weaponTotalAmmo or 0.1) - currentAmmo))
							end
						end

						if currentAmmo <= 0 then
						if cache.vehicle then
							TaskSwapWeapon(playerPed, true)
						end

						currentWeapon.timer = GetGameTimer() + 200
					else
						currentWeapon.timer = GetGameTimer() + (GetWeaponTimeBetweenShots(currentWeapon.hash) * 1000) +
							100
					end
				else
						local _, currentClip = GetAmmoInClip(playerPed, currentWeapon.hash)
						currentClip = currentClip or 0
						local expectedTotalAmmo = (weaponAmmo or 0) + weaponReserve
						local pedTotalAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash) or 0

						if not IsPedReloading(playerPed) and pedTotalAmmo > expectedTotalAmmo and currentClip == (weaponAmmo or 0) then
							SetPedAmmo(playerPed, currentWeapon.hash, expectedTotalAmmo)

							if shared.ammodebug then
								print(('[ox_inventory DEBUG] ped ammo reserve trimmed to pool | weapon: %s | clip: %s | reserve: %s | pedTotalBefore: %s'):format(
									tostring(currentWeapon.hash),
									tostring(weaponAmmo or 0),
									tostring(weaponReserve),
									tostring(pedTotalAmmo)
								))
							end
						end

						if pendingReloadSync.active and GetGameTimer() > pendingReloadSync.expiresAt then
							clearPendingReloadSync()
						end

						if currentClip > (weaponAmmo or 0) then
							local previousClip = weaponAmmo or 0
							local isPendingReloadForWeapon = pendingReloadSync.active and pendingReloadSync.weaponHash == currentWeapon.hash
							local nativeReloading = IsPedReloading(playerPed)
							local reloadGraceWindow = pendingReloadSync.requestedAt > 0 and (GetGameTimer() - pendingReloadSync.requestedAt) <= 1500

							if isPendingReloadForWeapon or nativeReloading or reloadGraceWindow then
								local latestAmmoState = applyClipChangeToAmmoPool(currentWeapon, previousClip, weaponReserve, currentClip)

								if isPendingReloadForWeapon then
									clearPendingReloadSync()
								end

								if shared.ammodebug then
									print(('[ox_inventory DEBUG] fallback clip increase sync | weapon: %s | clip: %s -> %s | reserve: %s | pending: %s | nativeReloading: %s | grace: %s'):format(
										tostring(currentWeapon.hash),
										tostring(previousClip),
										tostring(currentClip),
										tostring(latestAmmoState and latestAmmoState.reserve or currentWeapon.metadata.reserve or 0),
										tostring(isPendingReloadForWeapon),
										tostring(nativeReloading),
										tostring(reloadGraceWindow)
									))
								end
							elseif shared.ammodebug then
								print(('[ox_inventory DEBUG] unexpected clip increase ignored | weapon: %s | clip: %s -> %s | reserve: %s | pedTotal: %s'):format(
									tostring(currentWeapon.hash),
									tostring(previousClip),
									tostring(currentClip),
									tostring(weaponReserve),
									tostring(pedTotalAmmo)
								))
							end
						end
					end
				elseif currentWeapon.throwable then
					if not invBusy and IsControlPressed(0, 24) then
						invBusy = 1

						CreateThread(function()
							local weapon = currentWeapon

							while currentWeapon and (not IsPedWeaponReadyToShoot(cache.ped) or IsDisabledControlPressed(0, 24)) and GetSelectedPedWeapon(playerPed) == weapon.hash do
								Wait(0)
							end

							if GetSelectedPedWeapon(playerPed) == weapon.hash then Wait(700) end

							while IsPedPlantingBomb(playerPed) do Wait(0) end

							TriggerServerEvent('ox_inventory:updateWeapon', 'throw', nil, weapon.slot)
							plyState:set('invBusy', false, true)

							currentWeapon = nil

							RemoveWeaponFromPed(playerPed, weapon.hash)
							TriggerEvent('ox_inventory:currentWeapon')
						end)
					end
				elseif currentWeapon.melee and IsControlJustReleased(0, 24) and IsPedPerformingMeleeAction(playerPed) then
					currentWeapon.melee += 1
					currentWeapon.timer = GetGameTimer() + 200
				end
			end
		end
	end)

	plyState:set('invBusy', false, true)
	plyState:set('invOpen', false, false)
	plyState:set('invHotkeys', true, false)
	plyState:set('canUseWeapons', true, false)
	collectgarbage('collect')
end)

AddEventHandler('onResourceStop', function(resourceName)
	if shared.resource == resourceName then
		if client.syncCurrentWeaponAmmoPool then
			client.syncCurrentWeaponAmmoPool(true)
		end

		client.onLogout()
	end
end)

RegisterNetEvent('ox_inventory:viewInventory', function(left, right)
	if source == '' then return end

	plyState.invOpen = true

	SetInterval(client.interval, 100)
	SetNuiFocus(true, true)
	SetNuiFocusKeepInput(true)
	closeTrunk()

	if client.screenblur then TriggerScreenblurFadeIn(0) end

	currentInventory = right or defaultInventory
	currentInventory.ignoreSecurityChecks = true
	currentInventory.type = 'inspect'
	left.items = PlayerData.inventory
	left.groups = PlayerData.groups
	left.weight = PlayerData.weight

	if Utility.enabled then
		left.utility = applyDynamicUtilityConfig(Utility.collect(PlayerData.inventory))
		left.utilityConfig = left.utility and left.utility.config or Utility.config

		if currentInventory and currentInventory.items then
			currentInventory.utility = applyDynamicUtilityConfig(Utility.collect(currentInventory.items))
		end
	end

	SendNUIMessage({
		action = 'setupInventory',
		data = {
			leftInventory = left,
			rightInventory = currentInventory
		}
	})
end)

RegisterNUICallback('uiLoaded', function(_, cb)
	client.uiLoaded = true
	cb(1)
end)

RegisterNUICallback('getItemData', function(itemName, cb)
	cb(Items[itemName])
end)

RegisterNUICallback('removeComponent', function(data, cb)
	cb(1)

	if not currentWeapon then
		return TriggerServerEvent('ox_inventory:updateWeapon', 'component', data)
	end

	if data.slot ~= currentWeapon.slot then
		return lib.notify({ id = 'weapon_hand_wrong', type = 'error', description = locale('weapon_hand_wrong') })
	end

	local itemSlot = PlayerData.inventory[currentWeapon.slot]

	if not itemSlot then return end

	for _, component in pairs(Items[data.component].client.component) do
		if HasPedGotWeaponComponent(playerPed, currentWeapon.hash, component) then
			for k, v in pairs(itemSlot.metadata.components) do
				if v == data.component then
					local success = lib.callback.await('ox_inventory:updateWeapon', false, 'component', k)

					if success then
						RemoveWeaponComponentFromPed(playerPed, currentWeapon.hash, component)
						TriggerEvent('ox_inventory:updateWeaponComponent', 'removed', component, data.component)
					end

					break
							end
						end

						syncCurrentWeaponAmmoPool()
					else
						syncCurrentWeaponAmmoPool()
					end
				end
end)

RegisterNUICallback('removeAmmo', function(slot, cb)
	cb(1)
	local slotData = PlayerData.inventory[slot]

	if not slotData or not slotData.metadata.ammo or slotData.metadata.ammo == 0 then return end

	local success = lib.callback.await('ox_inventory:removeAmmoFromWeapon', false, slot)

	if success and slot == currentWeapon?.slot then
		if type(success) == 'table' then
			local poolKey = getWeaponAmmoPoolKey(currentWeapon)

			if poolKey then
				PlayerData.ammoPools[poolKey] = success
			end

			setCurrentWeaponAmmoFromPool(currentWeapon, success)
			TriggerServerEvent('ox_inventory:updateAmmoPool', poolKey, success.clip, success.reserve, currentWeapon.slot)
		else
			SetPedAmmo(playerPed, currentWeapon.hash, 0)
		end
	end
end)

RegisterNUICallback('useItem', function(slot, cb)
	useSlot(slot --[[@as number]])
	cb(1)
end)

RegisterNUICallback('loadMagazineFromItem', function(data, cb)
	lib.notify({ type = 'error', description = 'Magazine loading is disabled while the ammo pool system is active.' })
	cb(false)
end)

RegisterNUICallback('openWeaponMagazine', function(data, cb)
	lib.notify({ type = 'error', description = 'Weapon magazine inventories are disabled while the ammo pool system is active.' })
	cb(false)
end)

giveItemToTarget = function(serverId, slotId, count, fromInv)
	if type(slotId) ~= 'number' then return TypeError('slotId', 'number', type(slotId)) end
	if count and type(count) ~= 'number' then return TypeError('count', 'number', type(count)) end

	if slotId == currentWeapon?.slot then
		currentWeapon = Weapon.Disarm(currentWeapon)
	end

	Utils.PlayAnim(0, 'mp_common', 'givetake1_a', 1.0, 1.0, 2000, 50, 0.0, 0, 0, 0)

	local notification = lib.callback.await('ox_inventory:giveItem', false, slotId, serverId, count or 0, fromInv)

	if notification then
		lib.notify({ type = 'error', description = locale(table.unpack(notification)) })
	else
		client.closeInventory()
	end
end

exports('giveItemToTarget', giveItemToTarget)

isGiveTargetValid = function(ped, coords)
	if cache.vehicle and GetVehiclePedIsIn(ped, false) == cache.vehicle then
		return true
	end

	local entity = Utils.Raycast(1|2|4|8|16, coords + vec3(0, 0, 0.5), 0.2)

	return entity == ped and IsEntityVisible(ped)
end

RegisterNUICallback('giveItem', function(data, cb)
	cb(1)
	local amount = data.count or 1


	if usingItem then return end
	local item = lib.callback.await('inv:getItemFromSlot', false, data.slot)
	if amount == 0 then
		amount = item.count or 1
	end
	local props = Items[item.name]

	local slotId = item.slot


	if slotId == currentWeapon?.slot then
		currentWeapon = Weapon.Disarm(currentWeapon)
	end

	local isWeapon = false
	if item and item.name then
		local weaponHash = joaat(item.name)
		if IsWeaponValid(weaponHash) then
			isWeapon = true
		elseif not item.name:find('^WEAPON_') and not item.name:find('^weapon_') then
			local altHash = joaat('WEAPON_' .. item.name:upper())
			if IsWeaponValid(altHash) then
				isWeapon = true
			end
		end
	end

	if (props and props.modelp and not props.disableThrow) or isWeapon then
		client.closeInventory()
		local placed, response = startItemThrowPreview(item, props, amount, item)

		if placed then
			if response then
				updateInventory(response.items, response.weight)
			end
		else
			plyState:set('invBusy', false, true)
		end

		return
	end



	if client.giveplayerlist then
		local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(playerPed), 3.0)
		local nearbyCount = #nearbyPlayers

		if nearbyCount == 0 then return end

		if nearbyCount == 1 then
			local option = nearbyPlayers[1]

			if not isGiveTargetValid(option.ped, option.coords) then return end

			-- Resolve item details (may include inventory id)
			local item = lib.callback.await('inv:getItemFromSlot', false, data.slot)
			return giveItemToTarget(GetPlayerServerId(option.id), item and item.slot or data.slot, data.count,
				item and item.inventory)
		end

		local giveList, n = {}, 0

		for i = 1, #nearbyPlayers do
			local option = nearbyPlayers[i]

			if isGiveTargetValid(option.ped, option.coords) then
				local playerName = GetPlayerName(option.id)
				option.id = GetPlayerServerId(option.id)
				---@diagnostic disable-next-line: inject-field
				option.label = ('[%s] %s'):format(option.id, playerName)
				n += 1
				giveList[n] = option
			end
		end

		if n == 0 then return end

		lib.registerMenu({
			id = 'ox_inventory:givePlayerList',
			title = 'Give item',
			options = giveList,
		}, function(selected)
			local item = lib.callback.await('inv:getItemFromSlot', false, data.slot)
			giveItemToTarget(giveList[selected].id, item and item.slot or data.slot, data.count, item and item.inventory)
		end)

		return lib.showMenu('ox_inventory:givePlayerList')
	end

	if cache.vehicle then
		local seats = GetVehicleMaxNumberOfPassengers(cache.vehicle) - 1

		if seats >= 0 then
			local passenger = GetPedInVehicleSeat(cache.vehicle, cache.seat - 2 * (cache.seat % 2) + 1)

			if passenger ~= 0 and IsEntityVisible(passenger) then
				local item = lib.callback.await('inv:getItemFromSlot', false, data.slot)
				return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(passenger)),
					item and item.slot or data.slot, data.count, item and item.inventory)
			end
		end

		return
	end

	local entity = Utils.Raycast(1|2|4|8|16, GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 3.0, 0.5), 0.2)

	if entity and IsPedAPlayer(entity) and IsEntityVisible(entity) and #(GetEntityCoords(playerPed, true) - GetEntityCoords(entity, true)) < 3.0 then
		local item = lib.callback.await('inv:getItemFromSlot', false, data.slot)
		return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)), item and item.slot or data.slot,
			data.count, item and item.inventory)
	end
end)

RegisterNUICallback('giveItemNearby', function(data, cb)
	cb(1)
	local amount = data.count or 1

	if usingItem then return end

	if client.giveplayerlist then
		local nearbyPlayers = lib.getNearbyPlayers(GetEntityCoords(playerPed), 3.0)
		local nearbyCount = #nearbyPlayers

		if nearbyCount == 0 then return end

		if nearbyCount == 1 then
			local option = nearbyPlayers[1]

			if not isGiveTargetValid(option.ped, option.coords) then return end

			-- Resolve item details (may include inventory id)
			local item = lib.callback.await('inv:getItemFromSlot', false, data.slot)
			return giveItemToTarget(GetPlayerServerId(option.id), item and item.slot or data.slot, data.count,
				item and item.inventory)
		end

		local giveList, n = {}, 0

		for i = 1, #nearbyPlayers do
			local option = nearbyPlayers[i]

			if isGiveTargetValid(option.ped, option.coords) then
				local playerName = GetPlayerName(option.id)
				option.id = GetPlayerServerId(option.id)
				---@diagnostic disable-next-line: inject-field
				option.label = ('[%s] %s'):format(option.id, playerName)
				n += 1
				giveList[n] = option
			end
		end

		if n == 0 then return end

		lib.registerMenu({
			id = 'ox_inventory:givePlayerList',
			title = 'Give item',
			options = giveList,
		}, function(selected)
			local item = lib.callback.await('inv:getItemFromSlot', false, data.slot)
			giveItemToTarget(giveList[selected].id, item and item.slot or data.slot, data.count, item and item.inventory)
		end)

		return lib.showMenu('ox_inventory:givePlayerList')
	end

	if cache.vehicle then
		local seats = GetVehicleMaxNumberOfPassengers(cache.vehicle) - 1

		if seats >= 0 then
			local passenger = GetPedInVehicleSeat(cache.vehicle, cache.seat - 2 * (cache.seat % 2) + 1)

			if passenger ~= 0 and IsEntityVisible(passenger) then
				local item = lib.callback.await('inv:getItemFromSlot', false, data.slot)
				return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(passenger)),
					item and item.slot or data.slot, data.count, item and item.inventory)
			end
		end

		return
	end

	local entity = Utils.Raycast(1|2|4|8|16, GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 3.0, 0.5), 0.2)

	if entity and IsPedAPlayer(entity) and IsEntityVisible(entity) and #(GetEntityCoords(playerPed, true) - GetEntityCoords(entity, true)) < 3.0 then
		local item = lib.callback.await('inv:getItemFromSlot', false, data.slot)
		return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)), item and item.slot or data.slot,
			data.count, item and item.inventory)
	end
end)

RegisterNUICallback('useButton', function(data, cb)
	useButton(data.id, data.slot)
	cb(1)
end)

RegisterNUICallback('exit', function(_, cb)
	client.closeInventory()
	cb(1)
end)

RegisterNetEvent('ox_inventory:crafting:updateXp', function(newXp)
	if currentInventory and currentInventory.type == 'crafting' then
		currentInventory.crafting = currentInventory.crafting or {}
		currentInventory.crafting.xp = currentInventory.crafting.xp or { enabled = true, current = 0 }
		currentInventory.crafting.xp.current = newXp

		SendNUIMessage({
			action = 'refreshSlots',
			data = {
				craftingXp = {
					xp = newXp
				}
			}
		})
	end
end)

lib.callback.register('ox_inventory:startCrafting', function(id, recipe)
	recipe = CraftingBenches[id].items[recipe]

	return lib.progressCircle({
		label = locale('crafting_item', recipe.metadata?.label or Items[recipe.name].label),
		duration = recipe.duration or 3000,
		canCancel = true,
		disable = {
			move = true,
			combat = true,
		},
		anim = {
			dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@',
			clip = 'machinic_loop_mechandplayer',
		}
	})
end)

local swapActive = false

---Synchronise and validate all item movement between the NUI and server.
RegisterNUICallback('swapItems', function(data, cb)
	if swapActive or not invOpen or invBusy or usingItem then return cb(false) end

	swapActive = true

	local fromSlotData = data.fromType == 'player' and PlayerData.inventory[data.fromSlot]
	local toSlotData = data.toType == 'player' and PlayerData.inventory[data.toSlot]
	local fromItem = fromSlotData and Items[fromSlotData.name]
	local toItem = toSlotData and Items[toSlotData.name]

	if data.fromType == 'player' and data.toType == 'player' and fromItem?.ammo and toItem?.magazine then
		swapActive = false
		return cb(loadAmmoIntoMagazine(data.fromSlot, data.toSlot, data.count) and true or false)
	end

	if data.toType == 'newdrop' then
		if cache.vehicle or IsPedFalling(playerPed) then
			swapActive = false
			return cb(false)
		end

		local coords = GetEntityCoords(playerPed)

		if IsEntityInWater(playerPed) then
			local destination = vec3(coords.x, coords.y, -200)
			local handle = StartShapeTestLosProbe(coords.x, coords.y, coords.z, destination.x, destination.y,
				destination.z, 511, cache.ped, 4)

			while true do
				Wait(0)
				local retval, hit, endCoords = GetShapeTestResult(handle)

				if retval ~= 1 then
					if not hit then return end

					data.coords = vec3(endCoords.x, endCoords.y, endCoords.z + 1.0)

					break
				end
			end
		else
			data.coords = coords
		end
	end

	if currentInstance then
		data.instance = currentInstance
	end

	if currentWeapon and data.fromType ~= data.toType then
		if (data.fromType == 'player' and data.fromSlot == currentWeapon.slot) or (data.toType == 'player' and data.toSlot == currentWeapon.slot) then
			currentWeapon = Weapon.Disarm(currentWeapon, true)
		end
	end

	local success, response, weaponSlot = lib.callback.await('ox_inventory:swapItems', false, data)
	swapActive = false

	cb(success or false)

	if success then
		if weaponSlot and currentWeapon then
			currentWeapon.slot = weaponSlot
		end

		if response then
			updateInventory(response.items, response.weight)
		end
	elseif response then
		if type(response) == 'table' then
			SendNUIMessage({ action = 'refreshSlots', data = { items = response } })
		else
			lib.notify({ type = 'error', description = locale(response) })
		end
	end
end)

RegisterNUICallback('moveToUtilitySlot', function(data, cb)
	local success, response = lib.callback.await('ox_inventory:utility:moveTo', false, data)

	if not success and response then
		lib.notify({ type = 'error', description = locale(response) or response })
	end

	cb(success and true or false)
end)

RegisterNUICallback('moveFromUtilitySlot', function(data, cb)
	local utilitySlot = tonumber(data and data.utilitySlot)

	if utilitySlot and Utility.getReservedSlot then
		local reservedSlot = Utility.getReservedSlot(utilitySlot)
		local slotData = reservedSlot and PlayerData and PlayerData.inventory and PlayerData.inventory[reservedSlot]

		if slotData and slotData.name == 'parachute' and GetPedParachuteState(playerPed) ~= -1 then
			lib.notify({ type = 'error', description = 'You cannot remove the parachute while parachuting' })
			cb(false)
			return
		end
	end

	local success, response = lib.callback.await('ox_inventory:utility:moveFrom', false, data)

	if not success and response then
		lib.notify({ type = 'error', description = locale(response) or response })
	end

	cb(success and true or false)
end)

RegisterNUICallback('contextMoveToPlayer', function(data, cb)
	if type(data) ~= 'table' or type(data.fromSlot) ~= 'number' or type(data.toSlot) ~= 'number' then
		cb({ success = false, error = 'invalid_data' })
		return
	end

	local success, response = lib.callback.await('ox_inventory:swapItems', false, data)

	if success == false then
		cb({ success = false, error = response })
	else
		cb({ success = true, slot = data.toSlot })
	end
end)

RegisterNUICallback('contextUseItem', function(data, cb)
	if type(data) ~= 'table' or type(data.slot) ~= 'number' or type(data.item) ~= 'table' or type(data.item.name) ~= 'string' then
		cb(false)
		return
	end

	local definition = Items[data.item.name]

	if not definition then
		cb(false)
		return
	end

	-- Normalize metadata (NUI may send an empty array instead of an object)
	local metadata = data.item.metadata or {}
	if type(metadata) == 'table' and next(metadata) == nil then
		metadata = {}
	end

	local slotData = nil

	-- If the inventory is not the player's, fetch that inventory and validate the slot/item
	if data.inventory and data.inventory ~= 'player' then
		local inv = lib.callback.await('ox_inventory:getInventory', 200, data.inventory)

		if not inv or not inv.items then
			cb(false)
			return
		end

		-- Try to find the item by slot (preferred) or by name/slot fallback
		for _, it in pairs(inv.items) do
			if it and it.slot == data.item.slot then
				slotData = {
					slot = it.slot,
					name = it.name,
					count = it.count,
					weight = it.weight,
					metadata = it
						.metadata or {}
				}
				break
			end
		end

		-- Fallback: attempt to match by name and count if slot lookup failed
		if not slotData then
			for _, it in pairs(inv.items) do
				if it and it.name == data.item.name and it.count == data.item.count then
					slotData = {
						slot = it.slot,
						name = it.name,
						count = it.count,
						weight = it.weight,
						metadata = it
							.metadata or {}
					}
					break
				end
			end
		end

		if not slotData then
			cb(false)
			return
		end
	else
		-- Player inventory: use PlayerData
		local p = PlayerData.inventory[data.slot]
		if p then
			slotData = { slot = p.slot, name = p.name, count = p.count, weight = p.weight, metadata = p.metadata or {} }
		else
			-- If PlayerData doesn't have it, still allow using provided item info
			slotData = {
				slot = data.item.slot,
				name = data.item.name,
				count = data.item.count,
				weight = data.item
					.weight,
				metadata = metadata
			}
		end
	end

	local itemData = {}
	for k, v in pairs(definition) do
		itemData[k] = v
	end

	local effectPayload = {
		name = slotData and slotData.name or data.item.name,
		slot = slotData and slotData.slot or data.item.slot or data.slot,
		metadata = slotData and slotData.metadata or metadata
	}

	itemData.slot = effectPayload.slot
	itemData.metadata = effectPayload.metadata
	itemData.inventory = data.inventory
	itemData.slotData = slotData

	if itemData.client then
		if invOpen and itemData.close then client.closeInventory() end

		if itemData.export then
			itemData.export(itemData, effectPayload)
			cb(true)
			return
		elseif itemData.client.event then
			TriggerEvent(itemData.client.event, itemData, effectPayload)
			cb(true)
			return
		end
	end

	if itemData.effect then
		itemData:effect(effectPayload)
	else
		useItem(itemData)
	end

	cb(true)
end)

RegisterNUICallback('benchPermissions:close', function(_, cb)
	SetNuiFocus(false, false)
	cb(true)
end)

local function sendBenchPermissionsResponse(cb, payload, err)
	if payload then
		cb({ success = true, data = payload })
	else
		cb({ success = false, error = err })
	end
end

RegisterNUICallback('benchPermissions:createRole', function(data, cb)
	local payload, err = lib.callback.await('ox_inventory:crafting:createRole', false, data)
	sendBenchPermissionsResponse(cb, payload, err)
end)

RegisterNUICallback('benchPermissions:updateRole', function(data, cb)
	local payload, err = lib.callback.await('ox_inventory:crafting:updateRole', false, data)
	sendBenchPermissionsResponse(cb, payload, err)
end)

RegisterNUICallback('benchPermissions:deleteRole', function(data, cb)
	local payload, err = lib.callback.await('ox_inventory:crafting:deleteRole', false, data)
	sendBenchPermissionsResponse(cb, payload, err)
end)

RegisterNUICallback('benchPermissions:setMemberRole', function(data, cb)
	local payload, err = lib.callback.await('ox_inventory:crafting:setMemberRole', false, data)
	sendBenchPermissionsResponse(cb, payload, err)
end)

RegisterNUICallback('benchPermissions:transferOwnership', function(data, cb)
	local payload, err = lib.callback.await('ox_inventory:crafting:transferOwnership', false, data)
	sendBenchPermissionsResponse(cb, payload, err)
end)
RegisterNUICallback('buyItem', function(data, cb)
	---@type boolean, false | { [1]: number, [2]: SlotWithItem, [3]: SlotWithItem | false, [4]: number}, NotifyProps
	local response, data, message = lib.callback.await('ox_inventory:buyItem', 100, data)

	if data then
		-- data[2] may be a single SlotWithItem or an array of SlotWithItem (when non-stackable items occupy multiple slots)
		local playerItems = {}

		if type(data[2]) == 'table' and data[2].slot then
			-- single slot
			playerItems[1] = { item = data[2], inventory = cache.serverId }
		elseif type(data[2]) == 'table' then
			-- multiple items
			local n = 0
			for i = 1, #data[2] do
				if data[2][i] then
					n = n + 1
					playerItems[n] = { item = data[2][i], inventory = cache.serverId }
				end
			end
		end

		if next(playerItems) then
			-- If server provided a weight at index 4, use it; otherwise keep current weight
			updateInventory(playerItems, data[4])
		end

		if data[3] then
			-- shop slot may be a single slot or false; wrap in array for refresh
			SendNUIMessage({
				action = 'refreshSlots',
				data = {
					items = {
						{
							item = data[3],
							inventory = 'shop'
						}
					}
				}
			})
		end
	end

	if message then
		lib.notify(message)
	end

	cb(response)
end)

RegisterNUICallback('craftItem', function(data, cb)
	cb(true)

	local id = data.benchId or currentInventory.id
	local index = data.benchIndex or currentInventory.index
	local recipeSlot = data.recipeSlot or data.fromSlot
	local toSlot = data.toSlot
	local storageId = data.storageId or (currentInventory.storage and currentInventory.storage.id)
	local count = data.count or 1

	if not id or not recipeSlot then return end

	local success, response = lib.callback.await('ox_inventory:craftItem', 200, id, index, recipeSlot, toSlot, storageId,
		count)

	if not success and response then
		lib.notify({ type = 'error', description = locale(response or 'cannot_perform') })
	end
end)

RegisterNUICallback('cancelCraft', function(data, cb)
	cb(1)
	lib.callback.await('ox_inventory:cancelCraft', 200, data.benchId, data.jobIndex)
end)


lib.callback.register('ox_inventory:getVehicleData', function(netid)
	local entity = NetworkGetEntityFromNetworkId(netid)

	if entity then
		return GetEntityModel(entity), GetVehicleClass(entity)
	end
end)

weaponModelFromName = function(name)
	local w = joaat(name)
	if IsWeaponValid(w) then
		local model = GetWeapontypeModel(w)
		return model
	end
	if not name:find('^WEAPON_') and not name:find('^weapon_') then
		local guess = 'WEAPON_' .. name:upper()
		local g = joaat(guess)
		if IsWeaponValid(g) then
			local model = GetWeapontypeModel(g)
			return model
		end
	end
	return nil
end


lib.callback.register('ox_inventory:resolveModelOnClient', function(itemNameOrProps)
	lib.print.debug('resolveModelOnClient called with:', itemNameOrProps)

	if type(itemNameOrProps) == 'string' then
		lib.print.debug('Processing string item name:', itemNameOrProps)
		local model = weaponModelFromName(itemNameOrProps)
		lib.print.debug('Weapon model result:', model)
		return model
	end

	if type(itemNameOrProps) == 'table' and itemNameOrProps.name then
		lib.print.debug('Processing table with name:', itemNameOrProps.name)
		local model = weaponModelFromName(tostring(itemNameOrProps.name))
		lib.print.debug('Weapon model result:', model)
		return model
	end

	if type(itemNameOrProps) == 'table' and (itemNameOrProps.modelp or itemNameOrProps.prop) then
		lib.print.debug('Processing table with modelp/prop')
		local m = itemNameOrProps.modelp or itemNameOrProps.prop
		lib.print.debug('Raw model value:', m)

		if type(m) == 'table' and m.modelp then
			lib.print.debug('Using nested modelp:', m.modelp)
			return joaat(m.modelp)
		end

		if m then
			lib.print.debug('Using direct model:', m)
			return joaat(m)
		end
	end

	lib.print.debug('No model resolved, returning nil')
	return nil
end)

RegisterNetEvent('ox_inventory:playGiveAnim', function()
	Utils.PlayAnim(0, 'mp_common', 'givetake1_a', 1.0, 1.0, 2000, 50, 0.0, 0, 0, 0)
end)
