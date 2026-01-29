return {
    -- Set to true to enable the rarity system (colored borders, effects, labels).
    -- Set to false to completely disable all rarity features.
    Enabled = true,

    -- Define your rarities here
    -- Note: Using rgba for cleaner alpha channel support across all environments
    Levels = {
        ['common'] = {
            label = "COMMON",
            text = '#ffffff',
            background = 'radial-gradient(circle, rgba(0, 0, 0, 0.3) 0%, rgba(81, 81, 81, 0.3) 100%)',
            color = '#ffffff', 
        },
        ['uncommon'] = {
            label = "UNCOMMON",
            text = '#4ade80',
            background = 'radial-gradient(circle, rgba(0, 0, 0, 0.3) 0%, rgba(74, 222, 128, 0.15) 100%)',
            color = '#4ade80',
        },
        ['rare'] = {
            label = "RARE",
            text = '#0ea5e9',
            background = 'radial-gradient(circle, rgba(0, 0, 0, 0) 0%, rgba(14, 165, 233, 0.15) 100%)',
            color = '#0ea5e9',
        },
        ['epic'] = {
            label = "EPIC",
            text = '#c026d3',
            background = 'radial-gradient(circle, rgba(0, 0, 0, 0) 0%, rgba(190, 24, 93, 0.2) 100%)',
            color = '#c026d3',
        },
        ['legendary'] = {
            label = "LEGENDARY",
            text = '#eab308',
            background = 'radial-gradient(circle, rgba(0, 0, 0, 0) 0%, rgba(161, 98, 7, 0.2) 100%)',
            color = '#eab308',
        },
        -- Custom rarities
        ['danger'] = {
            label = "DANGER",
            text = '#ea1708',
            background = 'radial-gradient(circle, rgba(0, 0, 0, 0) 0%, rgba(161, 7, 7, 0.2) 100%)',
            color = '#ea1708',
        },
        ['gold'] = {
            label = "GOLD",
            text = '#7e6704',
            background = 'radial-gradient(circle, rgba(0, 0, 0, 0) 0%, rgba(161, 151, 7, 0.2) 100%)',
            color = '#7e6704',
        },
    }
}
