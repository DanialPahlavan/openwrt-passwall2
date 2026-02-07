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


-- System Maintenance
s = m:section(TypedSection, "global", translate("System Maintenance"))
s.anonymous = true
s.addremove = false

-- Clear DNS Cache
o = s:option(Button, "clear_dns_cache", translate("Clear DNS Cache"))
o.inputstyle = "apply"
o.description = translate("Clear the DNS cache to resolve domain name issues.")
o.write = function()
	sys.call("/etc/init.d/dnsmasq restart >/dev/null 2>&1 &")
	luci.http.redirect(api.url("maintenance", "backup"))
end

-- Restart Service
o = s:option(Button, "restart_service", translate("Restart Service"))
o.inputstyle = "reset"
o.description = translate("Restart the PassWall2 service to apply changes.")
o.write = function()
	sys.call("/etc/init.d/passwall2 restart >/dev/null 2>&1 &")
	luci.http.redirect(api.url("maintenance", "backup"))
end

-- Clear Logs
o = s:option(Button, "clear_logs", translate("Clear Logs"))
o.inputstyle = "reset"
o.description = translate("Clear all PassWall2 logs to free up space.")
o.write = function()
	sys.call("echo '' > /tmp/log/passwall2.log")
	sys.call("echo '' > /tmp/log/passwall2_access.log")
	luci.http.redirect(api.url("maintenance", "backup"))
end

-- Flush Rules
o = s:option(Button, "flush_rules", translate("Flush Rules"))
o.inputstyle = "reset"
o.description = translate("Flush all firewall and routing rules.")
o.write = function()
	api.sh_uci_set(appname, "@global[0]", "flush_set", "1", true)
	sys.call("/etc/init.d/passwall2 restart >/dev/null 2>&1 &")
	luci.http.redirect(api.url("maintenance", "backup"))
end

return m
