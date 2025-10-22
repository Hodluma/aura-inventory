local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('aura-inventory:client:openContainer', function(data)
    SendNUIMessage({action = 'openContainer', data = data})
end)

RegisterNetEvent('aura-inventory:client:notify', function(message, type)
    SendNUIMessage({action = 'notify', data = {message = message, type = type}})
    QBCore.Functions.Notify(message, type)
end)

RegisterNetEvent('aura-inventory:nui:openAttachments', function(data)
    SendNUIMessage({action = 'attachments', data = data})
end)

RegisterNUICallback('requestContainer', function(data, cb)
    QBCore.Functions.TriggerCallback('aura-inventory:openContainer', function(container, err)
        if container then
            SendNUIMessage({action = 'openContainer', data = container})
        else
            QBCore.Functions.Notify(('Container failed: %s'):format(err), 'error')
        end
        cb('ok')
    end, data.id)
end)
