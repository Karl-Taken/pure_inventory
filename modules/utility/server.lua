if not lib then
    return {}
end

local Utility = {}
local UtilityConfig = lib.load('data.utility') or {}
Utility.config = UtilityConfig

local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'

local function isEnabled()
    return UtilityConfig.enabled and (UtilityConfig.slots or 0) > 0
end

if not isEnabled() then
    return Utility
end

local slotOffset = UtilityConfig.slotOffset or (shared.playerslots + 100)
Utility.slotOffset = slotOffset

local armorItems = UtilityConfig.armorItems or {}
local armorRepairItems = UtilityConfig.armorRepairItems or {}
local armorDamageRate = UtilityConfig.armorDamageRate or 1.0

local function getReservedSlot(index)
    return slotOffset + index
end

local function cloneMetadata(metadata)
    return metadata and table.clone(metadata) or {}
end

local function generateBackpackIdentifier(owner, reservedSlot)
    local suffix = ('%04x%04x'):format(math.random(0, 0xFFFF), math.random(0, 0xFFFF))
    return ('backpack-%s-%s-%s'):format(owner or 'player', reservedSlot, suffix)
end

local function getArmorValue(itemName)
    local config = armorItems[itemName]
    if not config then return end

    local value = type(config) == 'table' and config.value or config

    if not value or value <= 0 then
        return nil
    end

    return value, config
end

local function extractJobName(entry)
    if not entry then return nil end

    local entryType = type(entry)

    if entryType == 'string' then
        return entry
    elseif entryType == 'table' then
        if type(entry.name) == 'string' and entry.name ~= '' then
            return entry.name
        end

        if type(entry.job) == 'string' and entry.job ~= '' then
            return entry.job
        elseif type(entry.job) == 'table' then
            local nested = extractJobName(entry.job)
            if nested then return nested end
        end

        if type(entry.group) == 'string' and entry.group ~= '' then
            return entry.group
        end

        if type(entry.type) == 'string' and entry.type ~= '' then
            return entry.type
        end

        if type(entry.identifier) == 'string' and entry.identifier ~= '' then
            return entry.identifier
        end

        if type(entry.id) == 'string' and entry.id ~= '' then
            return entry.id
        end

        if type(entry.label) == 'string' and entry.label ~= '' then
            return entry.label
        end

        if type(entry[1]) == 'string' and entry[1] ~= '' then
            return entry[1]
        end
    end

    return nil
end

local function groupEntryActive(value)
    local valueType = type(value)

    if valueType == 'nil' then
        return false
    elseif valueType == 'boolean' then
        return value
    elseif valueType == 'number' then
        return value >= 0
    elseif valueType == 'string' then
        return value ~= ''
    elseif valueType == 'table' then
        if value.duty ~= nil and value.duty == false then
            return false
        end

        local grade = value.grade or value.rank or value.level or value.jobGrade or value.position or value.grade_level

        if type(grade) == 'number' then
            return grade >= 0
        end

        return true
    end

    return false
end

local function jobMatchesEntry(key, value, desiredLower)
    if type(key) == 'string' and key ~= '' then
        if key:lower() == desiredLower then
            return groupEntryActive(value)
        end
    end

    local name = extractJobName(value)

    if name and type(name) == 'string' and name ~= '' and name:lower() == desiredLower then
        return groupEntryActive(value)
    end

    return false
end

local function playerHasJob(inventory, jobName)
    if not inventory or not jobName then return false end

    local playerData = inventory.player
    if not playerData then return false end

    jobName = tostring(jobName)

    if jobName == '' then return false end

    local jobLower = jobName:lower()

    local directSources = {
        playerData.job,
        playerData.Job,
        playerData.primaryJob,
        playerData.mainJob,
        playerData.profession,
        playerData.group,
    }

    for i = 1, #directSources do
        local source = directSources[i]
        if source and jobMatchesEntry(nil, source, jobLower) then
            return true
        end
    end

    if type(playerData.jobs) == 'table' then
        for key, value in pairs(playerData.jobs) do
            if jobMatchesEntry(key, value, jobLower) then
                return true
            end
        end
    end

    if type(playerData.groups) == 'table' then
        for key, value in pairs(playerData.groups) do
            if jobMatchesEntry(key, value, jobLower) then
                return true
            end
        end
    end

    local stateData = playerData.state

    if type(stateData) == 'table' then
        if jobMatchesEntry(nil, stateData.job, jobLower) then
            return true
        end

        if jobMatchesEntry(nil, stateData.group, jobLower) then
            return true
        end
    end

    return false
end

local function playerHasAllowedJob(inventory, jobs)
    if not jobs then
        return true
    end

    local jobsType = type(jobs)

    if jobsType ~= 'table' then
        return playerHasJob(inventory, jobs)
    end

    local hasEntries = false

    for key, value in pairs(jobs) do
        hasEntries = true

        local jobName

        if type(key) == 'string' and key ~= '' then
            jobName = key
        else
            jobName = extractJobName(value)
        end

        if jobName and playerHasJob(inventory, jobName) then
            return true
        end
    end

    return not hasEntries
end

local function isItemAllowed(itemName, utilitySlot)
    local allowed = UtilityConfig.items and UtilityConfig.items[utilitySlot]

    if not allowed then return false end

    for i = 1, #allowed do
        if allowed[i] == itemName then
            return true
        end
    end

    return false
end

local function syncSlots(inventory, slots)
    inventory:syncSlotsWithPlayer(slots, inventory.weight)
    inventory:syncSlotsWithClients(slots, true)
end

local function validateArmorAccess(inventory, itemName)
    local config = armorItems[itemName]

    if not config then
        return true
    end

    local jobs = config.jobs

    if not jobs then
        return true
    end

    local allowed = playerHasAllowedJob(inventory, jobs)


    return allowed
end

local function setUtilityMetadata(metadata, utilitySlot, itemName, owner, reservedSlot)
    metadata.utilitySlot = utilitySlot

    local backpackConfig = UtilityConfig.backpackItems and UtilityConfig.backpackItems[itemName]

    if backpackConfig then
        local existingId = metadata.backpackUid or metadata.backpackId

        if not existingId then
            existingId = generateBackpackIdentifier(owner, reservedSlot)
        end

        metadata.backpackUid = existingId
        metadata.backpackId = existingId
        metadata.container = metadata.backpackId
        metadata.size = { backpackConfig.slots or 0, backpackConfig.weight or 0 }
    else
        metadata.backpackId = nil
        metadata.backpackUid = nil
        metadata.container = nil
        metadata.size = nil
    end

    if UtilityConfig.armorItems and UtilityConfig.armorItems[itemName] then
        metadata.durability = metadata.durability or 100
    end

    return metadata
end

local function clearUtilityMetadata(metadata)
    if metadata then
        metadata.utilitySlot = nil
        metadata.backpackId = metadata.backpackUid or metadata.backpackId
        metadata.container = nil
        metadata.size = nil
    end

    return metadata
end

local function ensureBackpackInventory(ownerInventory, slotData)
    if not slotData or not slotData.name or not slotData.metadata then return nil end

    local config = UtilityConfig.backpackItems and UtilityConfig.backpackItems[slotData.name]

    if not config then return nil end

    local containerId = slotData.metadata.container or slotData.metadata.backpackId

    if not containerId then return nil end

    local ownerId = ownerInventory.owner
    local containerKey = ownerId and ('%s:%s'):format(containerId, ownerId) or containerId
    local container = Inventory(containerKey)

    if not container then
        if ownerId then
            container = Inventory({ id = containerId, owner = ownerId })
            if not container then
                container = Inventory(containerId)
            end
        else
            container = Inventory({ id = containerId })
        end
    end

    if not container then
        local itemDef = Items(slotData.name)
        local label = (itemDef and itemDef.label) or slotData.label or 'Backpack'
        container = Inventory.Create(
            containerId,
            label,
            'backpack',
            config.slots or 0,
            0,
            config.weight or 0,
            ownerId,
            nil
        )
    else
        if config.slots and container.slots ~= config.slots then
            Inventory.SetSlotCount(container, config.slots)
        end

        if config.weight and container.maxWeight ~= config.weight then
            Inventory.SetMaxWeight(container, config.weight)
        end
    end

    if container then
        container.label = container.label or slotData.label or 'Backpack'
        container.owner = ownerInventory.owner
    end

    return container
end

local function serialiseInventory(inv, overrideType)
    if not inv then return nil end

    local items = table.create(inv.slots, 0)

    for slot = 1, inv.slots do
        local item = inv.items[slot]

        if item then
            items[slot] = table.clone(item)
        else
            items[slot] = { slot = slot }
        end
    end

    return {
        id = tostring(inv.id),
        type = overrideType or inv.type or 'backpack',
        label = inv.label or 'Backpack',
        slots = inv.slots,
        items = items,
        maxWeight = inv.maxWeight,
        weight = inv.weight,
    }
end

lib.callback.register('ox_inventory:utility:moveTo', function(source, data)
    if source == '' then return false, 'Utility action unavailable' end

    local fromSlot = tonumber(data?.fromSlot)
    local utilitySlot = tonumber(data?.utilitySlot)

    if not fromSlot or not utilitySlot then
        return false, 'Invalid utility request'
    end

    if utilitySlot < 1 or utilitySlot > (UtilityConfig.slots or 0) then
        return false, 'Invalid utility slot'
    end

    local inventory = Inventory(source)

    if not inventory then
        return false, 'Inventory unavailable'
    end

    local slotData = inventory.items[fromSlot]

    if not slotData or not slotData.name then
        return false, 'Item not found'
    end

    if slotData.metadata and slotData.metadata.container then
        local openInventory = inventory.open

        if openInventory and openInventory == slotData.metadata.container then
            return false, 'Close the container before moving it'
        end
    end

    if not isItemAllowed(slotData.name, utilitySlot) then
        return false, 'This item cannot be placed in this slot'
    end

    if not validateArmorAccess(inventory, slotData.name) then
        return false, 'You are not authorised to equip this item'
    end

    local reservedSlot = getReservedSlot(utilitySlot)

    if inventory.items[reservedSlot] and reservedSlot ~= fromSlot then
        return false, 'Utility slot is already occupied'
    end

    local container
    local backpackConfig = UtilityConfig.backpackItems and UtilityConfig.backpackItems[slotData.name]

    if backpackConfig then
        container = ensureBackpackInventory(inventory, slotData)

        if container then
            container.openedBy[inventory.id] = nil

            if inventory.open == container.id or inventory.open == slotData.metadata.container then
                inventory.open = false
                inventory.containerSlot = nil
                container:set('open', false)
            end
        elseif inventory.open == slotData.metadata.container then
            inventory.open = false
            inventory.containerSlot = nil
        end
    end

    local itemDefinition = Items(slotData.name)

    if not itemDefinition then
        return false, 'Item data unavailable'
    end

    local armorValue = getArmorValue(slotData.name)

    local armorValue = getArmorValue(slotData.name)

    local metadata = cloneMetadata(slotData.metadata)
    metadata = setUtilityMetadata(metadata, utilitySlot, slotData.name, inventory.owner, reservedSlot)

    Inventory.SetSlot(inventory, itemDefinition, -slotData.count, slotData.metadata, fromSlot)
    local newItem = Inventory.SetSlot(inventory, itemDefinition, slotData.count, metadata, reservedSlot)

    local container = ensureBackpackInventory(inventory, newItem)

    local updates = {
        { item = inventory.items[fromSlot] or { slot = fromSlot }, inventory = inventory.id },
        { item = newItem, inventory = inventory.id },
    }

    syncSlots(inventory, updates)

    if container then
        TriggerClientEvent('ox_inventory:utility:setBackpack', inventory.id, serialiseInventory(container, 'backpack'))
    end

    if armorValue and newItem then
        local durability = tonumber(newItem.metadata and newItem.metadata.durability) or 100
        if durability < 0 then durability = 0 elseif durability > 100 then durability = 100 end

        TriggerClientEvent('ox_inventory:utility:wearArmor', inventory.id, {
            slot = reservedSlot,
            utilitySlot = utilitySlot,
            maxValue = armorValue,
            durability = durability
        })
    end

    local backpackConfig = UtilityConfig.backpackItems and UtilityConfig.backpackItems[slotData.name]
    if backpackConfig and backpackConfig.component and newItem then
        TriggerClientEvent('ox_inventory:utility:wearBackpack', inventory.id, {
            slot = reservedSlot,
            utilitySlot = utilitySlot,
            itemName = slotData.name,
            drawable = backpackConfig.component.drawable,
            texture = backpackConfig.component.texture or 0
        })
    end

    return true, { slot = reservedSlot }
end)

lib.callback.register('ox_inventory:utility:moveFrom', function(source, data)
    if source == '' then return false, 'Utility action unavailable' end

    local utilitySlot = tonumber(data?.utilitySlot)
    local toSlot = tonumber(data?.toSlot)

    if not utilitySlot then
        return false, 'Invalid utility request'
    end

    local inventory = Inventory(source)

    if not inventory then
        return false, 'Inventory unavailable'
    end

    local reservedSlot = getReservedSlot(utilitySlot)
    local slotData = inventory.items[reservedSlot]

    if not slotData or not slotData.name then
        return false, 'Item not found'
    end

    local itemDefinition = Items(slotData.name)

    if not itemDefinition then
        return false, 'Item data unavailable'
    end

    local backpackConfig = UtilityConfig.backpackItems and UtilityConfig.backpackItems[slotData.name]
    local isBackpack = backpackConfig ~= nil

    if isBackpack and UtilityConfig.lockBackpackRemovalWithItems then
        local meta = slotData.metadata
        local containerId = meta and (meta.container or meta.backpackId)

        if containerId then
            local containerInventory = Inventory(containerId)
            
            -- Try alternative lookup methods if first attempt fails
            if not containerInventory and inventory.owner then
                local containerKey = ('%s:%s'):format(containerId, inventory.owner)
                containerInventory = Inventory(containerKey)
            end
            
            if not containerInventory then
                containerInventory = Inventory({ id = containerId, owner = inventory.owner })
            end

            if containerInventory then
                for slotIndex = 1, containerInventory.slots do
                    local containerSlot = containerInventory.items[slotIndex]

                    if containerSlot and containerSlot.name then
                        return false, 'backpack_not_empty'
                    end
                end
            end
        end
    end

    local metadata = cloneMetadata(slotData.metadata)
    clearUtilityMetadata(metadata)

    Inventory.SetSlot(inventory, itemDefinition, -slotData.count, slotData.metadata, reservedSlot)

    local updates = {}

    if toSlot then
        local existing = inventory.items[toSlot]

        if existing and existing.name and existing.name ~= slotData.name then
            Inventory.SetSlot(inventory, itemDefinition, slotData.count, slotData.metadata, reservedSlot)
            return false, 'Target slot is occupied'
        end

        local response = Inventory.SetSlot(inventory, itemDefinition, slotData.count, metadata, toSlot)
        updates[#updates + 1] = { item = { slot = reservedSlot }, inventory = inventory.id }
        updates[#updates + 1] = { item = response, inventory = inventory.id }

        if backpackConfig then
            TriggerClientEvent('ox_inventory:utility:setBackpack', inventory.id, false)
        end

        syncSlots(inventory, updates)
        if armorValue then
            TriggerClientEvent('ox_inventory:utility:removeArmor', inventory.id, { slot = reservedSlot })
        end
        return true, { slot = toSlot }
    end

    local addSuccess, addResult = Inventory.AddItem(inventory, itemDefinition, slotData.count, metadata)

    if not addSuccess then
        Inventory.SetSlot(inventory, itemDefinition, slotData.count, slotData.metadata, reservedSlot)
        return false, addResult or 'Inventory is full'
    end

    updates[#updates + 1] = { item = { slot = reservedSlot }, inventory = inventory.id }

    if type(addResult) == 'table' then
        if addResult.slot then
            updates[#updates + 1] = { item = addResult, inventory = inventory.id }
        else
            for i = 1, #addResult do
                updates[#updates + 1] = { item = addResult[i], inventory = inventory.id }
            end
        end
    end

    -- Add small delay before sync operations
    Wait(0)
    
    if backpackConfig then
        TriggerClientEvent('ox_inventory:utility:setBackpack', inventory.id, false)
        Wait(0) -- Additional delay after backpack event
    end

    syncSlots(inventory, updates)

    if armorValue then
        TriggerClientEvent('ox_inventory:utility:removeArmor', inventory.id, { slot = reservedSlot })
    end

    if backpackConfig then
        TriggerClientEvent('ox_inventory:utility:removeBackpack', inventory.id, { slot = reservedSlot })
    end

    return true, addResult
end)

local function buildBackpackPayload(source, target)
    if source == '' then return {} end

    local payload = {}

    local function findBackpack(inv)
        if not inv then return nil, nil end

        for slotIndex = 1, (UtilityConfig.slots or 0) do
            local reservedSlot = getReservedSlot(slotIndex)
            local slotData = inv.items[reservedSlot]

            if slotData and slotData.name and slotData.metadata and UtilityConfig.backpackItems and UtilityConfig.backpackItems[slotData.name] then
                local container = ensureBackpackInventory(inv, slotData)

                if container then
                    return serialiseInventory(container, 'backpack'), slotIndex
                end
            end
        end

        return nil, nil
    end

    local playerInventory = Inventory(source)
    if playerInventory then
        local bp, idx = findBackpack(playerInventory)
        if bp then
            payload.backpack = bp
            payload.utilitySlot = idx
        end
    end

    if target and type(target) == 'number' then
        local otherInventory = Inventory(target)

        if otherInventory then
            local otherBp = select(1, findBackpack(otherInventory))

            if otherBp then
                payload.otherBackpack = otherBp
            end
        end
    end

    return payload
end

Utility.getBackpackPayload = buildBackpackPayload

lib.callback.register('ox_inventory:utility:getBackpack', function(source, target)
    return buildBackpackPayload(source, target)
end)

RegisterNetEvent('ox_inventory:utility:updateArmorDurability', function(slot, loss)
    local src = source
    slot = tonumber(slot)
    loss = tonumber(loss)

    if not slot or not loss or loss <= 0 then return end

    local inventory = Inventory(src)
    if not inventory then return end

    local slotData = inventory.items[slot]
    if not slotData or not slotData.name then return end

    local armorValue = getArmorValue(slotData.name)
    if not armorValue then return end

    local metadata = cloneMetadata(slotData.metadata)
    local currentDurability = tonumber(metadata.durability) or 100
    local rate = armorDamageRate > 0 and armorDamageRate or 1.0
    local durabilityLoss = loss * rate

    if durabilityLoss <= 0 then return end

    local newDurability = math.max(0, currentDurability - durabilityLoss)
    metadata.durability = newDurability

    Inventory.SetMetadata(inventory, slot, metadata)

    if newDurability <= 0 then
        TriggerClientEvent('ox_inventory:utility:removeArmor', src, { slot = slot, broken = true })
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = locale('armor_broken') })
    else
        local actualArmor = math.floor(armorValue * (newDurability / 100))
        TriggerClientEvent('ox_inventory:utility:updateArmor', src, {
            slot = slot,
            value = actualArmor,
            maxValue = armorValue,
            durability = newDurability
        })
    end
end)

RegisterNetEvent('ox_inventory:utility:applyArmorPlate', function(data)
    local src = source
    local itemName = data and data.name
    local slot = data and data.slot

    if not itemName then return end

    local repairAmount = armorRepairItems[itemName]
    if not repairAmount or repairAmount <= 0 then
        return
    end

    local inventory = Inventory(src)
    if not inventory then
        return
    end

    local targetSlot
    local equippedArmor

    for index = 1, (UtilityConfig.slots or 0) do
        local reservedSlot = getReservedSlot(index)
        local slotData = inventory.items[reservedSlot]

        if slotData and slotData.name and getArmorValue(slotData.name) then
            targetSlot = reservedSlot
            equippedArmor = slotData
            break
        end
    end

    if not targetSlot or not equippedArmor then
        TriggerClientEvent('ox_lib:notify', src, { type = 'error', description = locale('armor_not_equipped') })
        return
    end

    local metadata = cloneMetadata(equippedArmor.metadata)
    local currentDurability = tonumber(metadata.durability) or 100

    if currentDurability >= 100 then
        TriggerClientEvent('ox_lib:notify', src, { type = 'info', description = locale('armor_already_max') })
        return
    end

    if not Inventory.RemoveItem(inventory, itemName, 1, nil, slot) then
        return
    end

    local newDurability = math.min(100, currentDurability + repairAmount)
    metadata.durability = newDurability

    Inventory.SetMetadata(inventory, targetSlot, metadata)

    local armorValue = getArmorValue(equippedArmor.name)
    local actualArmor = math.floor(armorValue * (newDurability / 100))

    TriggerClientEvent('ox_inventory:utility:updateArmor', src, {
        slot = targetSlot,
        value = actualArmor,
        maxValue = armorValue,
        durability = newDurability
    })

    TriggerClientEvent('ox_lib:notify', src, { type = 'success', description = locale('armor_repaired') })
end)

return Utility
