assert(lib.checkDependency('qbx_core', '1.18.1'), 'qbx_core v1.18.1 or higher is required')
assert(lib.checkDependency('qbx_vehicles', '1.2.0'), 'qbx_vehicles v1.2.0 or higher is required')
local Inventory = require 'modules.inventory.server'
local QBX = exports.qbx_core

AddEventHandler('qbx_core:server:playerLoggedOut', function(source)
    server.savePlayerAmmoPools(source)
    server.playerDropped(source)
    server.clearPlayerAmmoPools(source)
end)
AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    server.savePlayerAmmoPools(source)
    server.playerDropped(source)
    server.clearPlayerAmmoPools(source)
end)

AddEventHandler('qbx_core:server:onGroupUpdate', function(source, groupName, groupGrade)
    local inventory = Inventory(source)
    if not inventory then return end
    inventory.player.groups[groupName] = not groupGrade and nil or groupGrade
end)

local function setupPlayer(playerData)
    playerData.identifier = playerData.citizenid
    playerData.name = ('%s %s'):format(playerData.charinfo.firstname, playerData.charinfo.lastname)
    server.setPlayerInventory(playerData)

    local accounts = Inventory.GetAccountItemCounts(playerData.source)
    if not accounts then return end
    for account in pairs(accounts) do
        local playerAccount = account == 'money' and 'cash' or account
        Inventory.SetItem(playerData.source, account, playerData.money[playerAccount])
    end
end

AddStateBagChangeHandler('loadInventory', nil, function(bagName, _, value)
    if not value then return end
    local plySrc = GetPlayerFromStateBagName(bagName)
    if not plySrc then return end
    setupPlayer(QBX:GetPlayer(plySrc).PlayerData)
end)

AddEventHandler('QBCore:Server:OnPlayerLoaded', function(source)
    local player = QBX:GetPlayer(source)
    if not player then return end
    server.loadPlayerAmmoPools(player.PlayerData.citizenid)
end)

SetTimeout(500, function()
    local playersData = QBX:GetPlayersData()
    for i = 1, #playersData do setupPlayer(playersData[i]) end
end)

function server.UseItem(source, itemName, data)
    local cb = QBX:CanUseItem(itemName)
    return cb and cb(source, data)
end

---@diagnostic disable-next-line: duplicate-set-field
function server.setPlayerData(player)
    local groups = QBX:GetGroups(player.source)
    return {
        source = player.source,
        name = ('%s %s'):format(player.charinfo.firstname, player.charinfo.lastname),
        groups = groups,
        sex = player.charinfo.gender,
        dateofbirth = player.charinfo.birthdate,
    }
end

-- ---@diagnostic disable-next-line: duplicate-set-field
-- function server.syncInventory(inv)
--     local accounts = Inventory.GetAccountItemCounts(inv)

--     if not accounts then return end

--     local player = QBX:GetPlayer(inv.id)
--     player.Functions.SetPlayerData('items', inv.items)

--     for account, amount in pairs(accounts) do
--         account = account == 'money' and 'cash' or account
--         if player.Functions.GetMoney(account) ~= amount then
--             player.Functions.SetMoney(account, amount, ('Sync %s with inventory'):format(account))
--         end
--     end
-- end

---@diagnostic disable-next-line: duplicate-set-field
function server.hasLicense(inv, license)
    local player = QBX:GetPlayer(inv.id)
    return player and player.PlayerData.metadata.licences[license]
end

---@diagnostic disable-next-line: duplicate-set-field
function server.buyLicense(inv, license)
    local player = QBX:GetPlayer(inv.id)
    if not player then return end

    if player.PlayerData.metadata.licences[license.name] then
        return false, 'already_have'
    elseif (exports.qbx_core:GetMoney(inv.id, 'cash') or 0) < license.price then
        return false, 'can_not_afford'
    end

    if not exports.qbx_core:RemoveMoney(inv.id, 'cash', license.price, 'ox_inventory:buy_license') then
        return false, 'can_not_afford'
    end

    player.PlayerData.metadata.licences[license.name] = true
    player.Functions.SetMetaData('licences', player.PlayerData.metadata.licences)

    return true, 'have_purchased'
end

---@diagnostic disable-next-line: duplicate-set-field
function server.isPlayerBoss(playerId, group, grade)
    return QBX:IsGradeBoss(group, grade)
end

---@param entityId number
---@return number | string
---@diagnostic disable-next-line: duplicate-set-field
function server.getOwnedVehicleId(entityId)
    return Entity(entityId).state.vehicleid or
        exports.qbx_vehicles:GetVehicleIdByPlate(GetVehicleNumberPlateText(entityId))
end

local function normaliseCurrency(currency)
    if server.normaliseCurrency then
        return server.normaliseCurrency(currency)
    end

    currency = type(currency) == 'string' and currency:lower() or 'money'
    if currency == 'cash' then currency = 'money' end
    return currency
end

---@diagnostic disable-next-line: duplicate-set-field
function server.getCurrencyBalance(source, currency)
    local normalised = normaliseCurrency(currency)
    local account = normalised == 'money' and 'cash' or normalised
    return exports.qbx_core:GetMoney(source, account) or 0
end

---@diagnostic disable-next-line: duplicate-set-field
function server.removeCurrency(source, currency, amount, context)
    local normalised = normaliseCurrency(currency)
    local account = normalised == 'money' and 'cash' or normalised
    return exports.qbx_core:RemoveMoney(source, account, amount, context or 'ox_inventory:transaction') or false
end
