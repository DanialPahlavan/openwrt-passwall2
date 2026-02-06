local api = require "luci.passwall2.api"
local appname = api.appname

m = Map(appname)
api.set_apply_on_parse(m)


s = m:section(TypedSection, "shunt_rules", "Sing-Box/Xray " .. translate("Shunt Rule"), "<a style='color: red'>" .. translate("Please note attention to the priority, the higher the order, the higher the priority.") .. "</a>")
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

return m
