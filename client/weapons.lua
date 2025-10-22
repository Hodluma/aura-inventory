local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('aura-inventory:client:attachmentApplied', function(slot, attachmentType)
    QBCore.Functions.Notify(('Attachment %s applied.'):format(attachmentType), 'success')
end)

RegisterNetEvent('aura-inventory:client:attachmentRemoved', function(slot, attachmentType)
    QBCore.Functions.Notify(('Attachment %s removed.'):format(attachmentType), 'error')
end)

local shooting = false

CreateThread(function()
    while true do
        Wait(0)
        if IsPedShooting(PlayerPedId()) then
            if not shooting then
                shooting = true
                TriggerServerEvent('aura-inventory:weaponFired')
            end
        else
            shooting = false
            Wait(200)
        end
    end
end)
