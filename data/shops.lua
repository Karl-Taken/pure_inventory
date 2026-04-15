return {
	General = {
		name = 'Shop',
		blip = {
			id = 59, colour = 69, scale = 0.8
		},
		inventory = {
			{ name = 'water',   price = 10 },
			{ name = 'sprunk',  price = 15 },
			{ name = 'mustard', price = 5 },
		},
		locations = {
			vec3(25.7, -1347.3, 29.49),
			vec3(-3038.71, 585.9, 7.9),
			vec3(-3241.47, 1001.14, 12.83),
			vec3(1728.66, 6414.16, 35.03),
			vec3(1697.99, 4924.4, 42.06),
			vec3(1961.48, 3739.96, 32.34),
			vec3(547.79, 2671.79, 42.15),
			vec3(2679.25, 3280.12, 55.24),
			vec3(2557.94, 382.05, 108.62),
			vec3(373.55, 325.56, 103.56),

			vec3(1135.808, -982.281, 46.415),
			vec3(-1222.915, -906.983, 12.326),
			vec3(-1487.553, -379.107, 40.163),
			vec3(-2968.243, 390.910, 15.043),
			vec3(1166.024, 2708.930, 38.157),
			vec3(1392.562, 3604.684, 34.980),
			vec3(-1393.409, -606.624, 30.319)
		},
		targets = {
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(24.87, -1347.52, 28.5),    heading = 271.38 }, -- strawberry gas station
			-- { loc = vec3(25.56, -1347.32, 29.5),   debug = true, length = 0.7,width = 0.5,     heading = 0.0, minZ = 29.5,   maxZ = 29.9,   distance = 1.5 },
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(-3039.06, 584.91, 6.91),   heading = 25.14 }, -- chumash
			-- { loc = vec3(-3039.18, 585.13, 7.91),  length = 0.6, width = 0.5, heading = 15.0,  minZ = 7.91,   maxZ = 8.31,   distance = 1.5 },
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(-3242.23, 1000.42, 11.83), heading = 349.73 }, -- chumash 2
			-- { loc = vec3(-3242.2, 1000.58, 12.83), length = 0.6, width = 0.6, heading = 175.0, minZ = 12.83,  maxZ = 13.23,  distance = 1.5 },
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(1728.12, 6414.77, 34.04),  heading = 251.23 }, -- mount chilliad
			-- { loc = vec3(1728.39, 6414.95, 35.04), length = 0.6, width = 0.6, heading = 65.0,  minZ = 35.04,  maxZ = 35.44,  distance = 1.5 },
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(1698.08, 4922.94, 41.06),  heading = 337.52 }, -- grapeseed
			-- { loc = vec3(1698.37, 4923.43, 42.06), length = 0.5, width = 0.5, heading = 235.0, minZ = 42.06,  maxZ = 42.46,  distance = 1.5 },
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(1960.62, 3739.96, 31.34),  heading = 313.63 }, -- sandy shores
			-- { loc = vec3(1960.54, 3740.28, 32.34), length = 0.6, width = 0.5, heading = 120.0, minZ = 32.34,  maxZ = 32.74,  distance = 1.5 },
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(548.62, 2671.49, 41.16),   heading = 93.92 }, -- harmony
			-- { loc = vec3(548.5, 2671.25, 42.16),   length = 0.6, width = 0.5, heading = 10.0,  minZ = 42.16,  maxZ = 42.56,  distance = 1.5 },
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(2678.46, 3279.68, 54.24),  heading = 325.36 }, -- Senora Fwy
			-- { loc = vec3(2678.29, 3279.94, 55.24), length = 0.6, width = 0.5, heading = 330.0, minZ = 55.24,  maxZ = 55.64,  distance = 1.5 },
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(2557.46, 381.25, 107.62),  heading = 351.42 }, -- Tataviam Mountains
			-- { loc = vec3(2557.19, 381.4, 108.62),  length = 0.6, width = 0.5, heading = 0.0,   minZ = 108.62, maxZ = 109.02, distance = 1.5 },
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(372.94, 326.13, 102.57),   heading = 257.86 }, -- Tataviam Mountains
			-- { loc = vec3(373.13, 326.29, 103.57),  length = 0.6, width = 0.5, heading = 345.0, minZ = 103.57, maxZ = 103.97, distance = 1.5 },
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(1134.19, -983.2, 45.42),   heading = 275.03 }, -- Vespucci Boulevard
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(-1221.4, -907.97, 11.33),  heading = 31.3 }, -- San Andreas Ave Boulevard
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(-1486.56, -377.52, 39.16), heading = 135.22 }, -- Prosperity Street
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(-2966.32, 391.48, 14.04),  heading = 83.92 }, -- Great Ocean Highway
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(1165.32, 2710.78, 37.16),  heading = 171.7 }, -- Great Ocean Highway
			{ ped = `mp_m_shopkeep_01`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(1165.32, 2710.78, 37.16),  heading = 171.7 }, -- Great Ocean Highway
		}
	},

	YouTool = {
		name = 'YouTool',
		blip = {
			id = 402, colour = 69, scale = 0.8
		},
		inventory = {
			{ name = 'lockpick', price = 10 },
			{ name = 'radio',    price = 10 }
		},
		locations = {
			vec3(2748.0, 3473.0, 55.67),
			vec3(342.99, -1298.26, 32.51)
		},
		targets = {
			{ loc = vec3(2746.8, 3473.13, 55.67), length = 0.6, width = 3.0, heading = 65.0, minZ = 55.0, maxZ = 56.8, distance = 3.0 }
		}
	},

	Ammunation = {
		name = 'Ammunation',
		blip = {
			id = 110, colour = 69, scale = 0.8
		},
		inventory = {
			{ name = 'pistol_ammo',    price = 35, },
			{ name = 'sniper_ammo',    price = 45, },
			{ name = 'WEAPON_KNIFE',   price = 50 },
			{ name = 'WEAPON_BAT',     price = 80 },
			{ name = 'WEAPON_DAGGER',  price = 100 },
			{ name = 'WEAPON_HATCHET', price = 180 },
			{ name = 'armour',         price = 300 },
			{ name = 'armor_plates',   price = 200 },
		},
		locations = {
			vec3(-662.180, -934.961, 21.829),
			vec3(810.25, -2157.60, 29.62),
			vec3(1693.44, 3760.16, 34.71),
			vec3(-330.24, 6083.88, 31.45),
			vec3(252.63, -50.00, 69.94),
			vec3(22.56, -1109.89, 29.80),
			vec3(2567.69, 294.38, 108.73),
			vec3(-1117.58, 2698.61, 18.55),
			vec3(842.44, -1033.42, 28.19)
		},
		targets = {
			{ ped = `s_m_m_ammucountry`, scenario = 'WORLD_HUMAN_AA_SMOKE', loc = vec3(-659.16, -939.9, 20.83),   heading = 98.01 },
			{ ped = `s_m_m_ammucountry`, scenario = 'WORLD_HUMAN_AA_SMOKE', loc = vec3(813.5, -2155.17, 28.62),   heading = 0.77 }, -- El Rancho Blvd
			{ ped = `s_m_m_ammucountry`, scenario = 'WORLD_HUMAN_AA_SMOKE', loc = vec3(1697.91, 3757.46, 33.71),  heading = 145.11 },
			{ ped = `s_m_m_ammucountry`, scenario = 'WORLD_HUMAN_AA_SMOKE', loc = vec3(-326.03, 6081.16, 30.45),  heading = 130.23 },
			{ ped = `s_m_m_ammucountry`, scenario = 'WORLD_HUMAN_AA_SMOKE', loc = vec3(246.89, -51.31, 68.94),    heading = 338.59 },
			{ ped = `s_m_m_ammucountry`, scenario = 'WORLD_HUMAN_AA_SMOKE', loc = vec3(18.2, -1107.91, 28.8),     heading = 152.27 },
			{ ped = `s_m_m_ammucountry`, scenario = 'WORLD_HUMAN_AA_SMOKE', loc = vec3(-1112.41, 2697.12, 17.55), heading = 130.41 },
		}
	},

	PoliceArmoury = {
		name = 'Police Armoury',
		groups = shared.police,
		blip = {
			id = 110, colour = 84, scale = 0.8
		},
		inventory = {
			{ name = 'pistol_ammo',         price = 5, },
			{ name = 'smg_ammo',            price = 5, },
			{ name = 'rifle_ammo',          price = 5, },
			{ name = 'shotgun_ammo',        price = 5, },
			{ name = 'WEAPON_FLASHLIGHT',   price = 200 },
			{ name = 'WEAPON_NIGHTSTICK',   price = 100 },
			{ name = 'WEAPON_DUTY_PISTOL',  price = 500,  metadata = { registered = true, serial = 'POL' }, license = 'weapon' },
			{ name = 'WEAPON_CARBINERIFLE', price = 1000, metadata = { registered = true, serial = 'POL' }, license = 'weapon', grade = 3 },
			{ name = 'WEAPON_STUNGUN',      price = 500,  metadata = { registered = true, serial = 'POL' } }
		},
		locations = {
			vec3(1822.1155, 3679.7444, 34.3336), -- Blaine County
			vec3(1529.9691, 807.3405, 72.3011), -- Highway PD
			vec3(479.7237, -996.6976, 30.6271), -- MRPD
			vec3(838.6980, -1282.3201, 21.3901), -- Highway PD Popular
			vec3(364.9733, -1599.0238, 25.5731), -- Davis PD
			vec3(-444.9582, 6013.9883, 37.1408), -- Paleto PD
			vec3(-594.8777, -100.6516, 33.8280), -- Rockford PD
		},
		targets = {
			{ loc = vec3(1822.1155, 3679.7444, 34.3336), length = 0.5, width = 3.0, heading = 20.24,  minZ = 30.5, maxZ = 32.0, distance = 6 }, -- Blaine County Sheriffs Office
			{ loc = vec3(1529.9691, 807.3405, 72.3011),  length = 0.5, width = 3.0, heading = 53.72,  minZ = 30.5, maxZ = 32.0, distance = 6 }, -- Highway PD
			{ loc = vec3(479.7237, -996.6976, 30.6271),  length = 0.5, width = 3.0, heading = 279.26, minZ = 30.5, maxZ = 32.0, distance = 6 }, -- Highway PD
			{ loc = vec3(838.6980, -1282.3201, 21.3901), length = 0.5, width = 3.0, heading = 356.42, minZ = 30.5, maxZ = 32.0, distance = 6 }, -- Highway PD
			{ loc = vec3(364.9733, -1599.0238, 25.5731), length = 0.5, width = 3.0, heading = 134.56, minZ = 30.5, maxZ = 32.0, distance = 6 }, -- Highway PD
			{ loc = vec3(-444.9582, 6013.9883, 37.1408), length = 0.5, width = 3.0, heading = 47.56,  minZ = 30.5, maxZ = 32.0, distance = 6 }, -- Highway PD
			{ loc = vec3(-594.8777, -100.6516, 33.8280), length = 0.5, width = 3.0, heading = 19.19,  minZ = 30.5, maxZ = 32.0, distance = 6 }, -- Highway PD

		}
	},

	Medicine = {
		name = 'EMS Store',
		groups = {
			['ambulance'] = 0
		},
		blip = {
			id = 403, colour = 69, scale = 0.8
		},
		inventory = {
			{ name = 'medikit', price = 26 },
			{ name = 'bandage', price = 5 }
		},
		locations = {
			vec3(306.3687, -601.5139, 43.28406)
		},
		targets = {

		}
	},

	BlackMarketArms = {
		name = 'Black Market (Arms)',
		inventory = {
			{ name = 'WEAPON_DAGGER',        price = 5000,  metadata = { registered = false }, currency = 'black_money' },
			{ name = 'WEAPON_CERAMICPISTOL', price = 50000, metadata = { registered = false }, currency = 'black_money' },
			{ name = 'at_suppressor_light',  price = 50000, currency = 'black_money' },
			{ name = 'ammo-rifle',           price = 1000,  currency = 'black_money' },
			{ name = 'ammo-rifle2',          price = 1000,  currency = 'black_money' }
		},
		locations = {
			vec3(309.09, -913.75, 56.46)
		},
		targets = {

		}
	},

	VendingMachineDrinks = {
		name = 'Vending Machine',
		inventory = {
			{ name = 'water', price = 10 },
			{ name = 'cola',  price = 10 },
		},
		model = {
			`prop_vend_soda_02`, `prop_vend_fridge01`, `prop_vend_water_01`, `prop_vend_soda_01`
		}
	},

	BurgerShot = {
		name = "Burger Shot Shop",
		inventory = {
			{ name = 'soda_cup',  price = 25 },
			{ name = 'raw_patty', price = 25 },
			{ name = 'bun',       price = 25 },
			{ name = 'paper_bag', price = 1 }
		},
		groups = {
			["burgershot"] = 0
		},
		locations = {
			vec3(-1196.59, -901.7, 12.89)
		},
		targets = {
			-- { debug = true, loc = vec3(-1196.59, -901.7, 12.89), length = 2, width = 0.5, heading = 0.0, minZ = 12.89, maxZ = 12.94, distance = 1.5 },
			{ ped = `csb_burgerdrug`, scenario = 'WORLD_HUMAN_AA_COFFEE', loc = vec3(-1196.59, -901.7, 12.89), heading = 120.32 }
		}
	},

	CasinoCounter = {
		name = 'Casino Counter',
		inventory = {
			{ name = 'casinochips', price = 10, currency = 'cash' }
		},
		locations = {
			vec3(1116.04, 219.92, -50.44),
		},
		targets = {
			{ debug = true, loc = vec3(1116.5, 219.92, -50.44), length = 0.6, width = 0.5, heading = 271.08, minZ = 55.0, maxZ = 56.8, distance = 3.0 }
		}
	},

	["MiningShop"] = {
		name = "Mining Shop",
		inventory = {
			{ name = "WEAPON_PICKAXE",       price = 200 },
			{ name = "WEAPON_DRILL",         price = 500 },
			{ name = "WEAPON_DRILL_COBALT",  price = 750 },
			{ name = "WEAPON_DRILL_HSS",     price = 1000 },
			{ name = "WEAPON_DRILL_DIAMOND", price = 1500 },
		},
		-- locations = {
		--    vector3(2707.3118, 2776.8994, 37.8780), -- example location
		-- },
		targets = {
			{ ped = `s_m_m_strvend_01`, scenario = "WORLD_HUMAN_STAND_IMPATIENT", loc = vector3(2707.3118, 2776.8994, 37.8780), heading = 27.8579 },
		},
	},

	["Pressurewash"] = {
		name = "Pressure Wash Shop",
		inventory = {
			{ name = 'WEAPON_PRESSUREWASHER', price = 25 },
			{ name = 'pressurewash',          price = 45 },
			{ name = 'petrolcan',             price = 15 },
			{ name = 'watercanister',         price = 13 },
		},
	},

	["FishingShop"] = {
		name = "Fishing Supply Store",
		inventory = {
			-- Rods
			{ name = "basic_fishing_rod",        price = 100 },
			{ name = "sport_fishing_rod",        price = 200 },
			{ name = "professional_fishing_rod", price = 550 },
			{ name = "aqua_fishing_rod",         price = 750 },
			{ name = "golden_fishing_rod",       price = 1000 },
			-- Bait
			{ name = "fishing_bait_worm",        price = 10 },
			{ name = "fishing_bait_lugworm",     price = 15 },
			{ name = "fishing_bait_radiated",    price = 25 },
		},
		-- locations = {
		--    vector3(-1710.5709, -1110.9550, 13.1523),
		-- },
		targets = {
			{ ped = `s_m_m_strvend_01`, scenario = "WORLD_HUMAN_STAND_IMPATIENT", loc = vec3(-1593.89, 5192.56, 3.31), heading = 211.71 },
		},
	}
}
