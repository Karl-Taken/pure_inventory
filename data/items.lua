return {
	['testburger']           = {
		label = 'Test Burger',
		weight = 220,
		degrade = 60,
		client = {
			image = 'burger_chicken.webp',
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			export = 'ox_inventory_examples.testburger'
		},
		server = {
			export = 'ox_inventory_examples.testburger',
			test = 'what an amazingly delicious burger, amirite?'
		},
		buttons = {
			{
				label = 'Lick it',
				action = function(slot)
					print('You licked the burger')
				end
			},
			{
				label = 'Squeeze it',
				action = function(slot)
					print('You squeezed the burger :(')
				end
			},
			{
				label = 'What do you call a vegan burger?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('A misteak.')
				end
			},
			{
				label = 'What do frogs like to eat with their hamburgers?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('French flies.')
				end
			},
			{
				label = 'Why were the burger and fries running?',
				group = 'Hamburger Puns',
				action = function(slot)
					print('Because they\'re fast food.')
				end
			}
		},
		consume = 0.3
	},

	['bench_basic']          = {
		label = 'Basic Crafting Bench',
		description = 'A portable bench for basic crafting. Place it to begin crafting.',
		weight = 8000,
		stack = false,
		close = true,
		consume = 0
	},

	['bench_advanced']       = {
		label = 'Advanced Crafting Bench',
		description = 'Advanced bench capable of more complex recipes.',
		weight = 9500,
		stack = false,
		close = true,
		consume = 0
	},

	['blueprint']            = {
		label = 'blueprint',
		description = 'A detailed blueprint containing technical drawings and instructions.',
		weight = 25,
		stack = true,
		close = true,
		consume = 0,
		degrade = 60,
	},

	['bandage']              = {
		label = 'Bandage',
		weight = 115,
		rarity = 'uncommon',
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_rolled_sock_02`, pos = vec3(-0.08, 0.05, -0.05), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = false, car = false, combat = true },
			usetime = 2500,
		}
	},

	['black_money']          = {
		label = 'Dirty Money',
		modelp = 'bkr_prop_money_wrapped_01',
	},

	['cash_roll']            = {
		label = 'Cash Roll',
		modelp = 'sf_prop_sf_cash_roll_01a',
	},

	['smart_watch']          = {
		label = 'Smart Watch',
		modelp = 'p_watch_02',
	},

	['burger']               = {
		label = 'Burger',
		weight = 220,
		client = {
			status = { hunger = 200000 },
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
			notification = 'You ate a delicious burger'
		},
	},
	['soda_cup']             = {
		label = "Cup",
		weight = 10,
		modelp = `ng_proc_sodacup_01a`,
		description = "A cup to put your soda in.",
		client = {
			image = 'soda_cup.webp',
		}
	},
	['bun']                  = {
		label = "Bun",
		weight = 10,
		description = "Just your ordinary bun, go make me a sandwhich.",
		client = {
			status = { hunger = 5 },
			anim = 'eating',
			prop = 'v_ret_247_bread1',
			usetime = 2500,

			image = 'bun.webp',
		}
	},
	['raw_patty']            = {
		label = "Raw Patty",
		weight = 10,
		description = "Listen, it's still mooing. Better put it in a grill fast",
		degradee = 30,
		client = {
			image = 'raw_patty.webp',
		}
	},
	['cooked_patty']         = {
		label = "Cooked Patty",
		weight = 10,
		description = "A cooked slab of meat, eat it by itself.",
		client = {
			status = { hunger = 7 },
			image = 'cooked_patty.webp',
			anim = 'eating',
			prop = 'burger',
			usetime = 2500,
		}
	},

	['burgershot_soda_cola'] = {
		label = "Burgershot Cola",
		weight = 10,
		modelp = `ng_proc_sodacup_01a`,
		description = "Who doesn't like cola from burgershot?",
		client = {
			image = 'soda_cup.webp',
			status = { thirst = 25 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `ng_proc_sodacup_01a`, pos = vec3(0.05, 0.05, -0.15), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'You quenched your thirst with a sprunk'
		}
	},

	['sprunk']               = {
		label = 'Sprunk',
		weight = 350,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_can_01`, pos = vec3(0.01, 0.01, 0.06), rot = vec3(5.0, 5.0, -180.5) },
			usetime = 2500,
			notification = 'You quenched your thirst with a sprunk'
		}
	},

	['parachute']            = {
		label = 'Parachute',
		weight = 8000,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 1500
		}
	},

	['garbage']              = {
		label = 'Garbage',
	},

	['paper_bag']            = {
		label = 'Paper Bag',
		weight = 1000,
		stack = false,
		close = false,
		consume = 0,
		client = {
			image = 'paper_bag.webp'
		},
		modelp = 'prop_food_bs_bag_04'
	},

	['pizzabox']             = {
		label = 'Pizza Box',
		weight = 50,
		stack = false,
		close = false,
		consume = 0,
	},

	['identification']       = {
		label = 'Identification',
		client = {
			image = 'card_id.webp'
		}
	},

	['panties']              = {
		label = 'Knickers',
		weight = 10,
		consume = 0,
		client = {
			status = { thirst = -100000, stress = -25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_cs_panties_02`, pos = vec3(0.03, 0.0, 0.02), rot = vec3(0.0, -13.5, -1.5) },
			usetime = 2500,
		}
	},

	['lockpick']             = {
		label = 'Lockpick',
		weight = 160,
	},

	['phone']                = {
		label = 'Phone',
		weight = 190,
		stack = false,
		consume = 0,
		client = {
			add = function(total)
				if total > 0 then
					pcall(function() return exports.npwd:setPhoneDisabled(false) end)
				end
			end,

			remove = function(total)
				if total < 1 then
					pcall(function() return exports.npwd:setPhoneDisabled(true) end)
				end
			end
		},
		rarity = "uncommon"
	},
	-- ['money']                = {
	-- 	label = 'Money',
	-- 	modelp = 'prop_cash_pile_01',
	-- 	rarity = "legendary"
	-- },
	['casinochips']          = {
		label = 'Casino Chips',
		stack = true,
		weight = 0.5,
		description = "Casino Chips from Diamond Casino",
		close = true,
		rarity = "legendary",

	},
	['casino_member']        = {
		label = 'Casino Member',
		stack = true,
		weight = 0.5,
		description = "Casino Membership Card From Diamond Casino",
		close = true,
		rarity = "legendary",
	},
	['mustard']              = {
		label = 'Mustard',
		weight = 500,
		client = {
			status = { hunger = 25000, thirst = 25000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_food_mustard`, pos = vec3(0.01, 0.0, -0.07), rot = vec3(1.0, 1.0, -1.5) },
			usetime = 2500,
			notification = 'You.. drank mustard'
		}
	},
	['water']                = {
		label = 'Water',
		weight = 500,
		client = {
			status = { thirst = 200000 },
			anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
			prop = { model = `prop_ld_flow_bottle`, pos = vec3(0.03, 0.03, 0.02), rot = vec3(0.0, 0.0, -1.5) },
			usetime = 2500,
			cancel = true,
			notification = 'You drank some refreshing water'
		}
	},

	['pistol_ammo']          = {
		label = 'Pistol Ammo Box',
		weight = 750,
		stack = true,
		close = true,
		consume = 1,
		description = 'A boxed stack of pistol rounds. Unbox it to add 30 pistol reserve ammo.',
		ammoPool = 'pistol',
		ammoAmount = 30,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_ld_ammo_pack_01`, pos = vec3(-0.08, 0.05, -0.05), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = false, sprint = false, car = false, combat = true },
			usetime = 10000,
			cancel = true,
		}
	},


	['rifle_ammo']           = {
		label = 'Rifle Ammo Box',
		weight = 1000,
		stack = true,
		close = true,
		consume = 1,
		description = 'A boxed stack of rifle rounds. Unbox it to add 30 rifle reserve ammo.',
		ammoPool = 'rifle',
		ammoAmount = 30,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `prop_ld_ammo_pack_03`, pos = vec3(-0.08, 0.05, -0.05), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = false, sprint = false, car = false, combat = true },
			usetime = 10000,
			cancel = true,
		}
	},

	['smg_ammo']             = {
		label = 'SMG Ammo Box',
		weight = 900,
		stack = true,
		close = true,
		consume = 1,
		description = 'A boxed stack of SMG rounds. Unbox it to add 30 SMG reserve ammo.',
		ammoPool = 'smg',
		ammoAmount = 30,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `v_ret_gc_ammo3`, pos = vec3(-0.08, 0.05, -0.05), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = false, sprint = false, car = false, combat = true },
			usetime = 10000,
			cancel = true,
		}
	},

	['shotgun_ammo']         = {
		label = 'Shotgun Ammo Box',
		weight = 1000,
		stack = true,
		close = true,
		consume = 1,
		description = 'A boxed stack of shotgun shells. Unbox it to add 16 shotgun reserve ammo.',
		ammoPool = 'shotgun',
		ammoAmount = 16,
		client = {
			anim = { dict = 'missheistdockssetup1clipboard@idle_a', clip = 'idle_a', flag = 49 },
			prop = { model = `v_ret_gc_ammo3`, pos = vec3(-0.08, 0.05, -0.05), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = false, sprint = false, car = false, combat = true },
			usetime = 10000,
			cancel = true,
		}
	},

	['radio']                = {
		label = 'Radio',
		weight = 1000,
		stack = false,
		allowArmed = true
	},

	['armour']               = {
		label = 'Bulletproof Vest',
		weight = 3000,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500
		}
	},

	['heavyarmour']          = {
		label = 'Heavy Armor',
		weight = 4500,
		stack = false,
		client = {
			anim = { dict = 'clothingshirt', clip = 'try_shirt_positive_d' },
			usetime = 3500
		},

	},

	['armor_plates']         = {
		label = 'Armour Plate',
		weight = 800,
		stack = true,
		close = true,
		client = {
			event = 'ox_inventory:utility:applyArmorPlate'
		}
	},

	['improved_armor_plate'] = {
		label = 'Improved Armour Plate',
		weight = 1000,
		stack = true,
		close = true,
		client = {
			event = 'ox_inventory:utility:applyArmorPlate'
		}
	},

	['armor_repair_kit']     = {
		label = 'Armor Repair Kit',
		weight = 1200,
		stack = true,
		close = true,
		client = {
			event = 'ox_inventory:utility:applyArmorPlate'
		}
	},
	['advancedkit']          = {
		label = 'Advanced Repair Kit',
		weight = 1000,
		stack = true,
		close = true,
	},
	['clothing']             = {
		label = 'Clothing',
		consume = 0,
	},

	['mastercard']           = {
		label = 'Fleeca Card',
		stack = false,
		weight = 10,
		client = {
			image = 'card_bank.webp'
		}
	},

	['scrapmetal']           = {
		label = 'Scrap Metal',
		weight = 80,
	},

	["washing_machine"]      = {
		label = "Washing Machine",
		weight = 2500,
		stack = false,
		close = true,
		description = "A portable washer you can place.",
		client = { image = "washing_machine.webp" },
		server = { export = 'laundry-test.useWasher' }
	},

	["fan"]                  = {
		label = "Cooling Fan",
		weight = 800,
		stack = false,
		close = true,
		description = "Keeps things cool while processing.",
		client = { image = "fan.webp" },
		server = { export = 'laundry-test.useFan' }

	},

	["basket"]               = {
		label = "Laundry Basket",
		weight = 500,
		stack = false,
		close = true,
		description = "Carry and sort laundry with style.",
		client = { image = "basket.webp" },
		server = { export = 'laundry-test.usePanel' }
	},

	["generator"]            = {
		label = "Power Generator",
		weight = 3500,
		stack = false,
		close = true,
		description = "Portable power for your setup.",
		client = { image = "generator.webp" },
		server = { export = 'laundry-test.useGenerator' }
	},


	["backpack_small"] = {
		label = "Small Backpack",
		weight = 500,
		stack = false,
		close = false,
		description = "A small backpack for carrying extra items.",
		client = { image = "backpack_small.webp" }
	},

	["backpack_medium"] = {
		label = "Medium Backpack",
		weight = 750,
		stack = false,
		close = false,
		description = "A medium backpack for carrying more items.",
		client = { image = "backpack_medium.webp" },
		rarity = "common"
	},

	["backpack_large"] = {
		label = "Large Backpack",
		weight = 1000,
		stack = false,
		close = false,
		description = "A large backpack for carrying many items.",
		client = { image = "backpack_large.webp" },
		rarity = "common"
	},


	['fishing_rod'] = {
		label = 'Fishing Rod',
		weight = 1500,
		stack = false,
		modelp = 'prop_fishing_rod_01',
		client = {
			image = 'fishing_rod.webp'
		}
	},

	-- MINING

	['aluminium_ore'] = {
		label = 'Aluminium Ore',
		weight = 5000,
		rarity = "common",
		client = {
			image = "aluminium_ore.webp"
		}
	},

	['basic_looking_ore'] = {
		label = 'Basic Looking Ore',
		weight = 5000,
		rarity = "common",
		client = {
			image = "basic_looking.webp"
		}
	},

	['copper_ore'] = {
		label = 'Copper Ore',
		weight = 5000,
		rarity = "common",
		client = {
			image = "copper_ore.webp"
		}
	},

	['coal_ore'] = {
		label = 'Coal Ore',
		weight = 5000,
		rarity = "common",
		client = {
			image = "coal.webp"
		}
	},

	['diamond_ore'] = {
		label = 'Diamond Ore',
		weight = 5000,
		rarity = "rare",
		client = {
			image = "diamond_ore.webp"
		}
	},

	['iron_ore'] = {
		label = 'Iron Ore',
		weight = 5000,
		rarity = "rare",
		client = {
			image = "iron_ore.webp"
		}
	},

	['lithium_ore'] = {
		label = 'Lithium Ore',
		weight = 5000,
		rarity = "uncommon",
		client = {
			image = "lithium_ore.webp"
		}
	},

	['magnesium_ore'] = {
		label = 'Magnesium Ore',
		weight = 5000,
		rarity = "uncommon",
		client = {
			image = "lithium_ore.webp"
		}
	},

	['silver_ore'] = {
		label = 'Silver Ore',
		weight = 5000,
		rarity = "rare",
		client = {
			image = "silver.webp"
		}
	},

	['gold_ore'] = {
		label = 'Gold Ore',
		weight = 5000,
		rarity = "rare",
		client = {
			image = "gold_ore.webp"
		}
	},

	['gem_ore'] = {
		label = 'Gem Ore',
		weight = 5000,
		rarity = "uncommon",
		client = {
			image = "gem_ore.webp"
		}
	},

	['zinc_ore'] = {
		label = 'Zinc Ore',
		weight = 5000,
		rarity = "common",
		client = {
			image = "zinc_ore.webp"
		}
	},

	['limestone_ore'] = {
		label = 'Limestone Ore',
		weight = 5000,
		rarity = "common",
		client = {
			image = "limestone_ore.webp"
		}
	},

	['nickel_ore'] = {
		label = 'Nickel Ore',
		weight = 5000,
		rarity = "common",
		client = {
			image = "nickel_ore.webp"
		}
	},

	['copper'] = {
		label = 'Copper',
		weight = 250,
		rarity = "common",
		client = {
			image = "copper.webp"
		}
	},

	['diamond'] = {
		label = 'Diamond',
		weight = 500,
		rarity = "epic",
		client = {
			image = "copper.webp"
		}
	},

	['emerald'] = {
		label = 'Emerald',
		weight = 400,
		rarity = "rare",
		client = {
			image = "emerald_gem.webp"
		}
	},

	['gem'] = {
		label = 'Gem',
		weight = 250,
		rarity = "uncommon",
		client = {
			image = "gem.webp"
		}
	},

	['gold'] = {
		label = 'Gold Nugget',
		weight = 150,
		rarity = "uncommon",
		client = {
			image = "gold.webp"
		}
	},

	['iron'] = {
		label = 'Iron',
		weight = 400,
		rarity = "uncommon",
		client = {
			image = "iron.webp"
		}
	},

	['limestone'] = {
		label = 'Limestone',
		weight = 500,
		rarity = "common",
		client = {
			image = "limestone.webp"
		}
	},

	['lithium'] = {
		label = 'Lithium',
		weight = 400,
		client = {
			image = "lithium.webp"
		}
	},

	['magnesium'] = {
		label = 'Magnesium',
		weight = 350,
		client = {
			image = "magnesium.webp"
		}
	},

	['nickel'] = {
		label = 'Nickel',
		weight = 400,
		client = {
			image = "nickel.webp"
		}
	},

	['ruby'] = {
		label = 'Ruby',
		weight = 500,
		client = {
			image = "ruby_gem.webp"
		}
	},

	['sapphire'] = {
		label = 'Sapphire',
		weight = 500,
		client = {
			image = "sapphire_gem.webp"
		}
	},

	['topaz'] = {
		label = 'Topaz',
		weight = 500,
		client = {
			image = "topaz_gem.webp"
		}
	},

	['iron_ingot'] = {
		label = 'Iron Ingot',
		weight = 300,
		client = {
			image = "iron.webp"
		}
	},

	['silver_ingot'] = {
		label = 'Silver Ingot',
		weight = 400,
		client = {
			image = "silver.webp"
		}
	},


	-- END OF MINING

	['frenchfries'] = {
		label = 'French Fries',
		weight = 10,
		stack = true,
		close = true,
		description = 'A plate of crispy, golden-brown french fries.'
	},

	['frenchfriesbag'] = {
		label = 'French Fries Bag',
		weight = 10,
		stack = true,
		close = true,
		description = 'Fresh french fries ready for frying.'
	},

	['burntfrenchfries'] = {
		label = 'Burnt French Fries',
		weight = 10,
		stack = true,
		close = true,
		description = 'A plate of burnt, black french fries.'
	},

	['rawburgerpatty'] = {
		label = 'Raw Burger Patty',
		weight = 10,
		stack = true,
		close = true,
		description = 'Fresh beef patty for grilling.'
	},

	['cookedburgerpatty'] = {
		label = 'Cooked Burger Patty',
		weight = 10,
		stack = true,
		close = true,
		description = 'A cooked burger patty.'
	},

	['restaurant_ticket'] = {
		label = 'Restaurant Ticket',
		weight = 0,
		stack = false,
		close = true,
		description = 'A receipt from a restaurant order.'
	},

	['cheese'] = {
		label = 'Cheese',
		weight = 10,
		stack = true,
		close = true,
		description = 'Cheese slices for burgers.'
	},

	['lettuce'] = {
		label = 'Lettuce',
		weight = 10,
		stack = true,
		close = true,
		description = 'Fresh lettuce leaves.'
	},

	['tomato'] = {
		label = 'Tomato',
		weight = 10,
		stack = true,
		close = true,
		description = 'Fresh tomato slices.'
	},

	['onion'] = {
		label = 'Onion',
		weight = 10,
		stack = true,
		close = true,
		description = 'Fresh onion slices.'
	},

	['avocado'] = {
		label = 'Avocado',
		weight = 10,
		stack = true,
		close = true,
		description = 'Fresh avocado slices.'
	},

	['texmex_sauce'] = {
		label = 'TexMex Sauce',
		weight = 10,
		stack = true,
		close = true,
		description = 'Spicy TexMex sauce.'
	},

	['burgerbun'] = {
		label = 'Burger Bun',
		weight = 10,
		stack = true,
		close = true,
		description = 'Fresh burger buns.'
	},

	['fish_filet'] = {
		label = 'Fish Filet',
		weight = 10,
		stack = true,
		close = true,
		description = 'Fresh fish filet.'
	},

	['beaten_egg'] = {
		label = 'Beaten Egg',
		weight = 10,
		stack = true,
		close = true,
		description = 'Beaten egg for cooking.'
	},
	['double_cheese_burger'] = {
		label = 'Double Cheese Burger',
		weight = 15,
		stack = true,
		close = true,
		description = 'A delicious double cheese burger.'
	},

	['cheese_burger'] = {
		label = 'Cheese Burger',
		weight = 12,
		stack = true,
		close = true,
		description = 'A classic cheese burger.'
	},

	['pizza_pepperoni'] = {
		label = 'Pepperoni Pizza',
		weight = 20,
		stack = true,
		close = true,
		description = 'Delicious pepperoni pizza.'
	},

	['pizza_mushroom'] = {
		label = 'Mushroom Pizza',
		weight = 20,
		stack = true,
		close = true,
		description = 'Fresh mushroom pizza.'
	},
	['mojito'] = {
		label = 'Mojito',
		weight = 8,
		stack = true,
		close = true,
		description = 'Refreshing mojito cocktail.'
	},

	['cola'] = {
		label = 'Cola',
		weight = 8,
		stack = true,
		close = true,
		description = 'Classic cola drink.'
	},

	['juice'] = {
		label = 'Juice',
		weight = 8,
		stack = true,
		close = true,
		description = 'Fresh fruit juice.'
	},

	['sunday'] = {
		label = 'Sunday',
		weight = 10,
		stack = true,
		close = true,
		description = 'Delicious sunday dessert.'
	},

	['sprite'] = {
		label = 'Sprite',
		weight = 8,
		stack = true,
		close = true,
		description = 'Refreshing sprite drink.'
	},

	['coffee_cup'] = {
		label = 'Coffee Cup',
		weight = 8,
		stack = true,
		close = true,
		description = 'Hot coffee in a cup.'
	},
	['mayonnaise'] = {
		label = 'Mayonnaise',
		weight = 5,
		stack = true,
		close = true,
		description = 'Creamy mayonnaise sauce.'
	},

	['ketchup'] = {
		label = 'Ketchup',
		weight = 5,
		stack = true,
		close = true,
		description = 'Ketchup is a condiment made from tomatoes and vinegar.'
	},

	['french_fries'] = {
		label = 'French Fries',
		weight = 8,
		stack = true,
		close = true,
		description = 'Crispy golden french fries, a classic side dish.'
	},

	['cooking_oil'] = {
		label = 'Cooking Oil',
		weight = 15,
		stack = true,
		close = true,
		description = 'High-quality cooking oil for frying.'
	},

	['chicken_nuggets_raw'] = {
		label = 'Chicken Nuggets Raw',
		weight = 10,
		stack = true,
		close = true,
		description = 'Crispy chicken nuggets.'
	},

	['chicken_nuggets'] = {
		label = 'Chicken Nuggets',
		weight = 10,
		stack = true,
		close = true,
		description = 'Crispy chicken nuggets.'
	},

	['cola_syrup'] = {
		label = 'Cola Syrup',
		weight = 10,
		stack = true,
		close = true,
		description = 'Cola Syrup'
	},

	['sprite_syrup'] = {
		label = 'Sprite Syrup',
		weight = 10,
		stack = true,
		close = true,
		description = 'Sprite Syrup'
	},

	['orange_concentrate'] = {
		label = 'Orange Concentrate',
		weight = 10,
		stack = true,
		close = true,
		description = 'Orange Concentrate'
	},

	['carbonation'] = {
		label = 'Carbonation',
		weight = 10,
		stack = true,
		close = true,
		description = 'Carbonation'
	},

	['orange_juice'] = {
		label = 'Orange Juice',
		weight = 10,
		stack = true,
		close = true,
		description = 'Orange Juice'
	},

	['coffee_beans'] = {
		label = 'Coffee Beans',
		weight = 10,
		stack = true,
		close = true,
		description = 'Coffee Beans'
	},

	['milk'] = {
		label = 'Milk',
		weight = 10,
		stack = true,
		close = true,
		description = 'Milk'
	},

	['foam_powder'] = {
		label = 'Foam Powder',
		weight = 10,
		stack = true,
		close = true,
		description = 'Foam Powder'
	},

	['coffee_black'] = {
		label = 'Coffee Black',
		weight = 10,
		stack = true,
		close = true,
		description = 'Coffee Black'
	},

	['coffee_latte'] = {
		label = 'Coffee Latte',
		weight = 10,
		stack = true,
		close = true,
		description = 'Coffee Latte'
	},

	['coffee_cappuccino'] = {
		label = 'Coffee Cappuccino',
		weight = 10,
		stack = true,
		close = true,
		description = 'Coffee Cappuccino'
	},

	['ramune_syrup'] = {
		label = 'Ramune syrup',
		weight = 10,
		stack = true,
		close = true,
		description = 'Ramune syrup'
	},

	['oolong_leaves'] = {
		label = 'Oolong leaves',
		weight = 10,
		stack = true,
		close = true,
		description = 'Oolong leaves'
	},

	['tea_leaves'] = {
		label = 'Tea leaves',
		weight = 10,
		stack = true,
		close = true,
		description = 'Tea leaves'
	},

	["shield"] = {
		label = "Police shield",
		weight = 8000,
		stack = false,
		consume = 0,
		client = {
			export = "ND_Police.useShield",
			add = function(total)
				if total > 0 then
					pcall(function() return exports["ND_Police"]:hasShield(true) end)
				end
			end,
			remove = function(total)
				if total < 1 then
					pcall(function() return exports["ND_Police"]:hasShield(false) end)
				end
			end
		}
	},

	["spikestrip"] = {
		label = "Spikestrip",
		weight = 500,
		client = {
			export = "ND_Police.deploySpikestrip"
		}
	},

	["cuffs"] = {
		label = "Handcuffs",
		weight = 150,
		client = {
			export = "ND_Police.cuff"
		}
	},

	["zipties"] = {
		label = "Zipties",
		weight = 10,
		client = {
			export = "ND_Police.ziptie"
		}
	},

	["tools"] = {
		label = "Tools",
		description = "Can be used to hotwire vehicles.",
		weight = 800,
		consume = 1,
		stack = true,
		close = true,
		client = {
			export = "ND_Core.hotwire",
			event = "ND_Police:unziptie"
		}
	},

	["handcuffkey"] = {
		label = "Handcuff key",
		weight = 10,
		client = {
			export = "ND_Police.uncuff"
		}
	},

	["casing"] = {
		label = "Bullet Casing"
	},

	["projectile"] = {
		label = "Projectile"
	},

	['atmbag'] = {
		label = 'Small Money Bag',
		weight = 1000,
		stack = false,
		close = true,
		description = "A compact bag used to store small amounts of cash.",
	},

	['bankbag'] = {
		label = 'Large Money Bag',
		weight = 3000,
		stack = false,
		close = true,
		description = "A heavy-duty bag designed to carry large sums of money.",
	},

	['privatecrate'] = {
		label = 'Large Locked Crate',
		weight = 5000,
		stack = false,
		close = true,
		description = "A secured crate used for transporting valuable goods.",
	},

	['thermite'] = {
		label = 'Thermite Charge',
		weight = 5000,
		stack = false,
		close = true,
		description = "An industrial-grade charge used to breach reinforced locks.",
	},
	["defib"] = {
		label = "Monitor/defibrillator",
		weight = 8000,
		stack = false,
		consume = 1,
		client = {
			export = "ND_Ambulance.useDefib",
			add = function(total)
				if total > 0 then
					pcall(function()
						return exports["ND_Ambulance"]:hasDefib(true)
					end)
				end
			end,
			remove = function(total)
				if total < 1 then
					pcall(function()
						return exports["ND_Ambulance"]:hasDefib(false)
					end)
				end
			end
		}
	},
	["medbag"] = {
		label = "Trauma bag",
		weight = 1000,
		stack = false,
		consume = 1,
		server = {
			export = "pure_ambulance.useBag"
		},
		client = {
			export = "pure_ambulance.useBag",
			add = function(total)
				if total > 0 then
					pcall(function()
						return exports["pure_amnbulance"]:bag(true)
					end)
				end
			end,
			remove = function(total)
				if total < 1 then
					pcall(function()
						return exports["pure_amnbulance"]:bag(false)
					end)
				end
			end
		}
	},
	["burndressing"] = {
		label = "Burn Dressing",
		weight = 50,
		server = {
			export = "pure_ambulance.treatment"
		},
		client = {
			anim = { dict = "missheistdockssetup1clipboard@idle_a", clip = "idle_a", flag = 49 },
			prop = { model = `prop_toilet_roll_01`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = false, car = false, combat = true },
			usetime = 2500
		}
	},
	["splint"] = {
		label = "Splint",
		weight = 500,
		server = {
			export = "pure_ambulance.treatment"
		},
		client = {
			anim = { dict = "missheistdockssetup1clipboard@idle_a", clip = "idle_a", flag = 49 },
			prop = { model = `prop_toilet_roll_01`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = false, car = false, combat = true },
			usetime = 2500
		}
	},
	["gauze"] = {
		label = "Gauze",
		weight = 80,
		allowArmed = true,
		server = {
			export = "pure_ambulance.treatment"
		},
		client = {
			anim = { dict = "missheistdockssetup1clipboard@idle_a", clip = "idle_a", flag = 49 },
			prop = { model = `prop_toilet_roll_01`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = false, car = false, combat = true },
			usetime = 2500
		}
	},
	["tourniquet"] = {
		label = "Tourniquet",
		weight = 85,
		server = {
			export = "pure_ambulance.treatment"
		},
		client = {
			anim = { dict = "missheistdockssetup1clipboard@idle_a", clip = "idle_a", flag = 49 },
			prop = { model = `prop_rolled_sock_02`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = false, car = false, combat = true },
			usetime = 2500
		}
	},

	-- Pressure Wash
	["pressurewash"] = {
		label = "Pressure Wash Generator",
		weight = 5000,
		stack = false
	},
	-- Refill consumables
	["petrolcan"] = {
		label = "Petrol Can",
		weight = 1000,
		stack = false,
	},
	["watercanister"] = {
		label = "Water Canister",
		weight = 1000,
		stack = false,
	},

	-- POLICE Utils
	-- Spike strips
	["spikesbox"] = {
		label = "Spike Strip Box",
		weight = 2000,
		stack = false
	},
	["spikebox_pilot"] = {
		label = "Spike Strip Remote",
		weight = 200,
		stack = false
	},
	-- GPS trackers
	["placeable_gps"] = {
		label = "GPS Tracker",
		weight = 100,
		stack = false
	},
	["shootable_gps"] = {
		label = "GPS Tracker (Shootable)",
		weight = 50,
		stack = true,
	},

	-- FISHING
	["basic_fishing_rod"] = {
		label = "Basic Fishing Rod",
		weight = 800
	},
	["sport_fishing_rod"] = {
		label = "Sport Fishing Rod",
		weight = 1000
	},
	["professional_fishing_rod"] = {
		label = "Professional Fishing Rod",
		weight = 1200
	},
	["prodigy_fishing_rod"] = {
		label = "Fishing Rod",
		weight = 1400,
	},
	["aqua_fishing_rod"] = {
		label = "Aqua Fishing Rod",
		weight = 1500,
		closeUi = true
	},
	["sunset_fishing_rod"] = {
		label = "Sunset Fishing Rod",
		weight = 1500
	},
	["golden_fishing_rod"] = {
		label = "Golden Fishing Rod",
		weight = 1500
	},

	-- Bait
	["fishing_bait_worm"] = {
		label = "Worm Bait",
		weight = 10,
	},
	["fishing_bait_lugworm"] = {
		label = "Lugworm Bait",
		weight = 10,
	},
	["fishing_bait_radiated"] = {
		label = "Radiated Bait",
		weight = 10,
	},

	["small_bullhead"] = {
		label = "Bullhead",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_bullhead"] = {
		label = "Bullhead",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_bullhead"] = {
		label = "Bullhead",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_carp"] = {
		label = "Carp",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_carp"] = {
		label = "Carp",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_carp"] = {
		label = "Carp",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_catfish"] = {
		label = "Catfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_catfish"] = {
		label = "Catfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_catfish"] = {
		label = "Catfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_perch"] = {
		label = "Perch",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_perch"] = {
		label = "Perch",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_perch"] = {
		label = "Perch",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_rainbow_trout"] = {
		label = "Rainbow Trout",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_rainbow_trout"] = {
		label = "Rainbow Trout",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_rainbow_trout"] = {
		label = "Rainbow Trout",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_northern_pike"] = {
		label = "Northern Pike",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_northern_pike"] = {
		label = "Northern Pike",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_northern_pike"] = {
		label = "Northern Pike",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},

	-- Saltwater Fish
	["small_atlantic_croaker"] = {
		label = "Atlantic Croaker",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_atlantic_croaker"] = {
		label = "Atlantic Croaker",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_atlantic_croaker"] = {
		label = "Atlantic Croaker",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_atlantic_mackerel"] = {
		label = "Atlantic Mackerel",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_atlantic_mackerel"] = {
		label = "Atlantic Mackerel",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_atlantic_mackerel"] = {
		label = "Atlantic Mackerel",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_flounder"] = {
		label = "Flounder",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_flounder"] = {
		label = "Flounder",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_flounder"] = {
		label = "Flounder",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_red_mullet"] = {
		label = "Red Mullet",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_red_mullet"] = {
		label = "Red Mullet",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_red_mullet"] = {
		label = "Red Mullet",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_sardine"] = {
		label = "Sardine",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_sardine"] = {
		label = "Sardine",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_sardine"] = {
		label = "Sardine",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_red_snapper"] = {
		label = "Red Snapper",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_red_snapper"] = {
		label = "Red Snapper",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_red_snapper"] = {
		label = "Red Snapper",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_salmon"] = {
		label = "Salmon",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_salmon"] = {
		label = "Salmon",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_salmon"] = {
		label = "Salmon",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_striped_bass"] = {
		label = "Striped Bass",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_striped_bass"] = {
		label = "Striped Bass",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_striped_bass"] = {
		label = "Striped Bass",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_tuna"] = {
		label = "Tuna",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_tuna"] = {
		label = "Tuna",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_tuna"] = {
		label = "Tuna",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_breamfish"] = {
		label = "Bream Fish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_breamfish"] = {
		label = "Bream Fish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_breamfish"] = {
		label = "Bream Fish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_hake"] = {
		label = "Hake",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_hake"] = {
		label = "Hake",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_hake"] = {
		label = "Hake",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_barracuda"] = {
		label = "Barracuda",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_barracuda"] = {
		label = "Barracuda",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_barracuda"] = {
		label = "Barracuda",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_coralgrouper"] = {
		label = "Coral Grouper",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_coralgrouper"] = {
		label = "Coral Grouper",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_coralgrouper"] = {
		label = "Coral Grouper",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_drumfish"] = {
		label = "Drum Fish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_drumfish"] = {
		label = "Drum Fish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_drumfish"] = {
		label = "Drum Fish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},

	-- Jellyfish
	["small_jellyfish"] = {
		label = "Blue Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_jellyfish"] = {
		label = "Blue Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_jellyfish"] = {
		label = "Blue Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_jellyfish_orange"] = {
		label = "Orange Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_jellyfish_orange"] = {
		label = "Orange Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_jellyfish_orange"] = {
		label = "Orange Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_jellyfish_red"] = {
		label = "Red Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_jellyfish_red"] = {
		label = "Red Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_jellyfish_red"] = {
		label = "Red Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_jellyfish_green"] = {
		label = "Green Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_jellyfish_green"] = {
		label = "Green Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_jellyfish_green"] = {
		label = "Green Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_jellyfish_pink"] = {
		label = "Pink Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_jellyfish_pink"] = {
		label = "Pink Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_jellyfish_pink"] = {
		label = "Pink Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_jellyfish_purple"] = {
		label = "Purple Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_jellyfish_purple"] = {
		label = "Purple Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_jellyfish_purple"] = {
		label = "Purple Jellyfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_jellyfish_rainbow"] = {
		label = "Rainbow Jellyfish",
		weight = 300,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_jellyfish_rainbow"] = {
		label = "Rainbow Jellyfish",
		weight = 300,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_jellyfish_rainbow"] = {
		label = "Rainbow Jellyfish",
		weight = 300,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},

	-- Golden Fish
	["small_golden_fish"] = {
		label = "Golden Fish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_golden_fish"] = {
		label = "Golden Fish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_golden_fish"] = {
		label = "Golden Fish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},

	-- Radiated Fish
	["small_atlantic_croaker_rad"] = {
		label = "Radiated Atlantic Croaker",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_atlantic_croaker_rad"] = {
		label = "Radiated Atlantic Croaker",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_atlantic_croaker_rad"] = {
		label = "Radiated Atlantic Croaker",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_barracuda_rad"] = {
		label = "Radiated Barracuda",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_barracuda_rad"] = {
		label = "Radiated Barracuda",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_barracuda_rad"] = {
		label = "Radiated Barracuda",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_breamfish_rad"] = {
		label = "Radiated Breamfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_breamfish_rad"] = {
		label = "Radiated Breamfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_breamfish_rad"] = {
		label = "Radiated Breamfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_bullhead_rad"] = {
		label = "Radiated Bullhead",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_bullhead_rad"] = {
		label = "Radiated Bullhead",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_bullhead_rad"] = {
		label = "Radiated Bullhead",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_carp_rad"] = {
		label = "Radiated Carp",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_carp_rad"] = {
		label = "Radiated Carp",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_carp_rad"] = {
		label = "Radiated Carp",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_catfish_rad"] = {
		label = "Radiated Catfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_catfish_rad"] = {
		label = "Radiated Catfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_catfish_rad"] = {
		label = "Radiated Catfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_coralgrouper_rad"] = {
		label = "Radiated Coral Grouper",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_coralgrouper_rad"] = {
		label = "Radiated Coral Grouper",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_coralgrouper_rad"] = {
		label = "Radiated Coral Grouper",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_drumfish_rad"] = {
		label = "Radiated Drumfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_drumfish_rad"] = {
		label = "Radiated Drumfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_drumfish_rad"] = {
		label = "Radiated Drumfish",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_flounder_rad"] = {
		label = "Radiated Flounder",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_flounder_rad"] = {
		label = "Radiated Flounder",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_flounder_rad"] = {
		label = "Radiated Flounder",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_hake_rad"] = {
		label = "Radiated Hake",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_hake_rad"] = {
		label = "Radiated Hake",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_hake_rad"] = {
		label = "Radiated Hake",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_northern_pike_rad"] = {
		label = "Radiated Northern Pike",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_northern_pike_rad"] = {
		label = "Radiated Northern Pike",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_northern_pike_rad"] = {
		label = "Radiated Northern Pike",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_perch_rad"] = {
		label = "Radiated Perch",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_perch_rad"] = {
		label = "Radiated Perch",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_perch_rad"] = {
		label = "Radiated Perch",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_rainbow_trout_rad"] = {
		label = "Radiated Rainbow Trout",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_rainbow_trout_rad"] = {
		label = "Radiated Rainbow Trout",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_rainbow_trout_rad"] = {
		label = "Radiated Rainbow Trout",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_red_mullet_rad"] = {
		label = "Radiated Red Mullet",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_red_mullet_rad"] = {
		label = "Radiated Red Mullet",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_red_mullet_rad"] = {
		label = "Radiated Red Mullet",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_red_snapper_rad"] = {
		label = "Radiated Red Snapper",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_red_snapper_rad"] = {
		label = "Radiated Red Snapper",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_red_snapper_rad"] = {
		label = "Radiated Red Snapper",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_salmon_rad"] = {
		label = "Radiated Salmon",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_salmon_rad"] = {
		label = "Radiated Salmon",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_salmon_rad"] = {
		label = "Radiated Salmon",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_sardine_rad"] = {
		label = "Radiated Sardine",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_sardine_rad"] = {
		label = "Radiated Sardine",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_sardine_rad"] = {
		label = "Radiated Sardine",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_striped_bass_rad"] = {
		label = "Radiated Striped Bass",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_striped_bass_rad"] = {
		label = "Radiated Striped Bass",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_striped_bass_rad"] = {
		label = "Radiated Striped Bass",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["small_tuna_rad"] = {
		label = "Radiated Tuna",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["medium_tuna_rad"] = {
		label = "Radiated Tuna",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},
	["large_tuna_rad"] = {
		label = "Radiated Tuna",
		weight = 225,
		buttons = {
			{
				label = "Cut Fish",
				action = function(slot)
					TriggerServerEvent("prp-fishing:server:cutFish", slot)
				end,
			}
		}
	},

	-- Fishing misc
	["fishing_boot"] = {
		label = "Fishing Boot",
		weight = 1000
	},

	["fish_meat"] = {
		label = "Fish Meat",
		weight = 100
	},

	-- Fishing Trophies
	["pr_trophy_fish_january"] = {
		label = "Fishing Trophy (January)",
		weight = 2000,
	},
	["pr_trophy_fish_february"] = {
		label = "Fishing Trophy (February)",
		weight = 2000,
	},
	["pr_trophy_fish_march"] = {
		label = "Fishing Trophy (March)",
		weight = 2000,
	},
	["pr_trophy_fish_april"] = {
		label = "Fishing Trophy (April)",
		weight = 2000,
	},
	["pr_trophy_fish_may"] = {
		label = "Fishing Trophy (May)",
		weight = 2000,
	},
	["pr_trophy_fish_june"] = {
		label = "Fishing Trophy (June)",
		weight = 2000,
	},
	["pr_trophy_fish_july"] = {
		label = "Fishing Trophy (July)",
		weight = 2000,
	},
	["pr_trophy_fish_august"] = {
		label = "Fishing Trophy (August)",
		weight = 2000,
	},
	["pr_trophy_fish_september"] = {
		label = "Fishing Trophy (September)",
		weight = 2000,
	},
	["pr_trophy_fish_october"] = {
		label = "Fishing Trophy (October)",
		weight = 2000,
	},
	["pr_trophy_fish_november"] = {
		label = "Fishing Trophy (November)",
		weight = 2000,
	},
	["pr_trophy_fish_december"] = {
		label = "Fishing Trophy (December)",
		weight = 2000,
	},

	-- Drug Farming
	["drugs_pot_small"] = {
		label = "Small Drug Pot",
		stack = false,
		weight = 1000
	},
	["drugs_pot_medium"] = {
		label = "Medium Drug Pot",
		stack = false,
		weight = 2000
	},
	["drugs_pot_large"] = {
		label = "Large Drug Pot",
		stack = false,
		weight = 3000
	},

	-- Drug Farming Tools
	["farm_water_can"] = {
		label = "Watering Can",
		stack = false,
		weight = 500
	},
	["farm_fertilizer"] = {
		label = "Fertilizer",
		stack = false,
		weight = 1000,
	},

	-- Drug Farming Seeds
	["seeds_weed_1a"] = {
		label = "Regular Grape Ape Seed",
		weight = 100
	},
	["seeds_weed_1b"] = {
		label = "Cherry Kush Seed",
		weight = 100
	},
	["seeds_weed_2a"] = {
		label = "Martian Candy Seed",
		weight = 100
	},
	["seeds_weed_2b"] = {
		label = "Exodus Seed",
		weight = 100
	},
	["seeds_weed_2c"] = {
		label = "Headband Seed",
		weight = 100
	},
	["seeds_cocaine"] = {
		label = "Cocaine Seeds",
		weight = 100
	},

	-- Drug Farming Crops
	["weed_1a"] = {
		label = "Crop of Regular Grape Ape",
		weight = 100
	},
	["weed_1b"] = {
		label = "Crop of Cherry Kush",
		weight = 100
	},
	["weed_2a"] = {
		label = "Crop of Martian Candy",
		weight = 100
	},
	["weed_2b"] = {
		label = "Crop of Exodus",
		weight = 100
	},
	["weed_2c"] = {
		label = "Crop of Headband",
		weight = 100
	},
	-- Weed
	["rolling_paper"] = {
		label = "Rolling Paper",
		weight = 0,
	},
	["joint_1a"] = {
		label = "(Joint) Regular Grape Ape",
		weight = 200
	},
	["joint_1b"] = {
		label = "(Joint) Cherry Kush",
		weight = 200
	},
	["joint_2a"] = {
		label = "(Joint) Martian Candy",
		weight = 200
	},
	["joint_2b"] = {
		label = "(Joint) Exodus",
		weight = 200
	},
	["joint_2c"] = {
		label = "(Joint) Headband",
		weight = 200
	},

	-- Cocaine
	["plastic"] = {
		label = "Plastic",
		weight = 0
	},
	["cocaine_container"] = {
		label = "Mixing Container",
		weight = 500,
		stack = false,
		close = true,
		buttons = {
			{
				label = "Shake",
				action = function(slot)
					TriggerServerEvent("prp-drugs:server:cocaine:shakeContainer", slot)
				end
			}
		}
	},
	["cocaine_solvent"] = {
		label = "Solvent",
		weight = 1000,
	},
	["cocaine_leaf"] = {
		label = "Coca Leaf",
		weight = 100
	},
	["cocaine_drying_rack"] = {
		label = "Drying Rack",
		weight = 15000,
		model = `pr_cokedry_01`,
		stack = false
	},
	["cocaine_paste"] = {
		label = "Coca Paste",
		weight = 100,
		model = `prp_cocaine_paste`
	},
	["cocaine_smelter"] = {
		label = "Smelting Furnace",
		weight = 25000,
		model = `cocaine_smelting_01a`,
		stack = false
	},
	["limestone_dust"] = {
		label = "Limestone Dust",
		weight = 100
	},
	["cocaine_powder"] = {
		label = "Coca Powder",
		weight = 100,
		model = `prp_cocaine_powder`
	},
	["cocaine_brick"] = {
		label = "Cocaine Brick",
		weight = 1000,
		model = `hei_prop_heist_weed_block_01`,
		stack = false
	},
	["cocaine"] = {
		label = "Cocaine",
		weight = 100,
		stack = false,
	},
	["wood_log"] = {
		label = "Wood Log",
		weight = 2300,
		stack = false
	},
	["wood_plank"] = {
		label = "Wood Plank",
		weight = 1600,
		stack = false
	},

	-- Meth
	["meth_kit"] = {
		label = "Lab Kit",
		weight = 20000,
		stack = false,
		model = `prp_meth_kit`,
	},
	["meth_cooker_low"] = {
		label = "Small Meth Cooker",
		weight = 20000,
		stack = false,
		model = `pr_methcooker_01`,
	},
	["meth_cooker_mid"] = {
		label = "Medium Meth Cooker",
		weight = 20000,
		stack = false,
		model = `pr_methcooker_01`,
	},
	["meth_cooker_high"] = {
		label = "Large Meth Cooker",
		weight = 20000,
		stack = false,
		model = `pr_methcooker_01`,
	},
	["meth_cooler_low"] = {
		label = "Small Meth Cooler",
		weight = 5000,
		stack = false
	},
	["meth_cooler_mid"] = {
		label = "Medium Meth Cooler",
		weight = 5000,
		stack = false
	},
	["meth_cooler_high"] = {
		label = "Large Meth Cooler",
		weight = 5000,
		stack = false
	},
	["meth_explosive"] = {
		label = "Explosive",
		weight = 2000,
		stack = false,
	},
	["meth"] = {
		label = "Meth",
		weight = 100,
		model = `prp_meth`,
	},
	["meth_slop"] = {
		label = "Wet Slop",
		weight = 0.05,
		model = `prp_meth_slop`
	},
	["meth_hose"] = {
		label = "Rubber Hose",
		weight = 1000,
		model = `prop_hose`,
	},
	["meth_pseudo"] = {
		label = "Pseudoephedrine Extract",
		weight = 5,
		model = `prp_meth_pseudo`
	},
	["meth_redpowder"] = {
		label = "Red Phosphorus Powder",
		weight = 5,
		model = `prp_meth_redpowder`
	},
	["meth_lithium"] = {
		label = "Lithium Strips",
		weight = 5,
		model = `prp_meth_lithium`
	},
	["meth_ammonia_barrel"] = {
		label = "Barrel of Ammonia",
		weight = 50000,
		model = `prop_barrel_01a`,
	},
	["meth_lab_card"] = {
		label = "Laboratory Card",
		weight = 1,
		degrade = 2880, -- 2 days in minutes
		stack = false,
		description = "You can notice a logo saying \"THORNS\" on the card"
	},

	-- Logs
	["oak_log"] = {
		label = "Low Softwood Log",
		weight = 10000,
		stack = false,
	},
	["cedar_log"] = {
		label = "Medium Softwood Log",
		weight = 10000,
		stack = false,
	},
	["pine_log"] = {
		label = "High Softwood Log",
		weight = 10000,
		stack = false,
	},
	["olive_log"] = {
		label = "Hardwood Log",
		weight = 10000,
		stack = false,
	},
	["forest_tree_log"] = {
		label = "Hard Hardwood Log",
		weight = 10000,
		stack = false,
	},

	-- Planks
	["oak_plank"] = {
		label = "Oak Plank",
		weight = 100,
		stack = 50,
	},
	["cedar_plank"] = {
		label = "Medium Softwood Plank",
		weight = 100,
		stack = 50,
	},
	["pine_plank"] = {
		label = "High Softwood Plank",
		weight = 100,
		stack = 50,
	},
	["olive_plank"] = {
		label = "Hardwood Plank",
		weight = 100,
		stack = 50,
	},
	["forest_tree_plank"] = {
		label = "Hard Hardwood Plank",
		weight = 100,
		stack = 50,
	},
}
