local QBCore = exports['qb-core']:GetCoreObject()

local Bridge = {}

function Bridge.GetPlayer(src)
    return QBCore.Functions.GetPlayer(src)
end

function Bridge.GetPlayerByCitizenId(citizenid)
    return QBCore.Functions.GetPlayerByCitizenId(citizenid)
end

function Bridge.GetPlayerData(src)
    local Player = Bridge.GetPlayer(src)
    return Player and Player.PlayerData or nil
end

function Bridge.AddItem(src, item, amount, slot, metadata)
    local Player = Bridge.GetPlayer(src)
    if not Player then return false, 'player_not_found' end
    local success, reason = Player.Functions.AddItem(item, amount, slot, metadata)
    if not success then
        return false, reason or 'add_failed'
    end
    return true
end

function Bridge.RemoveItem(src, item, amount, slot)
    local Player = Bridge.GetPlayer(src)
    if not Player then return false, 'player_not_found' end
    local success = Player.Functions.RemoveItem(item, amount, slot)
    if not success then
        return false, 'remove_failed'
    end
    return true
end

function Bridge.SetInventory(src, items)
    local Player = Bridge.GetPlayer(src)
    if not Player then return false, 'player_not_found' end
    Player.Functions.SetInventory(items)
    return true
end

function Bridge.GetInventory(src)
    local Player = Bridge.GetPlayer(src)
    if not Player then return nil end
    return Player.PlayerData.items or {}
end

function Bridge.SavePlayer(src)
    local Player = Bridge.GetPlayer(src)
    if Player then
        Player.Functions.Save()
    end
end

function Bridge.Notify(src, message, type)
    TriggerClientEvent('QBCore:Notify', src, message, type or 'primary')
end

function Bridge.ProgressBar(src, label, duration, options, cb)
    TriggerClientEvent('QBCore:Client:OnPlayerProgress', src, label, duration, options or {})
    if cb then
        SetTimeout(duration, function()
            cb(true)
        end)
    end
end

return Bridge
