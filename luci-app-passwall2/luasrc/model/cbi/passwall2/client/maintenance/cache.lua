local api = require "luci.passwall2.api"
local appname = "passwall2"

m = Map(appname)

s = m:section(TypedSection, "global", translate("Cache & Cleanup"))
s.anonymous = true
s.addremove = false

-- Clear DNS Cache
o = s:option(Button, "_clear_dns", translate("Clear DNS Cache"))
o.inputstyle = "apply"
o.description = translate("Restart DNS service to clear cache.")
function o.write(self, section)
	luci.sys.call("/etc/init.d/dnsmasq restart")
	-- Provide feedback via alert? Hard in CBI write.
	-- Page refresh implies action done.
end
-- Clear IPSet
o = s:option(Button, "_clear_ipset", translate("Clear IPSet"))
o.inputstyle = "apply"
o.description = translate("Flush all IPSet/NFTSet rules (Use with caution).")
function o.write(self, section)
	luci.sys.call("ipset flush") 
	-- Or passwall specific flush? 
	-- api.flush_set() ? 
end

-- Restart Service
o = s:option(Button, "_restart_service", translate("Restart PassWall"))
o.inputstyle = "reset"
o.description = translate("Restart the PassWall service.")
function o.write(self, section)
	luci.sys.call("/etc/init.d/passwall2 restart")
end

return m
