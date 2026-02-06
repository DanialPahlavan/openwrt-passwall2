module("luci.model.cbi.passwall2.client.nodes", package.seeall)

local api = require "luci.passwall2.api"
local appname = api.appname
local fs = api.fs

function index()
	entry({"admin", "services", appname, "nodes"}, alias("admin", "services", appname, "nodes", "list"), _("Nodes"), 2).dependent = true
	entry({"admin", "services", appname, "nodes", "list"}, cbi(appname .. "/client/node_list"), _("Node List"), 1).leaf = true
	entry({"admin", "services", appname, "nodes", "subscribe"}, cbi(appname .. "/client/node_subscribe"), _("Node Subscribe"), 2).leaf = true
end