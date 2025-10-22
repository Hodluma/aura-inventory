local Utils = {}

local json = require 'json'

function Utils.DeepCopy(tbl)
    if type(tbl) ~= 'table' then return tbl end
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == 'table' then
            copy[k] = Utils.DeepCopy(v)
        else
            copy[k] = v
        end
    end
    return copy
end

function Utils.MergeMetadata(base, override)
    local result = Utils.DeepCopy(base or {})
    for k, v in pairs(override or {}) do
        if type(v) == 'table' and type(result[k]) == 'table' then
            result[k] = Utils.MergeMetadata(result[k], v)
        else
            result[k] = v
        end
    end
    return result
end

function Utils.GenerateUUID()
    local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
    return string.gsub(template, '[xy]', function(c)
        local v = math.random(0, 15)
        if c == 'y' then
            v = (v % 4) + 8
        end
        return string.format('%x', v)
    end)
end

function Utils.Serialize(data)
    return json.encode(data)
end

function Utils.Deserialize(data)
    if not data or data == '' then return nil end
    local ok, decoded = pcall(json.decode, data)
    if not ok then
        return nil
    end
    return decoded
end

function Utils.GetItem(itemName)
    return Config.Items[itemName]
end

function Utils.GetWeight(itemName, amount)
    local item = Utils.GetItem(itemName)
    if not item then return 0 end
    local weight = item.weight or 0
    return weight * (amount or 1)
end

function Utils.Round(num, decimals)
    local mult = 10 ^ (decimals or 0)
    return math.floor(num * mult + 0.5) / mult
end

return Utils
