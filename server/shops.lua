local Utils = require 'shared/utils'
local Bridge = require 'shared/bridge_qb'
local Logs = require 'server/logs'

local Shops = {}
Shops.state = {}

local function initShops()
    for id, shop in pairs(Config.Shops) do
        Shops.state[id] = {
            stock = {},
            lastRefresh = os.time()
        }
        for _, item in ipairs(shop.items) do
            Shops.state[id].stock[item.name] = item.stock
        end
    end
end

initShops()

local function refreshShop(id)
    local shop = Config.Shops[id]
    if not shop then return end
    local state = Shops.state[id]
    local now = os.time()
    if now - state.lastRefresh >= (shop.refreshMinutes * 60) then
        for _, item in ipairs(shop.items) do
            state.stock[item.name] = item.stock
        end
        state.lastRefresh = now
    end
end

local function hasAccess(playerData, shop)
    if shop.whitelist and #shop.whitelist > 0 then
        local job = playerData.job
        for _, entry in ipairs(shop.whitelist) do
            if job and job.name == entry then
                return true
            end
        end
        return false
    end
    if shop.blacklist and #shop.blacklist > 0 then
        local job = playerData.job
        for _, entry in ipairs(shop.blacklist) do
            if job and job.name == entry then
                return false
            end
        end
    end
    return true
end

local function getItem(shop, name)
    for _, item in ipairs(shop.items) do
        if item.name == name then return item end
    end
    return nil
end

function Shops.HandleBuy(src, shopId, itemName, amount)
    local shop = Config.Shops[shopId]
    if not shop then return false, 'invalid_shop' end
    refreshShop(shopId)
    local Player = Bridge.GetPlayer(src)
    if not Player then return false, 'player_not_found' end
    if not hasAccess(Player.PlayerData, shop) then return false, 'no_access' end

    local amount = tonumber(amount)
    if not amount or amount <= 0 then return false, 'invalid_amount' end

    local item = getItem(shop, itemName)
    if not item then return false, 'invalid_item' end

    local state = Shops.state[shopId]
    local stock = state.stock[itemName] or 0
    if stock < amount then return false, 'out_of_stock' end

    local price = math.floor(item.price * amount * (1 + (shop.tax or 0)))
    local removed = Player.Functions.RemoveMoney('cash', price)
    if not removed then
        return false, 'insufficient_funds'
    end

    local itemCfg = Config.Items[itemName]
    if not itemCfg then return false, 'unknown_item' end

    local metadata = Utils.DeepCopy(itemCfg.metadata)
    local success, addReason = Bridge.AddItem(src, itemName, amount, nil, metadata)
    if not success then
        Player.Functions.AddMoney('cash', price)
        Logs.Write('shop_buy', {player = {src = src}, ok = false, item = itemName, qty = amount, reason = addReason or 'inventory_full'})
        return false, addReason or 'inventory_full'
    end

    state.stock[itemName] = stock - amount
    Logs.Write('shop_buy', {player = {src = src}, ok = true, item = itemName, qty = amount, meta = {price = price}})
    return true
end

function Shops.HandleSell(src, shopId, itemName, amount)
    local shop = Config.Shops[shopId]
    if not shop then return false, 'invalid_shop' end
    refreshShop(shopId)
    local Player = Bridge.GetPlayer(src)
    if not Player then return false, 'player_not_found' end
    if not hasAccess(Player.PlayerData, shop) then return false, 'no_access' end

    amount = tonumber(amount)
    if not amount or amount <= 0 then return false, 'invalid_amount' end

    local item = getItem(shop, itemName)
    if not item then return false, 'invalid_item' end

    local Inventory = require 'server/inventory'
    local items, cache = Inventory.LoadPlayer(src)
    local sold = 0
    for slot, invItem in pairs(items) do
        if invItem.name == itemName then
            local take = math.min(invItem.amount, amount - sold)
            invItem.amount = invItem.amount - take
            sold = sold + take
            if invItem.amount <= 0 then
                items[slot] = nil
            end
            if sold >= amount then break end
        end
    end
    if sold <= 0 then return false, 'no_item' end

    Inventory.SavePlayer(src)
    local payout = math.floor(item.price * sold * 0.5)
    Player.Functions.AddMoney('cash', payout)
    local state = Shops.state[shopId]
    state.stock[itemName] = (state.stock[itemName] or 0) + sold
    Logs.Write('shop_sell', {player = {src = src}, ok = true, item = itemName, qty = sold, meta = {payout = payout}})
    return true
end

return Shops
