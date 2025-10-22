local QBCore = exports['qb-core']:GetCoreObject()
local Bridge = require 'shared/bridge_qb'
local Inventory = require 'server/inventory'
local Containers = require 'server/containers'
local Crafting = require 'server/crafting'
local Weapons = require 'server/weapons'
local Shops = require 'server/shops'
local Logs = require 'server/logs'
local Utils = require 'shared/utils'

local json = require 'json'

local function sendState(src)
    local state = Inventory.GetState(src)
    if not state then return end
    TriggerClientEvent('aura-inventory:client:state', src, state, Weapons.hotbar[src])
end

local function hasGroup(Player, groups)
    if not groups or #groups == 0 then return true end
    local job = Player.PlayerData.job
    local gang = Player.PlayerData.gang
    for _, group in ipairs(groups) do
        if job and job.name == group then return true end
        if gang and gang.name == group then return true end
    end
    return false
end

RegisterNetEvent('QBCore:Server:PlayerLoaded', function(player)
    local src = player.PlayerData.source
    Inventory.LoadPlayer(src)
end)

RegisterNetEvent('QBCore:Server:OnPlayerUnload', function(src)
    Inventory.SavePlayer(src)
end)

QBCore.Commands.Add(Config.Admin.commands.inspect, 'Inspect a player inventory', {{name = 'id', help = 'Server ID'}}, true, function(source, args)
    local target = tonumber(args[1])
    if not target then return end
    local Player = Bridge.GetPlayer(source)
    if not Player or not hasGroup(Player, Config.Admin.groups.inspect) then return end
    local state = Inventory.GetState(target)
    if state then
        TriggerClientEvent('aura-inventory:client:inspect', source, state)
    end
end)

QBCore.Commands.Add(Config.Admin.commands.clearDrops, 'Clear all ground drops', {}, false, function(source)
    local Player = Bridge.GetPlayer(source)
    if not Player or not hasGroup(Player, Config.Admin.groups.clearDrops) then return end
    MySQL.query.await('DELETE FROM aura_ground_drops')
    Logs.Write('clear_drops', {player = {src = source}, ok = true})
end)

QBCore.Commands.Add(Config.Admin.commands.rebind, 'Rebind inventory hotkeys', {
    {name = 'key', help = 'Key code'},
    {name = 'action', help = 'inventory/hotbar/slot'}
}, false, function(source, args)
    local Player = Bridge.GetPlayer(source)
    if not Player or not hasGroup(Player, Config.Admin.groups.rebind) then return end
    TriggerClientEvent('aura-inventory:client:rebind', source, args[1], args[2])
end)

QBCore.Functions.CreateCallback('aura-inventory:getInventory', function(source, cb)
    local state = Inventory.GetState(source)
    cb(state)
end)

QBCore.Functions.CreateCallback('aura-inventory:openContainer', function(source, cb, id)
    local ok, data = Containers.Open(source, id)
    cb(ok and data or nil, ok and nil or data)
end)

RegisterNetEvent('aura-inventory:moveItem', function(payload)
    local src = source
    local ok, data = Inventory.HandleMove(src, payload)
    TriggerClientEvent('aura-inventory:client:moveResult', src, ok, data)
end)

RegisterNetEvent('aura-inventory:splitStack', function(payload)
    local src = source
    local ok, data = Inventory.HandleSplit(src, payload)
    TriggerClientEvent('aura-inventory:client:splitResult', src, ok, data)
end)

RegisterNetEvent('aura-inventory:useItem', function(slot)
    local src = source
    local ok, data = Inventory.HandleUse(src, slot)
    TriggerClientEvent('aura-inventory:client:useResult', src, ok, data)
end)

RegisterNetEvent('aura-inventory:dropItem', function(payload)
    local src = source
    local ok, data = Inventory.HandleDrop(src, payload)
    TriggerClientEvent('aura-inventory:client:dropResult', src, ok, data)
end)

RegisterNetEvent('aura-inventory:pickupDrop', function(dropId)
    local src = source
    local ok, data = Inventory.HandlePickup(src, dropId)
    TriggerClientEvent('aura-inventory:client:pickupResult', src, ok, data)
end)

RegisterNetEvent('aura-inventory:craftStart', function(recipeId, stationId)
    local src = source
    local ok, reason = Crafting.Start(src, stationId, recipeId)
    TriggerClientEvent('aura-inventory:client:craftResult', src, ok, reason)
end)

RegisterNetEvent('aura-inventory:attach', function(weaponSlot, attachmentSlot, attachmentKey)
    local src = source
    local ok, reason = Weapons.Attach(src, weaponSlot, attachmentSlot, attachmentKey)
    TriggerClientEvent('aura-inventory:client:attachResult', src, ok, reason)
end)

RegisterNetEvent('aura-inventory:detach', function(weaponSlot, attachmentType)
    local src = source
    local ok, reason = Weapons.Detach(src, weaponSlot, attachmentType)
    TriggerClientEvent('aura-inventory:client:detachResult', src, ok, reason)
end)

RegisterNetEvent('aura-inventory:shopBuy', function(shopId, itemName, amount)
    local src = source
    local ok, reason = Shops.HandleBuy(src, shopId, itemName, amount)
    TriggerClientEvent('aura-inventory:client:shopResult', src, ok, reason)
end)

RegisterNetEvent('aura-inventory:shopSell', function(shopId, itemName, amount)
    local src = source
    local ok, reason = Shops.HandleSell(src, shopId, itemName, amount)
    TriggerClientEvent('aura-inventory:client:shopResult', src, ok, reason)
end)

RegisterNetEvent('aura-inventory:hotbarUpdate', function(payload)
    local src = source
    local data = Weapons.hotbar[src] or { slots = {}, active = 1 }
    if payload.itemSlot and payload.slot then
        data.slots = data.slots or {}
        data.slots[tonumber(payload.slot)] = payload.itemSlot
    end
    if payload.active then
        data.active = payload.active
        data.activeWeapon = payload.weapon or data.activeWeapon
    end
    Weapons.hotbar[src] = data
    TriggerClientEvent('aura-inventory:client:hotbar', src, data)
end)

RegisterNetEvent('aura-inventory:weaponFired', function()
    local src = source
    local hotbar = Weapons.hotbar[src] or {}
    local active = hotbar.activeWeapon
    if active then
        Weapons.ReduceDurability(src, active, 1)
    end
end)

AddEventHandler('playerDropped', function(reason)
    local src = source
    Inventory.SavePlayer(src)
    Weapons.hotbar[src] = nil
end)

RegisterNetEvent('aura-inventory:requestState', function()
    local src = source
    sendState(src)
end)

CreateThread(function()
    while true do
        Wait(60000)
        local expiry = Config.Settings.groundDrop.despawnMinutes
        MySQL.query.await('DELETE FROM aura_ground_drops WHERE TIMESTAMPDIFF(MINUTE, created_at, NOW()) > ?', {expiry})
    end
end)

return {}
