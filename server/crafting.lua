local Utils = require 'shared/utils'
local Bridge = require 'shared/bridge_qb'
local Logs = require 'server/logs'

local Crafting = {}
Crafting.active = {}

local function hasRequirement(req, playerData)
    if not req then return true end
    if req.job then
        local job = playerData.job
        if not job or job.name ~= req.job.name or job.grade.level < (req.job.grade or 0) then
            return false
        end
    end
    if req.gang then
        local gang = playerData.gang
        if not gang or gang.name ~= req.gang.name or gang.grade.level < (req.gang.grade or 0) then
            return false
        end
    end
    if req.level and (playerData.metadata.level or 0) < req.level then
        return false
    end
    return true
end

local function hasTools(inv, tools)
    if not tools or #tools == 0 then return true end
    local lookup = {}
    for _, item in pairs(inv) do
        if item then
            lookup[item.name] = (lookup[item.name] or 0) + item.amount
        end
    end
    for _, tool in ipairs(tools) do
        if not lookup[tool] then return false end
    end
    return true
end

function Crafting.GetStation(stationId)
    return Config.Crafting.stations[stationId]
end

local function consumeInputs(inv, inputs)
    local function findItem(name, qty)
        for slot, item in pairs(inv) do
            if item and item.name == name and item.amount >= qty then
                return slot
            end
        end
        return nil
    end

    local consumed = {}
    for _, input in ipairs(inputs) do
        local slot = findItem(input.name, input.qty)
        if not slot then
            return false, 'missing_input'
        end
        inv[slot].amount = inv[slot].amount - input.qty
        table.insert(consumed, {slot = slot, name = input.name, qty = input.qty})
        if inv[slot].amount <= 0 then
            inv[slot] = nil
        end
    end
    return true, consumed
end

local function giveOutputs(inv, outputs)
    for _, output in ipairs(outputs) do
        local ok, reason = Crafting.AddItem(inv, output.name, output.qty, output.metadata)
        if not ok then
            return false, reason
        end
    end
    return true
end

function Crafting.AddItem(inv, name, amount, metadata)
    local itemCfg = Config.Items[name]
    if not itemCfg then return false, 'unknown_item' end
    for slot = 1, Config.Settings.maxSlots do
        local item = inv[slot]
        if item and item.name == name then
            local maxStack = itemCfg.maxStack or 1
            if item.amount + amount <= maxStack then
                item.amount = item.amount + amount
                item.metadata = Utils.MergeMetadata(item.metadata, metadata)
                return true
            end
        end
    end
    for slot = 1, Config.Settings.maxSlots do
        if not inv[slot] then
            inv[slot] = {
                name = name,
                amount = amount,
                slot = slot,
                metadata = Utils.MergeMetadata(itemCfg.metadata, metadata)
            }
            return true
        end
    end
    return false, 'inventory_full'
end

function Crafting.Start(src, stationId, recipeId)
    local Player = Bridge.GetPlayer(src)
    if not Player then return false, 'player_not_found' end
    local station = Crafting.GetStation(stationId)
    if not station then return false, 'invalid_station' end
    local recipe = Config.Crafting.recipes[recipeId]
    if not recipe or recipe.stationType ~= stationId then return false, 'invalid_recipe' end

    if not hasRequirement(recipe.requirements, Player.PlayerData) then
        return false, 'requirements_not_met'
    end

    local Inventory = require 'server/inventory'
    local items, cache = Inventory.LoadPlayer(src)

    if not hasTools(items, recipe.requirements and recipe.requirements.tools or {}) then
        return false, 'missing_tools'
    end

    local ok, consumed = consumeInputs(items, recipe.inputs)
    if not ok then return false, consumed end

    local duration = recipe.timeMs or 5000

    Bridge.ProgressBar(src, recipe.label, duration, {canCancel = true}, function(success)
        if not success then
            for _, entry in ipairs(consumed) do
                Crafting.AddItem(items, entry.name, entry.qty)
            end
            return
        end
        local failChance = recipe.failChance or 0
        local passed = math.random() >= failChance
        if not passed then
            Logs.Write('craft_fail', {player = {src = src}, ok = false, item = recipeId, reason = 'fail_chance'})
            return
        end
        local giveOk, reason = giveOutputs(items, recipe.outputs)
        if not giveOk then
            Logs.Write('craft_fail', {player = {src = src}, ok = false, item = recipeId, reason = reason})
            return
        end
        cache.weight = nil
        Inventory.SavePlayer(src)
        TriggerClientEvent('aura-inventory:client:state', src, Inventory.GetState(src), nil)
        Logs.Write('craft', {player = {src = src}, ok = true, item = recipeId})
        TriggerClientEvent('aura-inventory:craftCompleted', src, recipeId)
    end)

    return true
end

return Crafting
