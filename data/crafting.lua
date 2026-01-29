return {
	xp = {
		enabled = true,
		hideLocked = true,
		defaultReward = 0
	},
	blueprints = {
		lockpick = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'lockpick',
			consume = 0.05  -- Consume 5% durability per craft
		},
		weapon_bat = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_bat',
			consume = 0.05
		},
		weapon_crowbar = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_crowbar',
			consume = 0.05
		},
		weapon_wrench = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_wrench',
			consume = 0.05
		},
		weapon_hatchet = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_hatchet',
			consume = 0.05
		},
		weapon_hammer = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_hammer',
			consume = 0.05
		},
		weapon_pistol = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_pistol',
			consume = 0.05
		},
		weapon_smg = {
			item = 'blueprint',
			metadataKey = 'blueprint',
			metadataValue = 'weapon_smg',
			consume = 0.05
		},
	},
	types = {
		basic = {
			label = 'Basic Crafting Bench',
			model = 'prop_tool_bench02',
			spawnRange = 35.0,
			storage = {
				slots = 30,
				maxWeight = 100000
			},
			placement = {
				item = 'bench_basic',
				returnItem = true
			},
			recipes = {
				{
					name = 'lockpick',
					ingredients = {
						scrapmetal = 5,
						WEAPON_HAMMER = 0.05
					},
					duration = 5000,
					count = 2,
					xp = {
						required = 0,
						reward = 5
					},
					-- blueprint = 'lockpick'
				},
			}
		},
		advanced = {
			label = 'Advanced Crafting Bench',
			model = 'xm3_prop_xm3_bench_04b',
			spawnRange = 50.0,
			storage = {
				slots = 45,
				maxWeight = 150000
			},
			placement = {
				item = 'bench_advanced',
				returnItem = true
			},
			recipes = {
				{
					name = 'weapon_bat',
					ingredients = {
						scrapmetal = 10,
						WEAPON_HAMMER = 0.05 -- Consume 5% durability per craft
					}, 
					duration = 55000,
					count = 1,
					xp = {
						required = 15,
						reward = 12
					},
					blueprint = 'weapon_bat'
				},
				{
					name = 'weapon_crowbar',
					ingredients = {
						scrapmetal = 9,
						WEAPON_HAMMER = 0.05
					},
					duration = 55000,
					count = 1,
					xp = {
						required = 20,
						reward = 12
					},
					blueprint = 'weapon_crowbar'
				},
				{
					name = 'weapon_wrench',
					ingredients = {
						scrapmetal = 7,
						WEAPON_HAMMER = 0.05
					},
					duration = 5500,
					count = 1,
					xp = {
						required = 25,
						reward = 14
					},
					blueprint = 'weapon_wrench'
				},
				{
					name = 'weapon_hatchet',
					ingredients = {
						scrapmetal = 12,
						WEAPON_HAMMER = 0.05
					},
					duration = 6500,
					count = 1,
					xp = {
						required = 28,
						reward = 16
					},
					blueprint = 'weapon_hatchet'
				},
				{
					name = 'weapon_hammer',
					ingredients = {
						scrapmetal = 8,
						WEAPON_HAMMER = 0.05
					},
					duration = 6000,
					count = 1,
					xp = {
						required = 32,
						reward = 16
					},
					blueprint = 'weapon_hammer'
				},
				{
					name = 'weapon_pistol',
					ingredients = {
						scrapmetal = 20,
						WEAPON_HAMMER = 0.05
					},
					duration = 7600,
					count = 1,
					xp = {
						required = 36,
						reward = 22
					},
					blueprint = 'weapon_pistol'
				},
				{
					name = 'weapon_smg',
					ingredients = {
						scrapmetal = 28,
						WEAPON_HAMMER = 0.05
					},
					duration = 8800,
					count = 1,
					xp = {
						required = 48,
						reward = 28
					},
					blueprint = 'weapon_smg'
				},
			}
		}
	},
	benches = {
		{
			name = 'debug_crafting',
			type = 'basic',
			-- jobs = { 'mechanic' , 'mechanic2' }, -- remove all line to allow all jobs
			points = {
				vec3(-1147.083008, -2002.662109, 13.180260),
				vec3(-345.374969, -130.687088, 39.009613)
			},
			zones = {
				{
					coords = vec3(-1151.32, -2004.9, 12.18),
					size = vec3(3.8, 1.05, 0.15),
					distance = 2,
					rotation = 315.0,
				},
				{
					coords = vec3(-346.1, -130.45, 39.0),
					size = vec3(3.8, 1.05, 0.15),
					distance = 1.5,
					rotation = 70.0,
				},
			},
			blip = { id = 566, colour = 31, scale = 0.8 },
		},

	}
}
