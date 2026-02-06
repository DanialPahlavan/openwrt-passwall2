local api = require "luci.passwall2.api"
local appname = api.appname

m = Map(appname)
api.set_apply_on_parse(m)

-- [[ App Settings ]]--
s = m:section(TypedSection, "global_app", translate("App Update"),
	"<font color='red'>" ..
	translate("Please confirm that your firmware supports FPU.") ..
	"</font>")
s.anonymous = true
s:append(Template(appname .. "/app_update/app_version"))

local k, v
local com = require "luci.passwall2.com"
for k, v in pairs(com) do
	o = s:option(Value, k:gsub("%-","_") .. "_file", translatef("%s App Path", v.name))
	o.default = v.default_path or ("/usr/bin/" .. k)
	o.rmempty = false
end

o = s:option(DummyValue, "tips", " ")
o.rawhtml = true
o.cfgvalue = function(t, n)
	return string.format('<font color="red">%s</font>', translate("if you want to run from memory, change the path, /tmp beginning then save the application and update it manually."))
end


-- [[ Rule Update Settings ]]--
s = m:section(TypedSection, "global_rules", translate("Rule Update"))
s.anonymous = true

o = s:option(Value, "geoip_url", translate("GeoIP Update URL"))
o:value("https://github.com/Loyalsoldier/geoip/releases/latest/download/geoip.dat", translate("Loyalsoldier/geoip"))
o:value("https://github.com/MetaCubeX/meta-rules-dat/releases/latest/download/geoip.dat", translate("MetaCubeX/geoip"))
o:value("https://cdn.jsdelivr.net/gh/Loyalsoldier/geoip@release/geoip.dat", translate("Loyalsoldier/geoip (CDN)"))
o:value("https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geoip.dat", translate("MetaCubeX/geoip (CDN)"))
o:value("https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geoip.dat", translate("Chocolate4U/geoip (IR)"))
o:value("https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geoip.dat", translate("runetfreedom/geoip (RU)"))
o.default = o.keylist[1]

o = s:option(Value, "geosite_url", translate("Geosite Update URL"))
o:value("https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat", translate("Loyalsoldier/geosite"))
o:value("https://github.com/MetaCubeX/meta-rules-dat/releases/latest/download/geosite.dat", translate("MetaCubeX/geosite"))
o:value("https://cdn.jsdelivr.net/gh/Loyalsoldier/v2ray-rules-dat@release/geosite.dat", translate("Loyalsoldier/geosite (CDN)"))
o:value("https://cdn.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@release/geosite.dat", translate("MetaCubeX/geosite (CDN)"))
o:value("https://github.com/Chocolate4U/Iran-v2ray-rules/releases/latest/download/geosite.dat", translate("Chocolate4U/geosite (IR)"))
o:value("https://github.com/runetfreedom/russia-v2ray-rules-dat/releases/latest/download/geosite.dat", translate("runetfreedom/geosite (RU)"))
o.default = o.keylist[1]

o = s:option(Value, "v2ray_location_asset", translate("Location of Geo rule files"), translate("This variable specifies a directory where geoip.dat and geosite.dat files are."))
o.default = "/usr/share/v2ray/"
o.placeholder = o.default
o.rmempty = false

---- Auto Update
o = s:option(Flag, "auto_update", translate("Enable auto update rules"))
o.default = 0
o.rmempty = false

---- Week Update
o = s:option(ListValue, "week_update", translate("Update Mode"))
o:value(8, translate("Loop Mode"))
o:value(7, translate("Every day"))
o:value(1, translate("Every Monday"))
o:value(2, translate("Every Tuesday"))
o:value(3, translate("Every Wednesday"))
o:value(4, translate("Every Thursday"))
o:value(5, translate("Every Friday"))
o:value(6, translate("Every Saturday"))
o:value(0, translate("Every Sunday"))
o.default = 7
o:depends("auto_update", true)
o.rmempty = true

---- Time Update
o = s:option(ListValue, "time_update", translate("Update Time(every day)"))
for t = 0, 23 do o:value(t, t .. ":00") end
o.default = 0
o:depends("week_update", "0")
o:depends("week_update", "1")
o:depends("week_update", "2")
o:depends("week_update", "3")
o:depends("week_update", "4")
o:depends("week_update", "5")
o:depends("week_update", "6")
o:depends("week_update", "7")
o.rmempty = true

---- Interval Update
o = s:option(ListValue, "interval_update", translate("Update Interval(hour)"))
for t = 1, 24 do o:value(t, t .. " " .. translate("hour")) end
o.default = 2
o:depends("week_update", "8")
o.rmempty = true

--- The update option is always hidden by JavaScript.
local flags = {
	"geoip_update", "geosite_update"
}
for _, f in ipairs(flags) do
	o = s:option(Flag, f)
	o.rmempty = false
end

s:append(Template(appname .. "/rule/rule_version"))

return m
