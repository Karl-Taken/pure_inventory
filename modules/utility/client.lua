if not lib then
    return {}
end

local Utility = {}
local UtilityConfig = lib.load('data.utility') or {}

Utility.config = UtilityConfig
Utility.enabled = UtilityConfig.enabled and (UtilityConfig.slots or 0) > 0
Utility.slotOffset = UtilityConfig.slotOffset or 0

local armorItems = UtilityConfig.armorItems or {}
local backpackItems = UtilityConfig.backpackItems or {}
local backpackComponentsEnabled = UtilityConfig.enableBackpackComponents ~= false

local playerPed = cache.ped

lib.onCache('ped', function(ped)
    playerPed = ped

    if Utility.currentArmor and Utility.currentArmor.value and Utility.currentArmor.value > 0 then
        SetPedArmour(playerPed, Utility.currentArmor.value)
    end

    if backpackComponentsEnabled and Utility.currentBackpack and Utility.currentBackpack.drawable then
        SetPedComponentVariation(playerPed, 5, Utility.currentBackpack.drawable, Utility.currentBackpack.texture, 0)
    end
end)

local currentArmor = {
    slot = nil,
    utilitySlot = nil,
    maxValue = 0,
    durability = 0,
    value = 0,
}

Utility.currentArmor = currentArmor

local currentBackpack = {
    slot = nil,
    utilitySlot = nil,
    itemName = nil,
    drawable = nil,
    texture = nil,
}

Utility.currentBackpack = currentBackpack

local lastArmorValue = 0
local isRepairing = false

local function setPedArmor(value)
    local ped = playerPed or cache.ped

    if not ped then return end

    SetPlayerMaxArmour(PlayerId(), 100)
    SetPedArmour(ped, value)
end

local function getBackpackConfig(itemName)
    local config = backpackItems[itemName]
    if not config or not config.component then return nil end

    return config.component
end

local function setBackpackComponent(drawable, texture)
    local ped = playerPed or cache.ped
    if not ped then return end

    SetPedComponentVariation(ped, 5, drawable, texture or 0, 0)
end

local function removeBackpackComponent()
    local ped = playerPed or cache.ped
    if not ped then return end

    SetPedComponentVariation(ped, 5, 0, 0, 0)
end

local function clampDurability(value)
    if not value then return 0 end

    if value > 100 then
        return 100
    elseif value < 0 then
        return 0
    end

    return value
end

local function getArmorConfig(itemName)
    local config = armorItems[itemName]
    if not config then return end

    local maxValue = type(config) == 'table' and config.value or config

    if not maxValue or maxValue <= 0 then
        return nil
    end

    return maxValue, config
end

local function computeArmorValue(maxValue, durability)
    if not maxValue or maxValue <= 0 then
        return 0
    end

    durability = clampDurability(durability)
    return math.floor((maxValue * durability) / 100 + 0.5)
end

local function getReservedSlot(index)
    if Utility.slotOffset == 0 then
        return nil
    end

    return Utility.slotOffset + index
end

local function getUtilitySlot(metadata, slot)
    if metadata and metadata.utilitySlot then
        return metadata.utilitySlot
    end

    if Utility.slotOffset > 0 and slot and slot >= Utility.slotOffset then
        return slot - Utility.slotOffset
    end
end

Utility.getReservedSlot = getReservedSlot
Utility.getUtilitySlot = getUtilitySlot

local function applyArmorState(slot, utilitySlot, maxValue, durability, armourValue)
    currentArmor.slot = slot
    currentArmor.utilitySlot = utilitySlot
    currentArmor.maxValue = maxValue or 0
    currentArmor.durability = clampDurability(durability)
    currentArmor.value = armourValue or computeArmorValue(currentArmor.maxValue, currentArmor.durability)

    setPedArmor(currentArmor.value)
    lastArmorValue = currentArmor.value
end

local function resetArmorState()
    if currentArmor.slot then
        currentArmor.slot = nil
        currentArmor.utilitySlot = nil
        currentArmor.maxValue = 0
        currentArmor.durability = 0
        currentArmor.value = 0
    end

    setPedArmor(0)
    lastArmorValue = 0
end

local function cloneSlot(slotData)
    if not slotData then return nil end

    local copy = table.clone(slotData)
    if copy.metadata then
        copy.metadata = table.clone(copy.metadata)
    end

    return copy
end

local function findEquippedArmor(items)
    if not items then return nil end

    local best

    for slot, slotData in pairs(items) do
        if slotData and slotData.name and slotData.metadata then
            local utilitySlot = getUtilitySlot(slotData.metadata, slot)

            if utilitySlot then
                local maxValue = getArmorConfig(slotData.name)

                if maxValue then
                    local durability = clampDurability(tonumber(slotData.metadata.durability) or 100)
                    local value = computeArmorValue(maxValue, durability)

                    if value > 0 then
                        if not best or value > best.value or (value == best.value and durability > best.durability) then
                            best = {
                                slot = slot,
                                utilitySlot = utilitySlot,
                                maxValue = maxValue,
                                durability = durability,
                                value = value,
                            }
                        end
                    end
                end
            end
        end
    end

    return best
end

function Utility.collect(items)
    if not Utility.enabled then
        return nil
    end

    local slots = UtilityConfig.slots or 0
    local offset = Utility.slotOffset

    local state = {
        slots = slots,
        offset = offset,
        items = {},
        config = {
            labels = UtilityConfig.labels or {},
            icons = UtilityConfig.icons or {},
            iconSizes = UtilityConfig.iconSizes or {},
            items = UtilityConfig.items or {},
        },
    }

    for i = 1, slots do
        state.items[i] = { slot = offset > 0 and offset + i or i }
    end

    if not items then
        return state
    end

    for slot, slotData in pairs(items) do
        if slotData and slotData.name then
            local utilitySlot = getUtilitySlot(slotData.metadata, slot)

            if utilitySlot and utilitySlot >= 1 and utilitySlot <= slots then
                state.items[utilitySlot] = cloneSlot(slotData)
            end
        end
    end

    return state
end

function Utility.refreshArmorFromInventory(items)
    if not Utility.enabled then return false end

    
    local armor = findEquippedArmor(items)

    if armor then
        applyArmorState(armor.slot, armor.utilitySlot, armor.maxValue, armor.durability, armor.value)
        return true
    end

    
    if currentArmor.slot then
        resetArmorState()
    end

    return false
end

function Utility.refreshBackpackFromInventory(items)
    if not Utility.enabled or not backpackComponentsEnabled then return false end

    if not items then
        if currentBackpack.slot then
            removeBackpackComponent()
            currentBackpack.slot = nil
            currentBackpack.utilitySlot = nil
            currentBackpack.itemName = nil
            currentBackpack.drawable = nil
            currentBackpack.texture = nil
        end
        return false
    end

    -- Only check items in the utility slot range
    local slots = UtilityConfig.slots or 0
    local offset = Utility.slotOffset

    for i = 1, slots do
        local reservedSlot = offset > 0 and offset + i or i
        local slotData = items[reservedSlot]

        if slotData and slotData.name then
            local utilitySlot = getUtilitySlot(slotData.metadata, reservedSlot)

            if utilitySlot and utilitySlot == i then
                local component = getBackpackConfig(slotData.name)

                if component and component.drawable then
                    currentBackpack.slot = reservedSlot
                    currentBackpack.utilitySlot = utilitySlot
                    currentBackpack.itemName = slotData.name
                    currentBackpack.drawable = component.drawable
                    currentBackpack.texture = component.texture or 0

                    setBackpackComponent(currentBackpack.drawable, currentBackpack.texture)
                    return true
                end
            end
        end
    end

    if currentBackpack.slot then
        removeBackpackComponent()
        currentBackpack.slot = nil
        currentBackpack.utilitySlot = nil
        currentBackpack.itemName = nil
        currentBackpack.drawable = nil
        currentBackpack.texture = nil
    end

    return false
end

function Utility.getEquippedArmor()
    if not currentArmor.slot then return nil end

    return {
        slot = currentArmor.slot,
        utilitySlot = currentArmor.utilitySlot,
        maxValue = currentArmor.maxValue,
        durability = currentArmor.durability,
        value = currentArmor.value,
    }
end

function Utility.setRepairing(state)
    isRepairing = state and true or false
end

function Utility.isRepairing()
    return isRepairing
end

function Utility.canRepair()
    if not Utility.enabled then
        return false, nil, 'armor_repair_disabled'
    end
    if currentArmor.durability >= 100 then
        return false, table.clone(currentArmor), 'armor_already_max'
    end

    return true, table.clone(currentArmor)
end

function Utility.setArmorState(data)
    if not data then return end

    local slot = tonumber(data.slot) or data.slot
    local utilitySlot = tonumber(data.utilitySlot) or data.utilitySlot
    local maxValue = data.maxValue or data.maxArmorValue
    local durability = data.durability or data.armorDurability or 100

    if not maxValue then
        maxValue = getArmorConfig(data.name or (currentArmor.slot and currentArmor.name))
    end

    applyArmorState(slot, utilitySlot, maxValue or currentArmor.maxValue, durability, data.value)
end

function Utility.updateArmorValue(value, durability)
    if not currentArmor.slot then return end

    local armourValue = math.max(0, math.floor((value or currentArmor.value) + 0.5))
    setPedArmor(armourValue)

    currentArmor.value = armourValue

    if durability then
        currentArmor.durability = clampDurability(durability)
    end

    lastArmorValue = armourValue
end

function Utility.clearArmor()
    resetArmorState()
end

function Utility.setBackpackState(data)
    if not data or not backpackComponentsEnabled then return end

    local slot = tonumber(data.slot) or data.slot
    local utilitySlot = tonumber(data.utilitySlot) or data.utilitySlot
    local itemName = data.itemName or data.name
    local drawable = data.drawable
    local texture = data.texture or 0

    if not drawable then
        local component = getBackpackConfig(itemName)
        if component then
            drawable = component.drawable
            texture = component.texture or 0
        end
    end

    if drawable then
        currentBackpack.slot = slot
        currentBackpack.utilitySlot = utilitySlot
        currentBackpack.itemName = itemName
        currentBackpack.drawable = drawable
        currentBackpack.texture = texture

        setBackpackComponent(drawable, texture)
    end
end

function Utility.clearBackpack()
    if currentBackpack.slot then
        removeBackpackComponent()
        currentBackpack.slot = nil
        currentBackpack.utilitySlot = nil
        currentBackpack.itemName = nil
        currentBackpack.drawable = nil
        currentBackpack.texture = nil
    end
end

RegisterNetEvent('ox_inventory:utility:wearArmor', function(data)
    if not Utility.enabled then return end
    Utility.setArmorState(data)
end)

RegisterNetEvent('ox_inventory:utility:updateArmor', function(data)
    if not Utility.enabled then return end

    if not currentArmor.slot or (data.slot and data.slot ~= currentArmor.slot) then
        Utility.setArmorState(data)
        return
    end

    Utility.updateArmorValue(data.value, data.durability or data.armorDurability)
end)

RegisterNetEvent('ox_inventory:utility:removeArmor', function(data)
    if not Utility.enabled then return end

    if not data or not data.slot or not currentArmor.slot or data.slot == currentArmor.slot then
        resetArmorState()
    end
end)

RegisterNetEvent('ox_inventory:utility:wearBackpack', function(data)
    if not Utility.enabled or not backpackComponentsEnabled then return end
    Utility.setBackpackState(data)
end)

RegisterNetEvent('ox_inventory:utility:removeBackpack', function(data)
    if not Utility.enabled or not backpackComponentsEnabled then return end

    if not data or not data.slot or not currentBackpack.slot or data.slot == currentBackpack.slot then
        Utility.clearBackpack()
    end
end)

RegisterNetEvent('ox_inventory:utility:applyArmorPlate', function(data)
    if not Utility.enabled then return end

    local canRepair, _, message = Utility.canRepair()

    if not canRepair then
        return lib.notify({ type = 'error', description = message or 'Armor does not need repair' })
    end

    if lib.progressBar({
        duration = 5000,
        label = 'Repairing Armor',
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = true,
            combat = true,
        },
        anim = {
            dict = 'invitems@anims',
            clip = 'armor_plate'
        },
    }) then
        TriggerServerEvent('ox_inventory:utility:applyArmorPlate', data)
    end
end)

CreateThread(function()
    while true do
        Wait(500)

        if not Utility.enabled or not currentArmor.slot or currentArmor.maxValue <= 0 then
            lastArmorValue = currentArmor.value or 0
        elseif PlayerData and PlayerData.loaded then
            local ped = playerPed or cache.ped

            if ped and DoesEntityExist(ped) then
                local armourValue = GetPedArmour(ped)

                if armourValue < lastArmorValue - 0.5 then
                    local diff = lastArmorValue - armourValue

                    if diff > 0 then
                        local durabilityLoss = (diff / currentArmor.maxValue) * 100

                        if durabilityLoss > 0 then
                            TriggerServerEvent('ox_inventory:utility:updateArmorDurability', currentArmor.slot, durabilityLoss)
                        end
                    end
                end

                lastArmorValue = armourValue
            end
        end
    end
end)

return Utility
