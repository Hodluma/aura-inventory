local QBCore = exports['qb-core']:GetCoreObject()

local drops = {}

local function dropsList()
    local list = {}
    for _, drop in pairs(drops) do
        list[#list+1] = drop
    end
    return list
end

RegisterNetEvent('aura-inventory:client:dropCreated', function(data)
    drops[data.id] = data
    SendNUIMessage({action = 'drops', data = dropsList()})
end)

RegisterNetEvent('aura-inventory:client:dropRemoved', function(id)
    drops[id] = nil
    SendNUIMessage({action = 'drops', data = dropsList()})
end)

CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for id, drop in pairs(drops) do
            local dropCoords = vector3(drop.coords[1], drop.coords[2], drop.coords[3])
            local dist = #(coords - dropCoords)
            if dist < Config.Settings.groundDrop.pickupDistance then
                DrawText3D(dropCoords.x, dropCoords.y, dropCoords.z + 0.2, '[E] Pickup '..drop.item.name)
                if IsControlJustPressed(0, 38) then
                    TriggerServerEvent('aura-inventory:pickupDrop', id)
                end
            elseif dist > Config.Settings.groundDrop.dropDistance then
                drops[id] = nil
            end
        end
    end
end)

function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end
