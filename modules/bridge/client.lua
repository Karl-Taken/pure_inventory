if not lib then return end

---@diagnostic disable-next-line: duplicate-set-field
function client.setPlayerData(key, value)
	PlayerData[key] = value
	OnPlayerData(key, value)
end

function client.hasGroup(group)
	if not PlayerData.loaded then return end
	if type(group) == 'table' then
		-- Support both map-style ({ groupName = rank }) and array-style ({ 'groupName', ... })
		for k, v in pairs(group) do
			local name, rank
			if type(k) == 'number' then
				name = v
				rank = nil
			else
				name = k
				rank = v
			end
			local groupRank = PlayerData.groups[name]
			if groupRank and groupRank >= (rank or 0) then
				return name, groupRank
			end
		end
	else
		local groupRank = PlayerData.groups[group]
		if groupRank then
			return group, groupRank
		end
	end
end

local Shops = require 'modules.shops.client'
local Utils = require 'modules.utils.client'
local Weapon = require 'modules.weapon.client'
local Items = require 'modules.items.client'
local Utility = require 'modules.utility.client'

function client.onLogin()
    if not PlayerData.loaded then return end

    if Utility.enabled then
        -- Wait for clothing scripts to apply appearance
        Citizen.CreateThread(function()
            Citizen.Wait(2000)
            Utility.refreshArmorFromInventory(PlayerData.inventory)
            Utility.refreshBackpackFromInventory(PlayerData.inventory)
        end)
    end
end

function client.onLogout()
	if not PlayerData.loaded then return end

	if client.parachute then
		Utils.DeleteEntity(client.parachute[1])
		client.parachute = false
	end

	for _, point in pairs(client.drops) do
		if point.entity then
			Utils.DeleteEntity(point.entity)
		end

		if point.entities then
			for uid, entity in pairs(point.entities) do
				if entity and DoesEntityExist(entity) then
					Utils.DeleteEntity(entity)
				end

				if client.dropObjects then
					client.dropObjects[uid] = nil
				end
			end

			point.entities = nil
		end

		point:remove()
	end

	if client.dropObjects then
		for uid, record in pairs(client.dropObjects) do
			if record then
				local entity = record.entity

				if entity and DoesEntityExist(entity) then
					Utils.DeleteEntity(entity)
				elseif record.netId then
					local netEntity = NetworkGetEntityFromNetworkId(record.netId)

					if netEntity and DoesEntityExist(netEntity) then
						Utils.DeleteEntity(netEntity)
					end
				end
			end

			client.dropObjects[uid] = nil
		end
	end

	if client.dropObjectsByNetId then
		for netId in pairs(client.dropObjectsByNetId) do
			client.dropObjectsByNetId[netId] = nil
		end
	end

	for _, v in pairs(Items --[[@as table]]) do
        v.count = 0
    end

    Utility.clearArmor()

	PlayerData.loaded = false
	client.drops = nil

	client.closeInventory()
	Shops.wipeShops()

    if client.interval then
        ClearInterval(client.interval)
        ClearInterval(client.tick)
    end

	Weapon.Disarm()
end

local success, result = pcall(lib.load, ('modules.bridge.%s.client'):format(shared.framework))

if not success then
    lib.print.error(result)
    lib = nil
    return
end
