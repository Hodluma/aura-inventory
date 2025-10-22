local Utils = require 'shared/utils'
local Bridge = require 'shared/bridge_qb'
local Logs = require 'server/logs'
local json = require 'json'

local Containers = {}
Containers.active = {}

local function containerKey(id)
    return ('container:%s'):format(id)
end

local function createContainer(id, cfg)
    local data = {
        id = id,
        label = cfg.label,
        maxWeight = cfg.maxWeight or Config.Settings.maxWeight,
        maxSlots = cfg.maxSlots or Config.Settings.maxSlots,
        access = cfg.access or {},
        coords = cfg.coords,
        items = {}
    }
    Containers.active[id] = data
    return data
end

function Containers.Load(id)
    local cfg = Config.Stashes[id]
    if not cfg then return nil, 'unknown_container' end
    local existing = Containers.active[id]
    if existing then return existing end
    return createContainer(id, cfg)
end

function Containers.Get(id)
    return Containers.active[id]
end

local function hasJobAccess(playerData, jobReqs)
    if not jobReqs or #jobReqs == 0 then return true end
    local job = playerData.job
    if not job then return false end
    for _, req in pairs(jobReqs) do
        if job.name == req.name and job.grade.level >= (req.grade or 0) then
            return true
        end
    end
    return false
end

function Containers.ValidateAccess(src, container)
    local Player = Bridge.GetPlayer(src)
    if not Player then return false end
    local playerData = Player.PlayerData
    local access = container.access or {}
    if not hasJobAccess(playerData, access.jobs) then return false end
    return true
end

function Containers.Open(src, id)
    local container, reason = Containers.Load(id)
    if not container then return false, reason end
    if not Containers.ValidateAccess(src, container) then
        return false, 'no_access'
    end
    return true, {
        id = id,
        label = container.label,
        items = container.items,
        maxWeight = container.maxWeight,
        maxSlots = container.maxSlots
    }
end

function Containers.Save(id)
    local container = Containers.active[id]
    if not container then return end
    -- Extend to persist containers to DB if needed
end

return Containers
