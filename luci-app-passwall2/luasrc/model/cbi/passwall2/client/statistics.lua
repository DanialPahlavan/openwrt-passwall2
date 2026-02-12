-- PassWall2 Statistics Page
-- LuCI model for displaying monitoring statistics
-- Optimized for low-resource routers

local api = require "luci.passwall2.api"
local helpers = require "luci.passwall2.helpers"

local appname = api.appname

m = Map(appname, translate("Statistics"), translate("Real-time monitoring statistics"))

-- Status section
s = m:section(TypedSection, "global", translate("System Status"))
s.anonymous = true

-- Service status
o = s:option(DummyValue, "service_status", translate("Service Status"))
o.rawhtml = true
o.cfgvalue = function(self, section)
    if helpers.is_service_running() then
        return string.format("<span style='color:green;font-weight:bold'>%s</span>", translate("Running"))
    else
        return string.format("<span style='color:red;font-weight:bold'>%s</span>", translate("Stopped"))
    end
end

-- Connection count
o = s:option(DummyValue, "connections", translate("Active Connections"))
o.cfgvalue = function(self, section)
    local stats = helpers.get_monitor_stats()
    if stats and stats.connections then
        return tostring(stats.connections)
    end
    return "0"
end

-- Uptime
o = s:option(DummyValue, "uptime", translate("Uptime"))
o.cfgvalue = function(self, section)
    local stats = helpers.get_monitor_stats()
    if stats and stats.uptime then
        return helpers.format_uptime(stats.uptime)
    end
    return translate("Unknown")
end

-- Bandwidth section
s = m:section(TypedSection, "global", translate("Bandwidth Usage"))
s.anonymous = true

-- Download
o = s:option(DummyValue, "rx_bytes", translate("Downloaded"))
o.cfgvalue = function(self, section)
    local stats = helpers.get_monitor_stats()
    if stats and stats.bandwidth and stats.bandwidth.rx_bytes then
        return helpers.format_bytes(stats.bandwidth.rx_bytes)
    end
    return "0 B"
end

-- Upload
o = s:option(DummyValue, "tx_bytes", translate("Uploaded"))
o.cfgvalue = function(self, section)
    local stats = helpers.get_monitor_stats()
    if stats and stats.bandwidth and stats.bandwidth.tx_bytes then
        return helpers.format_bytes(stats.bandwidth.tx_bytes)
    end
    return "0 B"
end

-- Download rate
o = s:option(DummyValue, "rx_rate", translate("Download Speed"))
o.cfgvalue = function(self, section)
    local stats = helpers.get_monitor_stats()
    if stats and stats.bandwidth and stats.bandwidth.rx_rate then
        return helpers.format_bytes(stats.bandwidth.rx_rate) .. "/s"
    end
    return "0 B/s"
end

-- Upload rate
o = s:option(DummyValue, "tx_rate", translate("Upload Speed"))
o.cfgvalue = function(self, section)
    local stats = helpers.get_monitor_stats()
    if stats and stats.bandwidth and stats.bandwidth.tx_rate then
        return helpers.format_bytes(stats.bandwidth.tx_rate) .. "/s"
    end
    return "0 B/s"
end

-- System resources
s = m:section(TypedSection, "global", translate("System Resources"))
s.anonymous = true

-- Memory usage
o = s:option(DummyValue, "memory", translate("Memory Usage"))
o.cfgvalue = function(self, section)
    local resources = helpers.get_system_resources()
    if resources.memory then
        local used = helpers.format_bytes(resources.memory.used)
        local total = helpers.format_bytes(resources.memory.total)
        local percent = resources.memory.usage_percent
        return string.format("%s / %s (%d%%)", used, total, percent)
    end
    return translate("Unknown")
end

-- Load average
o = s:option(DummyValue, "load", translate("Load Average"))
o.cfgvalue = function(self, section)
    local resources = helpers.get_system_resources()
    if resources.load then
        return string.format("%.2f, %.2f, %.2f",
            resources.load.one,
            resources.load.five,
            resources.load.fifteen)
    end
    return translate("Unknown")
end

return m
