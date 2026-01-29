return {
    enabled = true,
    slots = 1,
    slotOffset = 1000,
    enableBackpackComponents = false,  -- Set to false to disable backpack visual components
    items = {
        -- [1] = { 'armour', 'heavyarmour' },
        [1] = { 'backpack_small', 'backpack_medium', 'backpack_large' },
    },
    labels = {
        -- [1] = 'Vest',
        [1] = 'Backpack',
    },
    icons = {
        -- [1] = 'vest.svg',
        [1] = 'backpack.svg',
    },
    iconSizes = {
        [1] = 50,
        [2] = 60,
    },
    lockBackpackRemovalWithItems = true,
    armorItems = {
        armour = {
            value = 50,
            jobs = {},
        },
        heavyarmour = {
            value = 100,
            jobs = { 'police', 'sheriff', 'bcso', 'fib' },
        },
    },
    armorDamageRate = 0.5,
    armorRepairItems = {
        armor_repair_kit = 20,
        armor_plates = 20,
    },
    backpackItems = {
        backpack_small = {
            slots = 50,
            weight = 50000,
            component = {
                drawable = 40,  -- Backpack drawable ID
                texture = 0,   -- Backpack texture variation
            },
        },
        backpack_medium = {
            slots = 20,
            weight = 100000,
            component = {
                drawable = 44,  -- Different drawable for medium backpack
                texture = 0,
            },
        },
        backpack_large = {
            slots = 30,
            weight = 150000,
            component = {
                drawable = 45,  -- Different drawable for large backpack
                texture = 0,
            },
        },
    },
}
