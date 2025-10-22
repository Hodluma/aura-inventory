Config = Config or {}
Config.Stashes = {
    police_armory = {
        label = 'Police Armory',
        coords = vector3(452.6, -980.0, 30.6),
        maxWeight = 500.0,
        maxSlots = 100,
        access = {
            jobs = {
                {name = 'police', grade = 0}
            }
        }
    },
    burger_shot = {
        label = 'Burger Shot Pantry',
        coords = vector3(-1192.0, -892.8, 13.9),
        maxWeight = 250.0,
        maxSlots = 50,
        access = {
            jobs = {
                {name = 'burgershot', grade = 0}
            }
        }
    }
}
