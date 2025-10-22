local Logs = {}
local json = require 'json'

local function sendWebhook(payload)
    if not Config.Settings.webhook.enabled or Config.Settings.webhook.url == '' then return end
    PerformHttpRequest(Config.Settings.webhook.url, function() end, 'POST', json.encode(payload), {['Content-Type'] = 'application/json'})
end

function Logs.Write(action, data)
    local entry = {
        ts = os.time(),
        action = action,
        player = data.player or {},
        item = data.item,
        qty = data.qty,
        src = data.src,
        dst = data.dst,
        ok = data.ok,
        reason = data.reason,
        meta = data.meta
    }
    print(('[AuraInventory] %s'):format(json.encode(entry)))
    if data.alert then
        sendWebhook(entry)
    end
end

return Logs
