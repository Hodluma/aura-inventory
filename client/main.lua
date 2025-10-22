local QBCore = exports['qb-core']:GetCoreObject()
local isOpen = false
local hotbarVisible = false
local lastHotbarUse = 0

local function toggleInventory(state)
    isOpen = state
    SetNuiFocus(state, state)
    SendNUIMessage({action = 'openInventory', data = {open = state}})
    if state then
        QBCore.Functions.TriggerCallback('aura-inventory:getInventory', function(data)
            SendNUIMessage({action = 'openInventory', data = {state = data}})
        end)
    end
end

RegisterKeyMapping('aura_inventory', 'Open inventory', 'keyboard', Config.Settings.keybinds.inventory)
RegisterCommand('aura_inventory', function()
    toggleInventory(not isOpen)
end, false)

RegisterKeyMapping('aura_hotbar_overlay', 'Toggle hotbar overlay', 'keyboard', Config.Settings.keybinds.hotbarOverlay)
RegisterCommand('aura_hotbar_overlay', function()
    hotbarVisible = not hotbarVisible
    SendNUIMessage({action = 'hotbar', data = {visible = hotbarVisible}})
end, false)

for index, key in ipairs(Config.Settings.keybinds.hotbarSlots) do
    local command = ('aura_hotbar_%s'):format(index)
    RegisterKeyMapping(command, ('Use hotbar slot %s'):format(index), 'keyboard', key)
    RegisterCommand(command, function()
        if (GetGameTimer() - lastHotbarUse) < Config.Settings.hotbarCooldownMs then return end
        lastHotbarUse = GetGameTimer()
        TriggerServerEvent('aura-inventory:useItem', index)
        SendNUIMessage({action = 'hotbarUse', data = {slot = index}})
    end, false)
end

RegisterNUICallback('close', function(_, cb)
    toggleInventory(false)
    cb('ok')
end)

RegisterNUICallback('moveItem', function(data, cb)
    TriggerServerEvent('aura-inventory:moveItem', data)
    cb('ok')
end)

RegisterNUICallback('splitStack', function(data, cb)
    TriggerServerEvent('aura-inventory:splitStack', data)
    cb('ok')
end)

RegisterNUICallback('useItem', function(data, cb)
    TriggerServerEvent('aura-inventory:useItem', data.slot)
    cb('ok')
end)

RegisterNUICallback('dropItem', function(data, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    data.coords = coords
    TriggerServerEvent('aura-inventory:dropItem', data)
    cb('ok')
end)

RegisterNUICallback('hotbarUpdate', function(data, cb)
    TriggerServerEvent('aura-inventory:hotbarUpdate', data)
    cb('ok')
end)

RegisterNUICallback('craftStart', function(data, cb)
    TriggerServerEvent('aura-inventory:craftStart', data.recipeId, data.stationId)
    cb('ok')
end)

RegisterNUICallback('attach', function(data, cb)
    TriggerServerEvent('aura-inventory:attach', data.weaponSlot, data.attachmentSlot, data.key)
    cb('ok')
end)

RegisterNUICallback('detach', function(data, cb)
    TriggerServerEvent('aura-inventory:detach', data.weaponSlot, data.attachmentType)
    cb('ok')
end)

RegisterNUICallback('shopBuy', function(data, cb)
    TriggerServerEvent('aura-inventory:shopBuy', data.shopId, data.itemName, data.amount)
    cb('ok')
end)

RegisterNUICallback('shopSell', function(data, cb)
    TriggerServerEvent('aura-inventory:shopSell', data.shopId, data.itemName, data.amount)
    cb('ok')
end)

RegisterNUICallback('pickupDrop', function(data, cb)
    TriggerServerEvent('aura-inventory:pickupDrop', data.dropId)
    cb('ok')
end)

RegisterNetEvent('aura-inventory:client:state', function(state, hotbar)
    SendNUIMessage({action = 'state', data = state})
    if hotbar then
        SendNUIMessage({action = 'hotbar', data = hotbar})
    end
end)

RegisterNetEvent('aura-inventory:client:moveResult', function(ok, data)
    if ok then
        SendNUIMessage({action = 'state', data = data})
    else
        QBCore.Functions.Notify(('Move failed: %s'):format(data), 'error')
    end
end)

RegisterNetEvent('aura-inventory:client:hotbar', function(data)
    SendNUIMessage({action = 'hotbar', data = data})
end)

RegisterNetEvent('aura-inventory:client:splitResult', function(ok, data)
    if ok then
        SendNUIMessage({action = 'state', data = data})
    else
        QBCore.Functions.Notify(('Split failed: %s'):format(data), 'error')
    end
end)

RegisterNetEvent('aura-inventory:client:useResult', function(ok, data)
    if not ok then
        QBCore.Functions.Notify(('Use failed: %s'):format(data), 'error')
    end
end)

RegisterNetEvent('aura-inventory:client:dropResult', function(ok, data)
    if ok then
        QBCore.Functions.Notify('Dropped item.', 'success')
    else
        QBCore.Functions.Notify(('Drop failed: %s'):format(data), 'error')
    end
end)

RegisterNetEvent('aura-inventory:client:pickupResult', function(ok, data)
    if ok then
        QBCore.Functions.Notify('Picked up item.', 'success')
    else
        QBCore.Functions.Notify(('Pickup failed: %s'):format(data), 'error')
    end
end)

RegisterNetEvent('aura-inventory:client:craftResult', function(ok, reason)
    if not ok then
        QBCore.Functions.Notify(('Craft failed: %s'):format(reason), 'error')
    end
end)

RegisterNetEvent('aura-inventory:client:attachResult', function(ok, reason)
    if ok then
        QBCore.Functions.Notify('Attachment applied.', 'success')
    else
        QBCore.Functions.Notify(('Attachment failed: %s'):format(reason), 'error')
    end
end)

RegisterNetEvent('aura-inventory:client:detachResult', function(ok, reason)
    if ok then
        QBCore.Functions.Notify('Attachment removed.', 'success')
    else
        QBCore.Functions.Notify(('Detach failed: %s'):format(reason), 'error')
    end
end)

RegisterNetEvent('aura-inventory:client:shopResult', function(ok, reason)
    if ok then
        QBCore.Functions.Notify('Shop transaction complete.', 'success')
    else
        QBCore.Functions.Notify(('Shop failed: %s'):format(reason), 'error')
    end
end)

RegisterNetEvent('aura-inventory:client:inspect', function(state)
    SendNUIMessage({action = 'inspect', data = state})
end)

RegisterNetEvent('aura-inventory:client:rebind', function(key, action)
    if action == 'inventory' then
        RegisterKeyMapping('aura_inventory', 'Open inventory', 'keyboard', key)
    elseif action == 'hotbar' then
        RegisterKeyMapping('aura_hotbar_overlay', 'Toggle hotbar overlay', 'keyboard', key)
    else
        local slot = tonumber(action)
        if slot then
            RegisterKeyMapping(('aura_hotbar_%s'):format(slot), ('Use hotbar slot %s'):format(slot), 'keyboard', key)
        end
    end
    QBCore.Functions.Notify(('Bound %s to %s'):format(action, key), 'success')
end)

RegisterNetEvent('aura-inventory:client:equipWeapon', function(weaponName, slot, metadata)
    GiveWeaponToPed(PlayerPedId(), joaat(weaponName), 0, false, true)
end)

RegisterNetEvent('aura-inventory:client:loadAmmo', function(weaponName, amount)
    AddAmmoToPed(PlayerPedId(), joaat(weaponName), amount)
end)

CreateThread(function()
    while true do
        Wait(60000)
        if isOpen then
            TriggerServerEvent('aura-inventory:requestState')
        end
    end
end)
