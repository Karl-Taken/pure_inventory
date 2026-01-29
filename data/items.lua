return {
	['testburger']           = {
		label = 'Test Burger',
		weight = 220,
		degrade = 60,
		client = {
			image = 'burger_chicken.png',
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
			image = 'soda_cup.png',
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

			image = 'bun.png',
		}
	},
	['raw_patty']            = {
		label = "Raw Patty",
		weight = 10,
		description = "Listen, it's still mooing. Better put it in a grill fast",
		degradee = 30,
		client = {
			image = 'raw_patty.png',
		}
	},
	['cooked_patty']         = {
		label = "Cooked Patty",
		weight = 10,
		description = "A cooked slab of meat, eat it by itself.",
		client = {
			status = { hunger = 7 },
			image = 'cooked_patty.png',
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
			image = 'soda_cup.png',
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
			image = 'paper_bag.png'
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
			image = 'card_id.png'
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
			image = 'card_bank.png'
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
		client = { image = "washing_machine.png" },
		server = { export = 'laundry-test.useWasher' }
	},

	["fan"]                  = {
		label = "Cooling Fan",
		weight = 800,
		stack = false,
		close = true,
		description = "Keeps things cool while processing.",
		client = { image = "fan.png" },
		server = { export = 'laundry-test.useFan' }

	},

	["basket"]               = {
		label = "Laundry Basket",
		weight = 500,
		stack = false,
		close = true,
		description = "Carry and sort laundry with style.",
		client = { image = "basket.png" },
		server = { export = 'laundry-test.usePanel' }
	},

	["generator"]            = {
		label = "Power Generator",
		weight = 3500,
		stack = false,
		close = true,
		description = "Portable power for your setup.",
		client = { image = "generator.png" },
		server = { export = 'laundry-test.useGenerator' }
	},


	["backpack_small"] = {
		label = "Small Backpack",
		weight = 500,
		stack = false,
		close = false,
		description = "A small backpack for carrying extra items.",
		client = { image = "backpack_small.png" }
	},

	["backpack_medium"] = {
		label = "Medium Backpack",
		weight = 750,
		stack = false,
		close = false,
		description = "A medium backpack for carrying more items.",
		client = { image = "backpack_medium.png" },
		rarity = "common"
	},

	["backpack_large"] = {
		label = "Large Backpack",
		weight = 1000,
		stack = false,
		close = false,
		description = "A large backpack for carrying many items.",
		client = { image = "backpack_large.png" },
		rarity = "common"
	},


	['fishing_rod'] = {
		label = 'Fishing Rod',
		weight = 1500,
		stack = false,
		modelp = 'prop_fishing_rod_01',
		client = {
			image = 'fishing_rod.png'
		}
	}

}
