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

local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'
local Shops = {}
local locations = shared.target and 'targets' or 'locations'

---@class OxShopItem
---@field slot number
---@field weight number

local function setupShopItems(id, shopType, shopName, groups)
	local shop = id and Shops[shopType][id] or Shops[shopType] --[[@as OxShop]]

	for i = 1, shop.slots do
		local slot = shop.items[i]

		if slot.grade and not groups then
			slot.grade = nil
		end

		local Item = Items(slot.name)

		if Item then
			---@type OxShopItem
			slot = {
				name = Item.name,
				slot = i,
				weight = Item.weight,
				count = slot.count,
				price = (server.randomprices and (not slot.currency or slot.currency == 'money')) and
				(math.ceil(slot.price * (math.random(80, 120) / 100))) or slot.price or 0,
				metadata = slot.metadata,
				license = slot.license,
				currency = slot.currency,
				grade = slot.grade
			}

			if slot.metadata then
				slot.weight = Inventory.SlotWeight(Item, slot, true)
			end

			shop.items[i] = slot
		end
	end
end

---@param shopType string
---@param properties OxShop
local function registerShopType(shopType, properties)
	local shopLocations = properties[locations] or properties.locations

	if shopLocations then
		Shops[shopType] = properties
	else
		Shops[shopType] = {
			label = properties.name,
			id = shopType,
			groups = properties.groups or properties.jobs,
			items = properties.inventory,
			slots = #properties.inventory,
			type = 'shop',
		}

		setupShopItems(nil, shopType, properties.name, properties.groups or properties.jobs)
	end
end

---@param shopType string
---@param id number
local function createShop(shopType, id)
	local shop = Shops[shopType]

	if not shop then return end

	local store = (shop[locations] or shop.locations)?[id]

	if not store then return end

	local groups = shop.groups or shop.jobs
	local coords

	if shared.target then
		if store.length then
			local z = store.loc.z + math.abs(store.minZ - store.maxZ) / 2
			coords = vec3(store.loc.x, store.loc.y, z)
		else
			coords = store.coords or store.loc
		end
	else
		coords = store
	end

	shop[id] = {
		label = shop.name,
		id = shopType .. ' ' .. id,
		groups = groups,
		items = table.clone(shop.inventory),
		slots = #shop.inventory,
		type = 'shop',
		coords = coords,
		distance = shared.target and shop.targets?[id]?.distance,
	}

	setupShopItems(id, shopType, shop.name, groups)

	return shop[id]
end

for shopType, shopDetails in pairs(lib.load('data.shops') or {}) do
	registerShopType(shopType, shopDetails)
end

---@param shopType string
---@param shopDetails OxShop
exports('RegisterShop', function(shopType, shopDetails)
	registerShopType(shopType, shopDetails)
end)

lib.callback.register('ox_inventory:openShop', function(source, data)
	local left, shop = Inventory(source)

	if not left then return end

	if data then
		shop = Shops[data.type]

		if not shop then return end

		if not shop.items then
			shop = (data.id and shop[data.id] or createShop(data.type, data.id))

			if not shop then return end
		end

		---@cast shop OxShop

		if shop.groups then
			local group = server.hasGroup(left, shop.groups)
			if not group then return end
		end

		if type(shop.coords) == 'vector3' and #(GetEntityCoords(GetPlayerPed(source)) - shop.coords) > 10 then
			return
		end

		---@diagnostic disable-next-line: assign-type-mismatch
		left:openInventory(left)
		left.currentShop = shop.id
	end

	return { label = left.label, type = left.type, slots = left.slots, weight = left.weight, maxWeight = left.maxWeight },
		shop
end)

local normaliseCurrency = server.normaliseCurrency or function(currency)
	if type(currency) == 'string' then
		currency = currency:lower()
	else
		currency = 'money'
	end

	if currency == 'cash' then
		return 'money'
	end

	return currency
end

local function formatCurrencyLabel(currency, price)
	if server.formatCurrencyLabel then
		return server.formatCurrencyLabel(currency, price)
	end

	local normalised = normaliseCurrency(currency)

	if normalised == 'money' then
		return ('%s%s'):format(locale('$'), math.groupdigits(price))
	end

	if normalised == 'bank' then
		return ('%s %s'):format(math.groupdigits(price), locale('bank_account') or 'Bank')
	end

	local item = Items(normalised)
	local label = item and item.label or currency
	return ('%s %s'):format(math.groupdigits(price), label)
end

local function currencyParts(currency, price)
	local normalised = normaliseCurrency(currency)

	if normalised == 'money' then
		return locale('$'), math.groupdigits(price)
	end

	if normalised == 'bank' then
		return math.groupdigits(price), ' ' .. (locale('bank_account') or 'Bank')
	end

	local item = Items(normalised)
	local label = item and item.label or currency
	return math.groupdigits(price), ' ' .. label
end

local function canAffordItem(inv, currency, price)
	local balance
	print("currency: ", currency)
	balance = server.getCurrencyBalance(source, currency)

	local canAfford = price >= 0 and balance >= price

	if canAfford then
		return true
	end

	return {
		type = 'error',
		description = locale('cannot_afford', formatCurrencyLabel(currency, price))
	}
end

local function removeCurrency(inv, currency, price)
	if server.removeCurrency then
		return server.removeCurrency(source, currency, price, 'ox_inventory:shop_purchase')
	end

	return Inventory.RemoveItem(inv, normaliseCurrency(currency), price)
end

local TriggerEventHooks = require 'modules.hooks.server'

local function isRequiredGrade(grade, rank)
	if type(grade) == "table" then
		for i = 1, #grade do
			if grade[i] == rank then
				return true
			end
		end
		return false
	else
		return rank >= grade
	end
end

lib.callback.register('ox_inventory:buyItem', function(source, data)
	if data.toType == 'player' then
		if data.count == nil then data.count = 1 end

		local playerInv = Inventory(source)

		if not playerInv or not playerInv.currentShop then return end

		local shopType, shopId = playerInv.currentShop:match('^(.-) (%d-)$')

		if not shopType then shopType = playerInv.currentShop end

		if shopId then shopId = tonumber(shopId) end

		local shop = shopId and Shops[shopType][shopId] or Shops[shopType]
		local fromData = shop.items[data.fromSlot]
		local toData = playerInv.items[data.toSlot]

		if fromData then
			if fromData.count then
				if fromData.count == 0 then
					return false, false, { type = 'error', description = locale('shop_nostock') }
				elseif data.count > fromData.count then
					data.count = fromData.count
				end
			end

			if fromData.license and server.hasLicense and not server.hasLicense(playerInv, fromData.license) then
				return false, false, { type = 'error', description = locale('item_unlicensed') }
			end

			if fromData.grade then
				local _, rank = server.hasGroup(playerInv, shop.groups)
				if not isRequiredGrade(fromData.grade, rank) then
					return false, false, { type = 'error', description = locale('stash_lowgrade') }
				end
			end

			local paymentMethod = type(data.payment) == 'string' and data.payment:lower() or nil
			local currency = fromData.currency or 'money'

			if paymentMethod == 'bank' then
				if currency == 'money' or currency == 'cash' then
					currency = 'bank'
				end
			elseif paymentMethod == 'cash' then
				if currency == 'cash' then
					currency = 'money'
				end
			end

			local fromItem = Items(fromData.name)

			local result = fromItem.cb and fromItem.cb('buying', fromItem, playerInv, data.fromSlot, shop)
			if result == false then return false end

			local toItem = toData and Items(toData.name)

			local requestedCount = data.count
			local templateMetadata = fromData.metadata and table.clone(fromData.metadata) or {}
			local pricePerUnit = fromData.price or 0

			local canCarry = Inventory.CanCarryItem(playerInv, fromItem, requestedCount, templateMetadata)

			if not canCarry then
				return false, false, { type = 'error', description = locale('cannot_carry') }
			end

			local function findAvailableSlot(inv, item, meta)
				for i = 1, inv.slots do
					local s = inv.items[i]
					if s == nil then
						return i
					end

					if s.name == item.name and item.stack and table.matches(s.metadata or {}, meta or {}) then
						return i
					end
				end

				return nil
			end

			local targetSlot = data.toSlot
			local targetData = toData

			local canUseTarget = (targetData == nil) or
			(fromItem.name == toItem?.name and fromItem.stack and table.matches(targetData.metadata or {}, templateMetadata or {}))

			if not canUseTarget then
				local found = findAvailableSlot(playerInv, fromItem, templateMetadata)
				if not found then
					return false, false, { type = 'error', description = locale('unable_stack_items') }
				end

				if fromItem.stack or requestedCount == 1 then
					data.toSlot = found
					targetSlot = found
					targetData = playerInv.items[found]
				else
					data.toSlot = nil
					targetSlot = nil
					targetData = nil
				end
			end

			if targetData == nil and not fromItem.stack and requestedCount > 1 then
				data.toSlot = nil
				targetSlot = nil
				targetData = nil
			end

			local canCarry2 = Inventory.CanCarryItem(playerInv, fromItem, requestedCount, templateMetadata)

			if not canCarry2 then
				return false, false, { type = 'error', description = locale('cannot_carry') }
			end

			local estimatedTotal = (pricePerUnit or 0) * requestedCount
			local canAfford = canAffordItem(playerInv, currency, estimatedTotal)

			if canAfford ~= true then
				return false, false, canAfford
			end

			if not TriggerEventHooks('buyItem', {
					source = source,
					shopType = shopType,
					shopId = shopId,
					toInventory = playerInv.id,
					toSlot = data.toSlot,
					fromSlot = fromData,
					itemName = fromData.name,
					metadata = templateMetadata,
					count = requestedCount,
					price = pricePerUnit,
					totalPrice = pricePerUnit * requestedCount,
					currency = currency,
				}) then
				return false
			end

			if server.loglevel > 0 then
				local _, _, emptySlots = Inventory.GetItemSlots(playerInv, fromItem, templateMetadata, false)
			end

			if server.loglevel > 1 then
				local _, _, emptySlots = Inventory.GetItemSlots(playerInv, fromItem, templateMetadata, false)
			end

			local ok, resp = Inventory.AddItem(playerInv, fromItem.name, requestedCount, templateMetadata, data.toSlot)

			if server.loglevel > 0 then
				-- print(('buyItem debug: AddItem returned ok=%s resp=%s'):format(tostring(ok), type(resp) == 'table' and json.encode(resp) or tostring(resp)))
			end

			if not ok then
				local err = type(resp) == 'string' and resp or 'unable_stack_items'
				return false, false, { type = 'error', description = locale(err) }
			end

			local added = 0

			if type(resp) == 'number' then
				added = resp
			elseif type(resp) == 'table' then
				if resp.count then
					added = resp.count
				else
					for i = 1, #resp do
						added = added + (resp[i].count or 0)
					end
					if added == 0 and resp.slot then
						added = resp.count or 1
					end
				end
			end

			local totalPrice = (pricePerUnit or 0) * added

			local txnId = ('%s-%d-%d'):format(tostring(playerInv.id), os.time(), math.random(1000, 9999))
			if server.loglevel > 0 then
				-- print(("[ox_inventory][buyItem] txn=%s charge %s %s"):format(txnId, tostring(currency), tostring(totalPrice)))
			end

			local deducted = removeCurrency(playerInv, currency, totalPrice)
			if server.loglevel > 0 then
				-- print(("[ox_inventory][buyItem] txn=%s deducted=%s"):format(txnId, tostring(deducted)))
			end

			if fromData.count then
				shop.items[data.fromSlot].count = fromData.count - added
			end

			if server.syncInventory then server.syncInventory(playerInv) end

			local part1, part2 = currencyParts(currency, totalPrice)
			local message = locale('purchased_for', added, templateMetadata?.label or fromItem.label, part1, part2)

			if server.loglevel > 0 then
				if server.loglevel > 1 or fromData.price >= 500 then
					lib.logger(playerInv.owner, 'buyItem', ('"%s" %s'):format(playerInv.label, message:lower()),
						('shop:%'):format(shop.label))
				end
			end

			return true, { resp, shop.items[data.fromSlot].count and shop.items[data.fromSlot], playerInv.weight },
				{ type = 'success', description = message }
		end
	end
end)

server.shops = Shops
