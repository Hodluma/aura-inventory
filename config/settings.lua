Config = Config or {}

Config.Settings = {
    capacityMode = 'weight', -- 'weight' or 'slots'
    maxWeight = 120.0,
    maxSlots = 40,
    hotbarSlots = 5,
    hotbarCooldownMs = 1000,
    allowStackSplit = true,
    splitStackMin = 1,
    fallbackImage = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect fill="%23343a40" width="64" height="64" rx="8" /><path fill="%23f8f9fa" d="M20 32h24v4H20zm0-10h24v4H20zm0 20h24v4H20z" /></svg>',
    uiTheme = 'dark',
    locale = 'en',
    debounceMs = 150,
    diffSync = true,
    keybinds = {
        inventory = 'TAB',
        hotbarOverlay = 'Z',
        hotbarSlots = {'1', '2', '3', '4', '5'}
    },
    groundDrop = {
        despawnMinutes = 20,
        maxDropsPerArea = 15,
        dropDistance = 25.0,
        pickupDistance = 2.0,
        ownerGraceSeconds = 30
    },
    rateLimits = {
        moveItem = {bucket = 20, refill = 5},
        splitStack = {bucket = 10, refill = 3},
        useItem = {bucket = 10, refill = 3},
        dropItem = {bucket = 10, refill = 2},
        pickupDrop = {bucket = 15, refill = 5},
        craftStart = {bucket = 5, refill = 2},
        attach = {bucket = 10, refill = 2},
        detach = {bucket = 10, refill = 2},
        shopBuy = {bucket = 10, refill = 2},
        shopSell = {bucket = 10, refill = 2}
    },
    webhook = {
        enabled = false,
        url = ''
    }
}

Config.WeaponDurability = {
    default = {max = 100, decayPerUse = 1},
    weaponOverrides = {
        WEAPON_PISTOL = {max = 120, decayPerUse = 0.6},
        WEAPON_ASSAULTRIFLE = {max = 200, decayPerUse = 0.8}
    }
}

Config.AttachmentCompat = {
    pistol = {
        comp = {'WEAPON_PISTOL', 'WEAPON_APPISTOL'},
        flashlight = {'WEAPON_PISTOL'},
        scope = {'WEAPON_PISTOL_MK2'}
    },
    rifle = {
        scope = {'WEAPON_ASSAULTRIFLE', 'WEAPON_CARBINERIFLE'},
        grip = {'WEAPON_ASSAULTRIFLE', 'WEAPON_CARBINERIFLE'},
        flashlight = {'WEAPON_ASSAULTRIFLE'}
    }
}

Config.Admin = {
    commands = {
        inspect = 'ainv.inspect',
        clearDrops = 'ainv.clearDrops',
        rebind = 'ainv.rebind'
    },
    groups = {
        inspect = {'admin', 'god'},
        clearDrops = {'admin', 'god'},
        rebind = {'admin', 'god', 'mod'}
    }
}

Config.Localization = {
    default = 'en',
    supported = {'en', 'bg'}
}
