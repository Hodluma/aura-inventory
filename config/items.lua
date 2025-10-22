Config = Config or {}
Config.Items = {
    water = {
        label = 'Water Bottle',
        description = 'Stay hydrated.',
        weight = 0.5,
        maxStack = 10,
        category = 'food',
        metadata = {thirst = 30},
        useEvent = 'consumables:client:DrinkWater'
    },
    bread = {
        label = 'Bread',
        description = 'Freshly baked.',
        weight = 0.4,
        maxStack = 10,
        category = 'food',
        metadata = {hunger = 25},
        useEvent = 'consumables:client:Eat'
    },
    bandage = {
        label = 'Bandage',
        description = 'Quick wound treatment.',
        weight = 0.2,
        maxStack = 5,
        category = 'medical',
        metadata = {heal = 25},
        useEvent = 'consumables:client:UseBandage'
    },
    pistol = {
        label = '9mm Pistol',
        description = 'Standard issue sidearm.',
        weight = 2.0,
        maxStack = 1,
        category = 'weapon',
        metadata = {weaponName = 'WEAPON_PISTOL', durability = 100, caliber = '9mm', weaponClass = 'pistol'}
    },
    rifle = {
        label = 'Carbine Rifle',
        description = 'High capacity assault rifle.',
        weight = 4.5,
        maxStack = 1,
        category = 'weapon',
        metadata = {weaponName = 'WEAPON_CARBINERIFLE', durability = 100, caliber = '5.56', weaponClass = 'rifle'}
    },
    ammo_9mm = {
        label = '9mm Ammo',
        description = 'Box of 9mm rounds.',
        weight = 0.02,
        maxStack = 50,
        category = 'ammo',
        metadata = {caliber = '9mm'}
    },
    ammo_rifle = {
        label = '5.56 Ammo',
        description = 'Rifle rounds.',
        weight = 0.03,
        maxStack = 50,
        category = 'ammo',
        metadata = {caliber = '5.56'}
    },
    repairkit = {
        label = 'Weapon Repair Kit',
        description = 'Restore weapon durability.',
        weight = 1.0,
        maxStack = 2,
        category = 'tools',
        metadata = {restore = 50}
    },
    pistol_comp = {
        label = 'Pistol Compensator',
        description = 'Attachment for pistols.',
        weight = 0.4,
        maxStack = 1,
        category = 'attachment',
        metadata = {attachmentType = 'comp', weaponClass = 'pistol'}
    },
    rifle_scope = {
        label = 'Rifle Scope',
        description = 'Mid-range optic.',
        weight = 0.5,
        maxStack = 1,
        category = 'attachment',
        metadata = {attachmentType = 'scope', weaponClass = 'rifle'}
    },
    notebook = {
        label = 'Notebook',
        description = 'Take notes.',
        weight = 0.1,
        maxStack = 5,
        category = 'misc',
        metadata = {notes = ''}
    }
}
