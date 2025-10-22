Config = Config or {}
Config.Crafting = {
    stations = {
        workbench = {
            label = 'General Workbench',
            coords = vector3(1165.3, -1657.9, 45.8),
            radius = 2.5,
            jobs = {},
            gangs = {},
            recipes = {'bandage_pack', 'pistol_ammo_box'}
        },
        gun_bench = {
            label = 'Gun Bench',
            coords = vector3(911.3, -2108.4, 30.5),
            radius = 2.0,
            jobs = {{name = 'weazle', grade = 2}},
            gangs = {},
            recipes = {'pistol_clean', 'rifle_scope_attach'}
        }
    },
    recipes = {
        bandage_pack = {
            id = 'bandage_pack',
            label = 'Craft Bandage',
            stationType = 'workbench',
            timeMs = 5000,
            failChance = 0.05,
            inputs = {
                {name = 'bandage', qty = 1},
                {name = 'notebook', qty = 1}
            },
            outputs = {
                {name = 'bandage', qty = 2}
            },
            requirements = {
                level = 0,
                tools = {}
            }
        },
        pistol_ammo_box = {
            id = 'pistol_ammo_box',
            label = 'Craft 9mm Ammo',
            stationType = 'workbench',
            timeMs = 8000,
            failChance = 0.1,
            inputs = {
                {name = 'notebook', qty = 1},
                {name = 'water', qty = 1}
            },
            outputs = {
                {name = 'ammo_9mm', qty = 20}
            },
            requirements = {
                tools = {'repairkit'}
            }
        },
        pistol_clean = {
            id = 'pistol_clean',
            label = 'Clean Pistol',
            stationType = 'gun_bench',
            timeMs = 6000,
            failChance = 0.0,
            inputs = {
                {name = 'pistol', qty = 1},
                {name = 'repairkit', qty = 1}
            },
            outputs = {
                {name = 'pistol', qty = 1, metadata = {durability = 100}}
            },
            requirements = {
                job = {name = 'police', grade = 1}
            }
        },
        rifle_scope_attach = {
            id = 'rifle_scope_attach',
            label = 'Attach Rifle Scope',
            stationType = 'gun_bench',
            timeMs = 4000,
            failChance = 0.0,
            inputs = {
                {name = 'rifle', qty = 1},
                {name = 'rifle_scope', qty = 1}
            },
            outputs = {
                {name = 'rifle', qty = 1, metadata = {attachments = {scope = true}}}
            },
            requirements = {
                job = {name = 'police', grade = 2}
            }
        }
    }
}
