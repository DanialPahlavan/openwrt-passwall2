module("luci.model.cbi.passwall2.client.tools", package.seeall)

local api = require "luci.passwall2.api"
local appname = api.appname
local fs = api.fs

function index()
	entry({"admin", "services", appname, "tools"}, alias("admin", "services", appname, "tools", "acl"), _("Tools"), 90).dependent = true
	entry({"admin", "services", appname, "tools", "acl"}, cbi(appname .. "/client/acl"), _("Access control"), 1).leaf = true
	entry({"admin", "services", appname, "tools", "geoview"}, form(appname .. "/client/geoview"), _("Geo View"), 2).leaf = true
	if nixio.fs.access("/usr/sbin/haproxy") then
		entry({"admin", "services", appname, "tools", "haproxy"}, cbi(appname .. "/client/haproxy"), _("Load Balancing"), 3).leaf = true
	end
end