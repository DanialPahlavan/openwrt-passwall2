local api = require "luci.passwall2.api"
local appname = "passwall2"

m = Map(appname)

-- [[ Cache & Cleanup ]]--
s = m:section(TypedSection, "global", translate("Cache & Cleanup"))
s.anonymous = true
s.addremove = false

-- Clear DNS Cache
o = s:option(Button, "clear_dns_cache", translate("Clear DNS Cache"))
o.inputstyle = "apply"
o.description = translate("Restart DNS service to clear cache.")
o.write = function()
	luci.sys.call("/etc/init.d/dnsmasq restart >/dev/null 2>&1")
	luci.sys.call("/etc/init.d/passwall2 restart_dns >/dev/null 2>&1")
	luci.http.redirect(api.url("maintenance", "cache"))
end

-- Clear IPSet
o = s:option(Button, "clear_ipset", translate("Clear IPSet"))
o.inputstyle = "apply"
o.description = translate("Flush all IPSet/NFTSet rules (Use with caution).")
o.write = function()
	luci.sys.call("ipset flush >/dev/null 2>&1")
	luci.sys.call("nft flush ruleset >/dev/null 2>&1")
	luci.http.redirect(api.url("maintenance", "cache"))
end

-- Restart Service
o = s:option(Button, "restart_service", translate("Restart PassWall"))
o.inputstyle = "reset"
o.description = translate("Restart the PassWall service.")
o.write = function()
	luci.sys.call("/etc/init.d/passwall2 restart >/dev/null 2>&1")
	luci.http.redirect(api.url("maintenance", "cache"))
end

return m
