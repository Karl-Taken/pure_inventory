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
			disable = { move = false, car = false, combat = false },
			usetime = 2500,
		}
	},

	['black_money']          = {
		label = 'Dirty Money',
		modelp = 'bkr_prop_money_wrapped_01',
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
		label = 'Armor Plates',
		weight = 800,
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
	['pickaxe'] = {
		label = 'Pickaxe',
		weight = 1200,
		client = {
			image = "pickaxe.webp"
		}
	},

	['copper_pickaxe'] = {
		label = 'Copper Pickaxe',
		weight = 1200,
		client = {
			image = "copper_pickaxe.webp"
		}
	},

	['iron_pickaxe'] = {
		label = 'Iron Pickaxe',
		weight = 1250,
		client = {
			image = "iron_pickaxe.webp"
		}
	},

	['silver_pickaxe'] = {
		label = 'Silver Pickaxe',
		weight = 1260,
		client = {
			image = "silver_pickaxe.webp"
		}
	},

	['gold_pickaxe'] = {
		label = 'Gold Pickaxe',
		weight = 1265,
		client = {
			image = "gold_pickaxe.webp"
		}
	},

	['copper_ore'] = {
		label = 'Copper Ore',
		weight = 500,
		client = {
			image = "copper.webp"
		}
	},

	['coal_ore'] = {
		label = 'Coal Ore',
		weight = 250,
		client = {
			image = "coal.webp"
		}
	},

	['iron_ore'] = {
		label = 'Iron Ore',
		weight = 500,
		client = {
			image = "iron.webp"
		}
	},

	['silver_ore'] = {
		label = 'Silver Ore',
		weight = 500,
		client = {
			image = "silver.webp"
		}
	},

	['gold_ore'] = {
		label = 'Gold Ore',
		weight = 500,
		client = {
			image = "gold.webp"
		}
	},

	['copper_ingot'] = {
		label = 'Copper Ingot',
		weight = 500,
		client = {
			image = "copper.webp"
		}
	},

	['iron_ingot'] = {
		label = 'Iron Ingot',
		weight = 500,
		client = {
			image = "iron.webp"
		}
	},

	['silver_ingot'] = {
		label = 'Silver Ingot',
		weight = 500,
		client = {
			image = "silver.webp"
		}
	},

	['gold_ingot'] = {
		label = 'Gold Ingot',
		weight = 500,
		client = {
			image = "gold.webp"
		}
	},

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

	["stretcher"] = {
		label = "Stretcher",
		weight = 15000,
		stack = false,
		consume = 1,
		server = {
			export = "ND_Ambulance.createStretcher"
		}
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
			export = "ND_Ambulance.useBag"
		},
		client = {
			export = "ND_Ambulance.useBag",
			add = function(total)
				if total > 0 then
					pcall(function()
						return exports["ND_Ambulance"]:bag(true)
					end)
				end
			end,
			remove = function(total)
				if total < 1 then
					pcall(function()
						return exports["ND_Ambulance"]:bag(false)
					end)
				end
			end
		}
	},
	["burndressing"] = {
		label = "Burn Dressing",
		weight = 50,
		server = {
			export = "ND_Ambulance.treatment"
		},
		client = {
			anim = { dict = "missheistdockssetup1clipboard@idle_a", clip = "idle_a", flag = 49 },
			prop = { model = `prop_toilet_roll_01`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2500
		}
	},
	["splint"] = {
		label = "Splint",
		weight = 500,
		server = {
			export = "ND_Ambulance.treatment"
		},
		client = {
			anim = { dict = "missheistdockssetup1clipboard@idle_a", clip = "idle_a", flag = 49 },
			prop = { model = `prop_toilet_roll_01`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2500
		}
	},
	["gauze"] = {
		label = "Gauze",
		weight = 80,
		server = {
			export = "ND_Ambulance.treatment"
		},
		client = {
			anim = { dict = "missheistdockssetup1clipboard@idle_a", clip = "idle_a", flag = 49 },
			prop = { model = `prop_toilet_roll_01`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2500
		}
	},
	["tourniquet"] = {
		label = "Tourniquet",
		weight = 85,
		server = {
			export = "ND_Ambulance.treatment"
		},
		client = {
			anim = { dict = "missheistdockssetup1clipboard@idle_a", clip = "idle_a", flag = 49 },
			prop = { model = `prop_rolled_sock_02`, pos = vec3(-0.14, -0.14, -0.08), rot = vec3(-50.0, -50.0, 0.0) },
			disable = { move = true, car = true, combat = true },
			usetime = 2500
		}
	},
}
