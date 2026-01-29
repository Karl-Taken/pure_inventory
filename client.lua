if not lib then return end

require 'modules.bridge.client'
require 'modules.interface.client'

local Utils = require 'modules.utils.client'
local Weapon = require 'modules.weapon.client'
local Utility = require 'modules.utility.client'
local currentWeapon

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
	SendNUIMessage({
		action = 'setPlayerBackpack',
		data = backpack
	})
end)

local StashTarget

exports('setStashTarget', function(id, owner)
	StashTarget = id and {id=id, owner=owner}
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
		Utils.PlayAnimAdvanced(0, 'anim@heists@fleeca_bank@scope_out@return_case', 'trevor_action', coords.x, coords.y, coords.z, 0.0, 0.0, GetEntityHeading(playerPed), 2.0, 2.0, 1000, 49, 0.25)

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

---@param inv string?
---@param data any?
---@return boolean?
function client.openInventory(inv, data)
	if invOpen then
		if not inv and currentInventory.type == 'newdrop' then
			return client.closeInventory()
		end

		if IsNuiFocused() then
			if inv == 'container' and currentInventory.id == PlayerData.inventory[data].metadata.container then
				return client.closeInventory()
			end

			if currentInventory.type == 'drop' and (not data or currentInventory.id == (type(data) == 'table' and data.id or data)) then
				return client.closeInventory()
			end

			if inv ~= 'drop' and inv ~= 'container' then
				if (data?.id or data) == currentInventory?.id then
					-- Triggering exports.ox_inventory:openInventory('stash', 'mystash') twice in rapid succession is weird behaviour
					return warn(("script tried to open inventory, but it is already open\n%s"):format(Citizen.InvokeNative(`FORMAT_STACK_TRACE` & 0xFFFFFFFF, nil, 0, Citizen.ResultAsString())))
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
        return lib.notify({ id = 'inventory_player_access', type = 'error', description = locale('inventory_player_access') })
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
            return lib.notify({ id = 'inventory_right_access', type = 'error', description = locale('inventory_right_access') })
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

		lib.print.debug('[ox_inventory] Crafting bench callback result - left:', left and 'exists' or 'nil', 'right:', right and 'exists' or 'nil', 'accessError:', accessError)

		if left then
			lib.print.debug('[ox_inventory] Processing crafting bench data')
			
			local craftingInfo = left.crafting
			local storagePayload = left.storage
			
			lib.print.debug('[ox_inventory] Crafting info:', craftingInfo and 'exists' or 'nil', 'Storage payload:', storagePayload and 'exists' or 'nil')
			
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
			
			lib.print.debug('[ox_inventory] Created right inventory for crafting bench:', right.type, right.id, right.label)
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
            return lib.notify({ id = 'inventory_right_access', type = 'error', description = locale('inventory_right_access') })
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
		left.utility = Utility.collect(PlayerData.inventory)
		left.utilityConfig = Utility.config

		if currentInventory then
			if currentInventory.items and (currentInventory.type == 'player' or currentInventory.type == 'inspect') then
				currentInventory.utility = Utility.collect(currentInventory.items)
			else
				currentInventory.utility = nil
			end
		end
	end

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
            Utils.PlayAnim(0, 'anim@heists@prison_heiststation@cop_reactions', 'cop_b_idle', 3.0, 3.0, -1, 49, 0.0, 0, 0, 0)

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

	if Utility.enabled then
		left.utility = Utility.collect(PlayerData.inventory)
		left.utilityConfig = Utility.config

		if currentInventory and currentInventory.items then
			currentInventory.utility = Utility.collect(currentInventory.items)
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
local Items = require 'modules.items.client'
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

-- forward declarations for cross-calls
local useSlot

---@param data table
---@param cb fun(response: SlotWithItem | false)?
---@param noAnim? boolean
---@param fromUseSlot? boolean
local function useItem(data, cb, noAnim, fromUseSlot)
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
					slotData = { slot = it.slot, name = it.name, count = it.count, weight = it.weight, metadata = it.metadata or {} }
					break
				end
			end

			if not slotData then
				for _, it in pairs(inv.items) do
					if it and it.name == (data.item and data.item.name) and it.count == (data.item and data.item.count) then
						slotData = { slot = it.slot, name = it.name, count = it.count, weight = it.weight, metadata = it.metadata or {} }
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
			warn(('^1An error occurred while calling item "%s" callback!\n^1SCRIPT ERROR: %s^0'):format(slotData.name, response))
		end
	end

    if result then
        TriggerEvent('ox_inventory:usedItem', slotData.name, slotData.slot, next(slotData.metadata) and slotData.metadata, inventoryId)
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

		if item.metadata.container then
			return client.openInventory('container', item.slot)
		elseif data.client then
			if invOpen and data.close then client.closeInventory() end

			if data.export then
				return data.export(data, {name = item.name, slot = item.slot, metadata = item.metadata})
			elseif data.client.event then -- re-add it, so I don't need to deal with morons taking screenshots of errors when using trigger event
				return TriggerEvent(data.client.event, data, {name = item.name, slot = item.slot, metadata = item.metadata})
			end
		end

		if data.effect then
			data:effect({name = item.name, slot = item.slot, metadata = item.metadata})
		elseif data.weapon then
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

			useItem(data, function(result)
				if result then
					if invOpen then client.closeInventory() end -- close inventory once weapon is equipped
                    local sleep
					currentWeapon, sleep = Weapon.Equip(item, data, noAnim)

					if sleep then Wait(sleep) end
				end
			end, noAnim, true)
		elseif currentWeapon then
			if data.ammo then
				if EnableWeaponWheel or currentWeapon.metadata.durability <= 0 then return end

				local clipSize = GetMaxAmmoInClip(playerPed, currentWeapon.hash, true)
				local currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)
				local _, maxAmmo = GetMaxAmmo(playerPed, currentWeapon.hash)

				if maxAmmo < clipSize then clipSize = maxAmmo end

				if currentAmmo == clipSize then return end

				useItem(data, function(resp)
					if not resp or resp.name ~= currentWeapon?.ammo then return end

					if currentWeapon.metadata.specialAmmo ~= resp.metadata.type and type(currentWeapon.metadata.specialAmmo) == 'string' then
						local clipComponentKey = ('%s_CLIP'):format(Items[currentWeapon.name].model:gsub('WEAPON_', 'COMPONENT_'))
						local specialClip = ('%s_%s'):format(clipComponentKey, (resp.metadata.type or currentWeapon.metadata.specialAmmo):upper())

						if type(resp.metadata.type) == 'string' then
							if not HasPedGotWeaponComponent(playerPed, currentWeapon.hash, specialClip) then
								if not DoesWeaponTakeWeaponComponent(currentWeapon.hash, specialClip) then
									warn('cannot use clip with this weapon')
									return
								end

								local defaultClip = ('%s_01'):format(clipComponentKey)

								if not HasPedGotWeaponComponent(playerPed, currentWeapon.hash, defaultClip) then
									warn('cannot use clip with currently equipped clip')
									return
								end

								if currentAmmo > 0 then
									warn('cannot mix special ammo with base ammo')
									return
								end

								currentWeapon.metadata.specialAmmo = resp.metadata.type

								GiveWeaponComponentToPed(playerPed, currentWeapon.hash, specialClip)
							end
						elseif HasPedGotWeaponComponent(playerPed, currentWeapon.hash, specialClip) then
							if currentAmmo > 0 then
								warn('cannot mix special ammo with base ammo')
								return
							end

							currentWeapon.metadata.specialAmmo = nil

							RemoveWeaponComponentFromPed(playerPed, currentWeapon.hash, specialClip)
						end
					end

					if maxAmmo > clipSize then
						clipSize = GetMaxAmmoInClip(playerPed, currentWeapon.hash, true)
					end

					currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)
					local missingAmmo = clipSize - currentAmmo
					local addAmmo = resp.count > missingAmmo and missingAmmo or resp.count
					local newAmmo = currentAmmo + addAmmo

					if newAmmo == currentAmmo then return end

                    AddAmmoToPed(playerPed, currentWeapon.hash, addAmmo)

					if cache.vehicle then
						if cache.seat > -1 or IsVehicleStopped(cache.vehicle) then
							TaskReloadWeapon(playerPed, true)
                        else
                            -- This is a hacky solution for forcing ammo to properly load into the
                            -- weapon clip while driving; without it, ammo will be added but won't
                            -- load until the player stops doing anything. i.e. if you keep shooting,
                            -- the weapon will not reload until the clip empties.
                            -- And yes - for some reason RefillAmmoInstantly needs to run in a loop.
                            lib.waitFor(function()
                                RefillAmmoInstantly(playerPed)

                                local _, ammo = GetAmmoInClip(playerPed, currentWeapon.hash)
                                return ammo == newAmmo or nil
                            end)
                        end
					else
						Wait(100)
						MakePedReload(playerPed)

						SetTimeout(100, function()
							while IsPedReloading(playerPed) do
								DisableControlAction(0, 22, true)
								Wait(0)
							end
						end)
					end

					lib.callback.await('ox_inventory:updateWeapon', false, 'load', newAmmo, false, currentWeapon.metadata.specialAmmo)
				end, nil, true)
			elseif data.component then
				local components = data.client.component

                if not components then return end

				local componentType = data.type
				local weaponComponents = PlayerData.inventory[currentWeapon.slot].metadata.components

				-- Checks if the weapon already has the same component type attached
				for componentIndex = 1, #weaponComponents do
					if componentType == Items[weaponComponents[componentIndex]].type then
						return lib.notify({ id = 'component_slot_occupied', type = 'error', description = locale('component_slot_occupied', componentType) })
					end
				end

				for i = 1, #components do
					local component = components[i]

					if DoesWeaponTakeWeaponComponent(currentWeapon.hash, component) then
						if HasPedGotWeaponComponent(playerPed, currentWeapon.hash, component) then
							lib.notify({ id = 'component_has', type = 'error', description = locale('component_has', label) })
						else
							useItem(data, function(data)
								if data then
									local success = lib.callback.await('ox_inventory:updateWeapon', false, 'component', tostring(data.slot), currentWeapon.slot)

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
                return lib.notify({ id = 'cannot_perform', type = 'error', description = locale('cannot_perform') })
			end
		elseif not data.ammo and not data.component then
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
                return warn(("secondary inventory keybind '%s' disabled (keybind cannot match primary inventory keybind)"):format(self:getCurrentKey()))
            end

			if invOpen then return end

			if invBusy or not canOpenInventory() then
				return lib.notify({ id = 'inventory_player_access', type = 'error', description = locale('inventory_player_access') })
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
					local slotId = Inventory.GetSlotIdWithItem(currentWeapon.ammo, { type = currentWeapon.metadata.specialAmmo }, false)

					if slotId then
						useSlot(slotId)
					end
				else
					lib.notify({ id = 'no_durability', type = 'error', description = locale('no_durability', currentWeapon.label) })
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
			SendNUIMessage({ action = 'toggleHotbar' })
		end
	})

	for i = 1, 5 do
		lib.addKeybind({
			name = ('hotkey%s'):format(i),
			description = locale('use_hotbar', i),
			defaultKey = tostring(i),
			onPressed = function()
				if invOpen or EnableWeaponWheel or not invHotkeys or IsNuiFocused() then return end
				useSlot(i)
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
		payload.leftUtility = Utility.collect(PlayerData.inventory)
		Utility.refreshArmorFromInventory(PlayerData.inventory)
		Utility.refreshBackpackFromInventory(PlayerData.inventory)
	end

	SendNUIMessage({ action = 'refreshSlots', data = payload })

    if weight ~= PlayerData.weight then client.setPlayerData('weight', weight) end

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
	if point.instance and point.instance ~= currentInstance then return end

	point.entities = point.entities or {}

	-- Spawn per-item props when provided, otherwise fall back to a single drop model
	if point.itemProps and next(point.itemProps) then
		for i = 1, #point.itemProps do
			local entry = point.itemProps[i]
			local uid = entry.uniqueId or ('%s_%s_%s'):format(point.invId or 'drop', entry.itemName or 'item', entry.slot or i)

			local entity = point.entities[uid]

			if not entity or not DoesEntityExist(entity) then
				local model = entry.modelp or point.model or client.dropmodel

				-- Prevent breaking inventory on invalid models; fall back to default drop model
				if not IsModelValid(model) and not IsModelInCdimage(model) then
					model = client.dropmodel
				end

				lib.requestModel(model)
				local coords = entry.coords or point.coords
				entity = CreateObject(model, coords.x, coords.y, coords.z, false, true, true)

				SetModelAsNoLongerNeeded(model)
				PlaceObjectOnGroundProperly(entity)
				FreezeEntityPosition(entity, true)
				SetEntityCollision(entity, false, true)

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
		PlaceObjectOnGroundProperly(entity)
		FreezeEntityPosition(entity, true)
		SetEntityCollision(entity, false, true)

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
	PlaceObjectOnGroundProperly(entity)
	FreezeEntityPosition(entity, true)
	SetEntityCollision(entity, false, true)

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
				buttons[i] = {label = v.buttons[i].label, group = v.buttons[i].group}
			end
		end

		ItemData[v.name] = {
			label = v.label,
			stack = v.stack,
			close = v.close,
			count = 0,
			description = v.description,
			buttons = buttons,
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
	client.setPlayerData('weight', weight)
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
			message = ('**%s**  \n%s'):format(locale('purchase_license', data.name), locale('interact_prompt', GetControlInstructionalButton(0, 38, true):sub(3)))
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
                    local maxDistance = (currentInventory.distance or currentInventory.type == 'stash' and 4.8 or 1.8) + 0.2

					if currentInventory.type == 'otherplayer' then
						local id = GetPlayerFromServerId(currentInventory.id)
						local ped = GetPlayerPed(id)
						local pedCoords = GetEntityCoords(ped)

						if not id or #(playerCoords - pedCoords) > maxDistance or not (client.hasGroup(shared.police) or canOpenTarget(ped)) then
							client.closeInventory()
							lib.notify({ id = 'inventory_lost_access', type = 'error', description = locale('inventory_lost_access') })
						else
							TaskTurnPedToFaceCoord(playerPed, pedCoords.x, pedCoords.y, pedCoords.z, 50)
						end

					elseif currentInventory.coords and (#(playerCoords - currentInventory.coords) > maxDistance or canOpenTarget(playerPed)) then
						client.closeInventory()
						lib.notify({ id = 'inventory_lost_access', type = 'error', description = locale('inventory_lost_access') })
					end
				end
			end
		end

		if client.parachute and GetPedParachuteState(playerPed) ~= -1 then
			Utils.DeleteEntity(client.parachute[1])
			client.parachute = false
		end

		if EnableWeaponWheel then return end

		local weaponHash = GetSelectedPedWeapon(playerPed)

		if currentWeapon then
			if weaponHash ~= currentWeapon.hash and currentWeapon.timer then
				local weaponCount = Items[currentWeapon.name]?.count

				if weaponCount > 0 then
					SetCurrentPedWeapon(playerPed, currentWeapon.hash, true)
					SetAmmoInClip(playerPed, currentWeapon.hash, currentWeapon.metadata.ammo)
					SetPedCurrentWeaponVisible(playerPed, true, false, false, false)

					weaponHash = GetSelectedPedWeapon(playerPed)
				end

				if weaponHash ~= currentWeapon.hash then
                    lib.print.info(('%s was forcibly unequipped (caused by game behaviour or another resource)'):format(currentWeapon.name))
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

			if currentWeapon and currentWeapon.timer then
				DisableControlAction(0, 80, true)
				DisableControlAction(0, 140, true)

				if currentWeapon.metadata.durability <= 0 or not currentWeapon.timer then
					DisablePlayerFiring(playerId, true)
				elseif client.aimedfiring and not currentWeapon.melee and currentWeapon.group ~= `GROUP_PETROLCAN` and not IsPlayerFreeAiming(playerId) then
					DisablePlayerFiring(playerId, true)
				end

				local weaponAmmo = currentWeapon.metadata.ammo

				if not invBusy and currentWeapon.timer ~= 0 and currentWeapon.timer < GetGameTimer() then
					currentWeapon.timer = 0

					if weaponAmmo then
						TriggerServerEvent('ox_inventory:updateWeapon', 'ammo', weaponAmmo)

						if client.autoreload and currentWeapon.ammo and GetAmmoInPedWeapon(playerPed, currentWeapon.hash) == 0 then
							local slotId = Inventory.GetSlotIdWithItem(currentWeapon.ammo, { type = currentWeapon.metadata.specialAmmo }, false)

							if slotId then
								CreateThread(function() useSlot(slotId) end)
							end
						end

					elseif currentWeapon.metadata.durability then
						TriggerServerEvent('ox_inventory:updateWeapon', 'melee', currentWeapon.melee)
						currentWeapon.melee = 0
					end
				elseif weaponAmmo then
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
							currentAmmo = GetAmmoInPedWeapon(playerPed, currentWeapon.hash)

							if currentAmmo < weaponAmmo then
								currentAmmo = (weaponAmmo < currentAmmo) and 0 or currentAmmo
								currentWeapon.metadata.ammo = currentAmmo
								currentWeapon.metadata.durability = currentWeapon.metadata.durability - (durabilityDrain * math.abs((weaponAmmo or 0.1) - currentAmmo))
							end
						end

						if currentAmmo <= 0 then
							if cache.vehicle then
								TaskSwapWeapon(playerPed, true)
							end

							currentWeapon.timer = GetGameTimer() + 200
						else currentWeapon.timer = GetGameTimer() + (GetWeaponTimeBetweenShots(currentWeapon.hash) * 1000) + 100 end
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

	if Utility.enabled then
		left.utility = Utility.collect(PlayerData.inventory)
		left.utilityConfig = Utility.config

		if currentInventory and currentInventory.items then
			currentInventory.utility = Utility.collect(currentInventory.items)
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
		end
	end
end)

RegisterNUICallback('removeAmmo', function(slot, cb)
	cb(1)
	local slotData = PlayerData.inventory[slot]

	if not slotData or not slotData.metadata.ammo or slotData.metadata.ammo == 0 then return end

	local success = lib.callback.await('ox_inventory:removeAmmoFromWeapon', false, slot)

	if success and slot == currentWeapon?.slot then
		SetPedAmmo(playerPed, currentWeapon.hash, 0)
	end
end)

RegisterNUICallback('useItem', function(slot, cb)
	useSlot(slot --[[@as number]])
	cb(1)
end)

local function giveItemToTarget(serverId, slotId, count, fromInv)
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

local function isGiveTargetValid(ped, coords)
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

			lib.showTextUI('[N] place\n[ESC] cancel', {
				position = 'bottom-center',  

			})


		local entity = exports["Dm-throwitems"]:throwItem(data.slot, props, amount)

		while DoesEntityExist(entity) do
			DisableFrontendThisFrame()

			if IsControlJustReleased(2, 200) then
				DeleteEntity(entity)
				RemoveWeaponFromPed(playerPed, 'WEAPON_BALL')

				lib.hideTextUI()
			  plyState:set('invBusy', false, true)

			end

			if IsControlJustReleased(0, 306) then
				DeleteEntity(entity)
				RemoveWeaponFromPed(playerPed, 'WEAPON_BALL')
				lib.hideTextUI()
				exports["Dm-throwitems"]:placeItem(data.slot, props, amount)
			end

			Wait(0)
		end
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
			return giveItemToTarget(GetPlayerServerId(option.id), item and item.slot or data.slot, data.count, item and item.inventory)
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
				return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(passenger)), item and item.slot or data.slot, data.count, item and item.inventory)
			end
		end

        return
	end

    local entity = Utils.Raycast(1|2|4|8|16, GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 3.0, 0.5), 0.2)

	if entity and IsPedAPlayer(entity) and IsEntityVisible(entity) and #(GetEntityCoords(playerPed, true) - GetEntityCoords(entity, true)) < 3.0 then
		local item = lib.callback.await('inv:getItemFromSlot', false, data.slot)
		return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)), item and item.slot or data.slot, data.count, item and item.inventory)
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
			return giveItemToTarget(GetPlayerServerId(option.id), item and item.slot or data.slot, data.count, item and item.inventory)
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
				return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(passenger)), item and item.slot or data.slot, data.count, item and item.inventory)
			end
		end

        return
	end

    local entity = Utils.Raycast(1|2|4|8|16, GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 3.0, 0.5), 0.2)

	if entity and IsPedAPlayer(entity) and IsEntityVisible(entity) and #(GetEntityCoords(playerPed, true) - GetEntityCoords(entity, true)) < 3.0 then
		local item = lib.callback.await('inv:getItemFromSlot', false, data.slot)
		return giveItemToTarget(GetPlayerServerId(NetworkGetPlayerIndexFromPed(entity)), item and item.slot or data.slot, data.count, item and item.inventory)
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

	if data.toType == 'newdrop' then
		if cache.vehicle or IsPedFalling(playerPed) then
			swapActive = false
			return cb(false)
		end

		local coords = GetEntityCoords(playerPed)

		if IsEntityInWater(playerPed) then
			local destination = vec3(coords.x, coords.y, -200)
			local handle = StartShapeTestLosProbe(coords.x, coords.y, coords.z, destination.x, destination.y, destination.z, 511, cache.ped, 4)

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
				slotData = { slot = it.slot, name = it.name, count = it.count, weight = it.weight, metadata = it.metadata or {} }
				break
			end
		end

		-- Fallback: attempt to match by name and count if slot lookup failed
		if not slotData then
			for _, it in pairs(inv.items) do
				if it and it.name == data.item.name and it.count == data.item.count then
					slotData = { slot = it.slot, name = it.name, count = it.count, weight = it.weight, metadata = it.metadata or {} }
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
			slotData = { slot = data.item.slot, name = data.item.name, count = data.item.count, weight = data.item.weight, metadata = metadata }
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

	local success, response = lib.callback.await('ox_inventory:craftItem', 200, id, index, recipeSlot, toSlot, storageId, count)

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

local function weaponModelFromName(name)
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


