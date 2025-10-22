Config = Config or {}
Config.Shops = {
    general = {
        label = '24/7 Convenience',
        ped = 'mp_m_shopkeep_01',
        coords = vector3(25.7, -1347.3, 29.5),
        heading = 270.0,
        items = {
            {name = 'water', price = 5, stock = 50, max = 5},
            {name = 'bread', price = 7, stock = 50, max = 5},
            {name = 'bandage', price = 35, stock = 25, max = 5}
        },
        tax = 0.07,
        refreshMinutes = 60,
        whitelist = {},
        blacklist = {}
    },
    ammunation = {
        label = 'Ammu-Nation',
        ped = 's_m_y_ammucity_01',
        coords = vector3(22.0, -1106.9, 29.8),
        heading = 155.0,
        items = {
            {name = 'ammo_9mm', price = 35, stock = 200, max = 10},
            {name = 'ammo_rifle', price = 55, stock = 150, max = 10},
            {name = 'pistol', price = 1800, stock = 5, max = 1}
        },
        tax = 0.12,
        refreshMinutes = 120,
        whitelist = {},
        blacklist = {}
    }
}
