local Utils = require 'shared/utils'
local Bridge = require 'shared/bridge_qb'
local Logs = require 'server/logs'
local json = require 'json'

local Inventory = {}
Inventory.cache = {}

local function ensureTables()
    MySQL.ready(function()
        MySQL.query([[CREATE TABLE IF NOT EXISTS aura_inventories (
            citizenid VARCHAR(50) PRIMARY KEY,
            items LONGTEXT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )]])
        MySQL.query([[CREATE TABLE IF NOT EXISTS aura_ground_drops (
            id VARCHAR(64) PRIMARY KEY,
            data LONGTEXT NULL,
            coords VARCHAR(128) NOT NULL,
            owner VARCHAR(50) NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )]])
        MySQL.query([[CREATE TABLE IF NOT EXISTS aura_inventory_logs (
            id INT AUTO_INCREMENT PRIMARY KEY,
            payload LONGTEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )]])
    end)
end

ensureTables()

local function rateLimitKey(src, action)
    return ('%s:%s'):format(src, action)
end

Inventory.rateBuckets = {}

local function checkRateLimit(src, action)
    local cfg = Config.Settings.rateLimits[action]
    if not cfg then return true end
    local key = rateLimitKey(src, action)
    local bucket = Inventory.rateBuckets[key] or {tokens = cfg.bucket, last = os.time()}
    local now = os.time()
    if now > bucket.last then
        local refill = (now - bucket.last) * cfg.refill
        bucket.tokens = math.min(cfg.bucket, bucket.tokens + refill)
        bucket.last = now
    end
    if bucket.tokens < 1 then
        return false
    end
    bucket.tokens = bucket.tokens - 1
    Inventory.rateBuckets[key] = bucket
    return true
end

local function inventoryWeight(inv)
    local weight = 0
    for _, item in pairs(inv) do
        if item and item.name and item.amount then
            weight = weight + Utils.GetWeight(item.name, item.amount)
        end
    end
    return weight
end

local function ensureSlotStructure(inv)
    local normalized = {}
    for slot, item in pairs(inv) do
        normalized[tonumber(slot)] = item
    end
    return normalized
end

function Inventory.LoadPlayer(src)
    local Player = Bridge.GetPlayer(src)
    if not Player then return nil, 'player_not_found' end
    local citizenid = Player.PlayerData.citizenid
    local cache = Inventory.cache[citizenid]
    if cache then return ensureSlotStructure(cache.items), cache end
    local result = MySQL.single.await('SELECT items FROM aura_inventories WHERE citizenid = ?', {citizenid})
    local items = {}
    if result and result.items then
        items = Utils.Deserialize(result.items) or {}
    else
        MySQL.insert.await('INSERT INTO aura_inventories (citizenid, items) VALUES (?, ?)', {citizenid, Utils.Serialize({})})
    end
    items = ensureSlotStructure(items)
    local data = {items = items, weight = inventoryWeight(items)}
    Inventory.cache[citizenid] = data
    return items, data
end

local function saveCitizen(citizenid)
    local cache = Inventory.cache[citizenid]
    if not cache then return end
    MySQL.update.await('UPDATE aura_inventories SET items = ? WHERE citizenid = ?', {Utils.Serialize(cache.items), citizenid})
end

function Inventory.SavePlayer(src)
    local Player = Bridge.GetPlayer(src)
    if not Player then return end
    local citizenid = Player.PlayerData.citizenid
    saveCitizen(citizenid)
end

local function ensureCapacity(inv, meta, name, amount)
    meta = meta or {}
    local mode = Config.Settings.capacityMode
    local maxSlots = meta.maxSlots or Config.Settings.maxSlots
    local maxWeight = meta.maxWeight or Config.Settings.maxWeight
    if mode == 'slots' then
        local count = 0
        for _, item in pairs(inv) do
            if item and item.name then count = count + 1 end
        end
        if count >= maxSlots then
            return false, 'slot_limit'
        end
        return true
    else
        local newWeight = inventoryWeight(inv) + Utils.GetWeight(name, amount)
        if newWeight > maxWeight then
            return false, 'weight_limit'
        end
        return true
    end
end

local function getFreeSlot(inv, meta)
    local limit = (meta and meta.maxSlots) or Config.Settings.maxSlots
    for i = 1, limit do
        if not inv[i] then return i end
    end
    return nil
end

local function addItem(inv, name, amount, metadata, slot, meta)
    local itemCfg = Config.Items[name]
    if not itemCfg then return false, 'unknown_item' end
    local targetSlot = slot or getFreeSlot(inv, meta)
    if not targetSlot then return false, 'inventory_full' end
    local stackMax = itemCfg.maxStack or 1
    local existing = inv[targetSlot]
    if existing then
        if existing.name ~= name then return false, 'slot_occupied' end
        if (existing.amount + amount) > stackMax then
            return false, 'stack_overflow'
        end
        existing.amount = existing.amount + amount
        existing.metadata = Utils.MergeMetadata(existing.metadata, metadata)
        existing.category = existing.category or itemCfg.category
        existing.label = existing.label or itemCfg.label
        existing.description = existing.description or itemCfg.description
    else
        local ok, reason = ensureCapacity(inv, meta, name, amount)
        if not ok then return false, reason end
        inv[targetSlot] = {
            name = name,
            amount = amount,
            slot = targetSlot,
            metadata = Utils.MergeMetadata(itemCfg.metadata, metadata),
            category = itemCfg.category,
            label = itemCfg.label,
            description = itemCfg.description,
            weight = itemCfg.weight
        }
    end
    return true
end

local function removeItem(inv, slot, amount)
    local item = inv[slot]
    if not item then return false, 'no_item' end
    if item.amount < amount then
        return false, 'insufficient_amount'
    end
    item.amount = item.amount - amount
    if item.amount <= 0 then
        inv[slot] = nil
    end
    return true, item
end

local function moveBetween(invFrom, metaFrom, slotFrom, invTo, metaTo, slotTo, amount)
    local item = invFrom[slotFrom]
    if not item then return false, 'no_item' end
    amount = amount or item.amount
    if amount <= 0 then return false, 'invalid_amount' end
    if item.amount < amount then return false, 'insufficient_amount' end

    local cfg = Config.Items[item.name]
    if not cfg then return false, 'unknown_item' end

    if slotTo then
        local target = invTo[slotTo]
        if target then
            if target.name ~= item.name then return false, 'slot_occupied' end
            local maxStack = cfg.maxStack or 1
            if (target.amount + amount) > maxStack then
                return false, 'stack_overflow'
            end
        else
            local ok, reason = ensureCapacity(invTo, metaTo, item.name, amount)
            if not ok then return false, reason end
        end
    else
        local ok, reason = ensureCapacity(invTo, metaTo, item.name, amount)
        if not ok then return false, reason end
        slotTo = getFreeSlot(invTo, metaTo)
        if not slotTo then return false, 'inventory_full' end
    end

    local targetItem = invTo[slotTo]
    if targetItem then
        targetItem.amount = targetItem.amount + amount
    else
        invTo[slotTo] = {
            name = item.name,
            amount = amount,
            slot = slotTo,
            metadata = Utils.DeepCopy(item.metadata),
            category = item.category,
            label = item.label,
            description = item.description,
            weight = item.weight
        }
    end

    item.amount = item.amount - amount
    if item.amount <= 0 then
        invFrom[slotFrom] = nil
    end

    return true, slotTo
end

function Inventory.HandleMove(src, payload)
    if not checkRateLimit(src, 'moveItem') then
        return false, 'rate_limited'
    end
    local fromInv = payload.fromInventory
    local toInv = payload.toInventory
    local fromSlot = tonumber(payload.fromSlot)
    local toSlot = payload.toSlot and tonumber(payload.toSlot) or nil
    local amount = payload.amount and tonumber(payload.amount)

    if not fromSlot then return false, 'invalid_slot' end

    local Player = Bridge.GetPlayer(src)
    if not Player then return false, 'player_not_found' end
    local citizenid = Player.PlayerData.citizenid
    local cache = Inventory.cache[citizenid]
    if not cache then
        Inventory.LoadPlayer(src)
        cache = Inventory.cache[citizenid]
    end
    local mainInv = cache.items

    local srcInv = mainInv
    local dstInv = mainInv
    local srcMeta = {maxSlots = Config.Settings.maxSlots, maxWeight = Config.Settings.maxWeight}
    local dstMeta = srcMeta
    local container
    if fromInv == 'container' or toInv == 'container' then
        local Container = require 'server/containers'
        local containerId = payload.containerId
        if not containerId then return false, 'missing_container' end
        container = Container.Get(containerId)
        if not container then return false, 'container_not_found' end
        if fromInv == 'container' then
            srcInv = container.items
            srcMeta = {maxSlots = container.maxSlots, maxWeight = container.maxWeight}
        end
        if toInv == 'container' then
            dstInv = container.items
            dstMeta = {maxSlots = container.maxSlots, maxWeight = container.maxWeight}
        end
        local ok = Container.ValidateAccess(src, container)
        if not ok then return false, 'no_access' end
    end

    local ok, reason = moveBetween(srcInv, srcMeta, fromSlot, dstInv, dstMeta, toSlot, amount)
    if not ok then
        Logs.Write('move', {player = {src = src}, ok = false, reason = reason})
        return false, reason
    end

    cache.weight = inventoryWeight(mainInv)
    saveCitizen(citizenid)

    if container then
        container.weight = inventoryWeight(container.items)
        container.items = container.items
        TriggerClientEvent('aura-inventory:client:openContainer', src, {
            id = container.id,
            label = container.label,
            items = container.items,
            maxWeight = container.maxWeight,
            maxSlots = container.maxSlots
        })
    end

    Logs.Write('move', {player = {src = src}, ok = true, src = fromInv, dst = toInv})
    return true, cache
end

function Inventory.HandleSplit(src, payload)
    if not checkRateLimit(src, 'splitStack') then
        return false, 'rate_limited'
    end
    local fromSlot = tonumber(payload.fromSlot)
    local toSlot = tonumber(payload.toSlot)
    local amount = tonumber(payload.amount)
    if not fromSlot or not toSlot or not amount then return false, 'invalid_params' end

    local Player = Bridge.GetPlayer(src)
    if not Player then return false, 'player_not_found' end
    local citizenid = Player.PlayerData.citizenid
    local cache = Inventory.cache[citizenid]
    if not cache then
        Inventory.LoadPlayer(src)
        cache = Inventory.cache[citizenid]
    end

    local inv = cache.items
    local item = inv[fromSlot]
    if not item then return false, 'no_item' end
    if amount <= 0 or amount >= item.amount then return false, 'invalid_amount' end

    if inv[toSlot] then
        return false, 'slot_occupied'
    end

    local ok, reason = ensureCapacity(inv, {maxSlots = Config.Settings.maxSlots, maxWeight = Config.Settings.maxWeight}, item.name, amount)
    if not ok then return false, reason end

    inv[toSlot] = {
        name = item.name,
        amount = amount,
        slot = toSlot,
        metadata = Utils.DeepCopy(item.metadata),
        category = item.category,
        label = item.label,
        description = item.description,
        weight = item.weight
    }
    item.amount = item.amount - amount

    cache.weight = inventoryWeight(inv)
    saveCitizen(citizenid)
    Logs.Write('split', {player = {src = src}, ok = true, item = item.name, qty = amount})

    return true, cache
end

function Inventory.HandleUse(src, slot)
    if not checkRateLimit(src, 'useItem') then
        return false, 'rate_limited'
    end
    slot = tonumber(slot)
    if not slot then return false, 'invalid_slot' end

    local Player = Bridge.GetPlayer(src)
    if not Player then return false, 'player_not_found' end
    local citizenid = Player.PlayerData.citizenid
    local cache = Inventory.cache[citizenid]
    if not cache then
        Inventory.LoadPlayer(src)
        cache = Inventory.cache[citizenid]
    end

    local item = cache.items[slot]
    if not item then return false, 'no_item' end

    local itemCfg = Config.Items[item.name]
    if not itemCfg then return false, 'unknown_item' end

    local Weapons = require 'server/weapons'

    if itemCfg.category == 'weapon' then
        return Weapons.EquipWeapon(src, slot, item)
    elseif itemCfg.category == 'ammo' then
        return Weapons.LoadAmmo(src, slot, item)
    elseif itemCfg.category == 'attachment' then
        return Weapons.HandleAttachmentUse(src, slot, item)
    else
        local useEvent = itemCfg.useEvent
        if useEvent then
            TriggerClientEvent(useEvent, src, item.metadata)
        end
        removeItem(cache.items, slot, 1)
        cache.weight = inventoryWeight(cache.items)
        saveCitizen(citizenid)
        Logs.Write('use', {player = {src = src}, ok = true, item = item.name, qty = 1})
        return true, cache
    end
end

function Inventory.HandleDrop(src, payload)
    if not checkRateLimit(src, 'dropItem') then
        return false, 'rate_limited'
    end
    local slot = tonumber(payload.slot)
    local amount = tonumber(payload.amount)
    local coords = payload.coords
    if not slot or not amount or not coords then return false, 'invalid_params' end

    local Player = Bridge.GetPlayer(src)
    if not Player then return false, 'player_not_found' end
    local citizenid = Player.PlayerData.citizenid
    local cache = Inventory.cache[citizenid]
    if not cache then
        Inventory.LoadPlayer(src)
        cache = Inventory.cache[citizenid]
    end

    local item = cache.items[slot]
    if not item or item.amount < amount then return false, 'insufficient_amount' end

    local playerCoords = GetEntityCoords(GetPlayerPed(src))
    local dropVec = vector3(coords.x, coords.y, coords.z)
    local dist = #(dropVec - playerCoords)
    if dist > Config.Settings.groundDrop.dropDistance then
        return false, 'too_far'
    end

    local ok = removeItem(cache.items, slot, amount)
    if not ok then return false, 'remove_failed' end

    local dropId = Utils.GenerateUUID()
    local dropData = {
        id = dropId,
        owner = citizenid,
        coords = {coords.x, coords.y, coords.z},
        item = {
            name = item.name,
            amount = amount,
            metadata = Utils.DeepCopy(item.metadata)
        },
        created = os.time()
    }

    MySQL.insert.await('INSERT INTO aura_ground_drops (id, data, coords, owner) VALUES (?, ?, ?, ?)', {
        dropId,
        Utils.Serialize(dropData.item),
        json.encode(dropData.coords),
        citizenid
    })

    cache.weight = inventoryWeight(cache.items)
    saveCitizen(citizenid)

    Logs.Write('drop', {player = {src = src}, ok = true, item = item.name, qty = amount})

    TriggerClientEvent('aura-inventory:client:dropCreated', -1, dropData)

    return true, dropData
end

function Inventory.HandlePickup(src, dropId)
    if not checkRateLimit(src, 'pickupDrop') then
        return false, 'rate_limited'
    end
    local drop = MySQL.single.await('SELECT * FROM aura_ground_drops WHERE id = ?', {dropId})
    if not drop then return false, 'drop_missing' end

    local Player = Bridge.GetPlayer(src)
    if not Player then return false, 'player_not_found' end
    local citizenid = Player.PlayerData.citizenid
    local cache = Inventory.cache[citizenid]
    if not cache then
        Inventory.LoadPlayer(src)
        cache = Inventory.cache[citizenid]
    end

    local item = Utils.Deserialize(drop.data)
    if not item then return false, 'corrupt_drop' end

    local ok, reason = addItem(cache.items, item.name, item.amount, item.metadata, nil, {maxSlots = Config.Settings.maxSlots, maxWeight = Config.Settings.maxWeight})
    if not ok then return false, reason end

    cache.weight = inventoryWeight(cache.items)
    saveCitizen(citizenid)

    MySQL.prepare.await('DELETE FROM aura_ground_drops WHERE id = ?', {dropId})

    TriggerClientEvent('aura-inventory:client:dropRemoved', -1, dropId)

    Logs.Write('pickup', {player = {src = src}, ok = true, item = item.name, qty = item.amount})
    return true, cache
end

function Inventory.GetState(src)
    local items, data = Inventory.LoadPlayer(src)
    if not items then return nil end
    return {
        items = items,
        weight = inventoryWeight(items),
        weightLimit = Config.Settings.maxWeight,
        slots = Config.Settings.maxSlots
    }
end

return Inventory
