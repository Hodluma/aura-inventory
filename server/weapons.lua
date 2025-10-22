local Utils = require 'shared/utils'
local Bridge = require 'shared/bridge_qb'
local Logs = require 'server/logs'

local Weapons = {}
Weapons.hotbar = {}
Weapons.cooldowns = {}

local function getDurabilityConfig(weaponName)
    return Config.WeaponDurability.weaponOverrides[weaponName] or Config.WeaponDurability.default
end

function Weapons.EquipWeapon(src, slot, item)
    local Player = Bridge.GetPlayer(src)
    if not Player then return false, 'player_not_found' end
    local weaponName = item.metadata.weaponName
    if not weaponName then return false, 'invalid_weapon' end

    local durability = item.metadata.durability or getDurabilityConfig(weaponName).max
    if durability <= 0 then
        return false, 'weapon_broken'
    end

    TriggerClientEvent('aura-inventory:client:equipWeapon', src, weaponName, slot, item.metadata)
    Weapons.hotbar[src] = Weapons.hotbar[src] or { slots = {}, active = slot }
    Weapons.hotbar[src].active = slot
    Weapons.hotbar[src].activeWeapon = weaponName
    Logs.Write('equip', {player = {src = src}, ok = true, item = item.name})
    return true
end

local function findWeaponSlot(inv, weaponName, caliber)
    for slot, item in pairs(inv) do
        if item and item.metadata then
            if weaponName and item.metadata.weaponName == weaponName then
                return slot, item
            end
            if caliber and item.metadata.caliber == caliber then
                return slot, item
            end
        end
    end
    return nil
end

local function findWeaponByCaliber(inv, caliber)
    for slot, item in pairs(inv) do
        if item and item.metadata and item.metadata.caliber == caliber then
            return slot, item
        end
    end
    return nil
end

function Weapons.LoadAmmo(src, slot, item)
    local Player = Bridge.GetPlayer(src)
    if not Player then return false, 'player_not_found' end
    local Inventory = require 'server/inventory'
    local items, cache = Inventory.LoadPlayer(src)
    slot = tonumber(slot)
    if not slot then return false, 'invalid_slot' end
    local ammoItem = items[slot]
    if not ammoItem or ammoItem.name ~= item.name then return false, 'no_item' end

    local weaponRef = item.metadata.weapon
    local weaponSlot, weaponItem
    if weaponRef then
        weaponSlot, weaponItem = findWeaponSlot(items, weaponRef)
    else
        weaponSlot, weaponItem = findWeaponByCaliber(items, item.metadata.caliber)
    end
    if not weaponSlot then return false, 'weapon_missing' end

    local ammoAmount = math.min(ammoItem.amount, item.amount)
    ammoItem.amount = ammoItem.amount - ammoAmount
    if ammoItem.amount <= 0 then
        items[slot] = nil
    end
    Inventory.SavePlayer(src)

    TriggerClientEvent('aura-inventory:client:loadAmmo', src, weaponItem.metadata.weaponName, ammoAmount)
    Logs.Write('ammo_load', {player = {src = src}, ok = true, item = ammoItem and ammoItem.name or item.name, qty = ammoAmount})
    return true
end

function Weapons.ReduceDurability(src, weaponName, amount)
    local Inventory = require 'server/inventory'
    local items, cache = Inventory.LoadPlayer(src)
    local slot, weapon = findWeaponSlot(items, weaponName)
    if not slot then return end
    weapon.metadata = weapon.metadata or {}
    weapon.metadata.durability = math.max(0, (weapon.metadata.durability or getDurabilityConfig(weaponName).max) - amount)
    Inventory.SavePlayer(src)
    if weapon.metadata.durability <= 0 then
        Bridge.Notify(src, 'Weapon is broken!', 'error')
    end
end

function Weapons.HandleAttachmentUse(src, slot, item)
    local attachmentType = item.metadata.attachmentType
    local weaponClass = item.metadata.weaponClass
    if not attachmentType or not weaponClass then
        return false, 'invalid_attachment'
    end
    local Inventory = require 'server/inventory'
    local items = select(1, Inventory.LoadPlayer(src))
    local options = {}
    for invSlot, invItem in pairs(items) do
        if invItem and invItem.metadata and invItem.metadata.weaponClass == weaponClass then
            options[#options + 1] = {
                slot = invSlot,
                weaponName = invItem.metadata.weaponName,
                attachments = invItem.metadata.attachments or {}
            }
        end
    end
    TriggerClientEvent('aura-inventory:nui:openAttachments', src, {
        slot = slot,
        attachmentType = attachmentType,
        weaponClass = weaponClass,
        options = options
    })
    return true
end

function Weapons.Attach(src, weaponSlot, attachmentSlot, attachmentKey)
    local Inventory = require 'server/inventory'
    local items, cache = Inventory.LoadPlayer(src)
    weaponSlot = tonumber(weaponSlot)
    attachmentSlot = tonumber(attachmentSlot)
    if not weaponSlot or not attachmentSlot then return false, 'invalid_slot' end
    local weapon = items[weaponSlot]
    local attachment = items[attachmentSlot]
    if not weapon or not attachment then return false, 'missing_item' end
    local weaponClass = attachment.metadata.weaponClass
    local weaponName = weapon.metadata.weaponName
    local compatList = Config.AttachmentCompat[weaponClass] and Config.AttachmentCompat[weaponClass][attachment.metadata.attachmentType]
    if not compatList then return false, 'incompatible' end
    local match = false
    for _, allowed in ipairs(compatList) do
        if allowed == weaponName then
            match = true
            break
        end
    end
    if not match then return false, 'incompatible' end

    weapon.metadata.attachments = weapon.metadata.attachments or {}
    weapon.metadata.attachments[attachment.metadata.attachmentType] = true
    items[weaponSlot] = weapon
    items[attachmentSlot] = nil
    Inventory.SavePlayer(src)
    Logs.Write('attach', {player = {src = src}, ok = true, item = attachment.name, meta = attachment.metadata})
    TriggerClientEvent('aura-inventory:client:attachmentApplied', src, weaponSlot, attachment.metadata.attachmentType)
    return true
end

function Weapons.Detach(src, weaponSlot, attachmentType)
    local Inventory = require 'server/inventory'
    local items, cache = Inventory.LoadPlayer(src)
    weaponSlot = tonumber(weaponSlot)
    if not weaponSlot then return false, 'invalid_slot' end
    local weapon = items[weaponSlot]
    if not weapon or not weapon.metadata.attachments or not weapon.metadata.attachments[attachmentType] then
        return false, 'missing_attachment'
    end
    weapon.metadata.attachments[attachmentType] = nil
    Inventory.SavePlayer(src)
    Logs.Write('detach', {player = {src = src}, ok = true, item = weapon.name, meta = attachmentType})
    TriggerClientEvent('aura-inventory:client:attachmentRemoved', src, weaponSlot, attachmentType)
    return true
end

return Weapons
