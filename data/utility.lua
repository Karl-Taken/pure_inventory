return {
    enabled = true,
    slots = 9,
    slotOffset = 1000,
    enableBackpackComponents = false,  -- Set to false to disable backpack visual components
    hotbarSlots = { 5, 6, 7, 8, 9 },
    items = {
        [1] = { 'backpack_small', 'backpack_medium', 'backpack_large' },
        [2] = { 'armour', 'heavyarmour' },
        [3] = { 'phone' },
        [4] = { 'parachute' },
        [5] = { '$weapon' },
        [6] = { '$weapon' },
        [7] = { '$nonweapon' },
        [8] = { '$nonweapon' },
        [9] = { '$nonweapon' },
    },
    labels = {
        [1] = 'Backpack',
        [2] = 'Body Armour',
        [3] = 'Phone',
        [4] = 'Parachute',
        [5] = 'Weapon Slot 1',
        [6] = 'Weapon Slot 2',
        [7] = 'Hotkey Slot 1',
        [8] = 'Hotkey Slot 2',
        [9] = 'Hotkey Slot 3',
    },
    icons = {
        [1] = 'backpack.svg',
        [2] = 'vest.svg',
        [3] = 'phone.svg',
        [4] = 'parachute.svg',
        [5] = 'others.svg',
        [6] = 'others.svg',
        [7] = 'pocket.svg',
        [8] = 'pocket.svg',
        [9] = 'pocket.svg',
    },
    iconSizes = {
        [1] = 56,
        [2] = 54,
        [3] = 34,
        [4] = 38,
        [5] = 42,
        [6] = 42,
        [7] = 34,
        [8] = 34,
        [9] = 34,
    },
    hotkeys = {
        [5] = '1',
        [6] = '2',
        [7] = '3',
        [8] = '4',
        [9] = '5',
    },
    layout = {
        [1] = { row = 1, column = 1 },
        [2] = { row = 2, column = 1 },
        [3] = { row = 3, column = 1 },
        [4] = { row = 1, column = 3 },
        [5] = { row = 2, column = 3 },
        [6] = { row = 3, column = 3 },
        [7] = { row = 4, column = 1 },
        [8] = { row = 4, column = 2 },
        [9] = { row = 4, column = 3 },
    },
    lockBackpackRemovalWithItems = false,
    armorItems = {
        armour = {
            value = 100,
            initialDurability = 50,
            jobs = {},
        },
        heavyarmour = {
            value = 100,
            initialDurability = 100,
            jobs = { 'police', 'sheriff', 'bcso', 'fib' },
        },
    },
    armorDamageRate = 1.0,
    armorRepairItems = {
        armor_repair_kit = 20,
        armor_plates = {
            amount = 25,
            mode = 'armor',
        },
        improved_armor_plate = {
            amount = 50,
            mode = 'armor',
        },
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
