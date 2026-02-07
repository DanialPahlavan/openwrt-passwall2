local api = require "luci.passwall2.api"
local appname = api.appname

m = Map(appname)
api.set_apply_on_parse(m)

s = m:section(TypedSection, "shunt_rules", translate("Shunt Rules Assignment"), translate("Assign nodes to shunt rules for traffic routing."))
s.template = "cbi/tblsection"
s.anonymous = false
s.addremove = true
s.sortable = true
s.extedit = api.url("shunt_rules", "%s")
function s.create(e, t)
	TypedSection.create(e, t)
	luci.http.redirect(e.extedit:format(t))
end
function s.remove(e, t)
	m.uci:foreach(appname, "nodes", function(s)
		if s["protocol"] and s["protocol"] == "_shunt" then
			m:del(s[".name"], t)
		end
	end)
	TypedSection.remove(e, t)
end

o = s:option(DummyValue, "remarks", translate("Remarks"))

-- Node Assignment
o = s:option(ListValue, "node", translate("Assigned Node"))
o:value("", translate("None"))
m.uci:foreach(appname, "nodes", function(s)
	if s["type"] and s["type"] ~= "_shunt" then
		local remarks = s["remarks"] or s[".name"]
		o:value(s[".name"], remarks)
	end
end)

-- Chain Proxy
o = s:option(Flag, "chain_proxy", translate("Chain Proxy"))
o.rmempty = false
o.default = 0

-- Pre-proxy Node
o = s:option(ListValue, "preproxy_node", translate("Pre-proxy Node"))
o:value("", translate("None"))
o:depends("chain_proxy", "1")
m.uci:foreach(appname, "nodes", function(s)
	if s["type"] and s["type"] ~= "_shunt" then
		local remarks = s["remarks"] or s[".name"]
		o:value(s[".name"], remarks)
	end
end)

-- To Node
o = s:option(ListValue, "to_node", translate("To Node"))
o:value("", translate("None"))
o:depends("chain_proxy", "1")
m.uci:foreach(appname, "nodes", function(s)
	if s["type"] and s["type"] ~= "_shunt" then
		local remarks = s["remarks"] or s[".name"]
		o:value(s[".name"], remarks)
	end
end)

return m