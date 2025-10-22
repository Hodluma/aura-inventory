local QBCore = exports['qb-core']:GetCoreObject()

local function openNearbyStation()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    for id, station in pairs(Config.Crafting.stations) do
        if #(coords - station.coords) <= station.radius then
            local recipes = {}
            for _, recipeId in ipairs(station.recipes or {}) do
                local recipe = Config.Crafting.recipes[recipeId]
                if recipe then
                    table.insert(recipes, recipe)
                end
            end
            SendNUIMessage({action = 'craftingStation', data = {id = id, label = station.label, recipes = recipes}})
            return
        end
    end
end

RegisterCommand('ainv_craft', function()
    openNearbyStation()
end, false)
RegisterKeyMapping('ainv_craft', 'Open crafting when near station', 'keyboard', 'K')

CreateThread(function()
    while true do
        Wait(1000)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for id, stash in pairs(Config.Stashes) do
            if #(coords - stash.coords) < 2.0 then
                SendNUIMessage({action = 'prompt', data = {type = 'stash', id = id, label = stash.label}})
            end
        end
    end
end)
