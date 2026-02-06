local api = require "luci.passwall2.api"
local appname = api.appname

m = Map(appname)
api.set_apply_on_parse(m)

-- [[ Delay Settings ]]--
s = m:section(TypedSection, "global_delay", translate("Scheduled Tasks"))
s.anonymous = true
s.addremove = false

---- Open and close Daemon
o = s:option(Flag, "start_daemon", translate("Open and close Daemon"))
o.default = 1
o.rmempty = false

---- Delay Start
o = s:option(Value, "start_delay", translate("Delay Start"), translate("Units:seconds"))
o.default = "1"
o.rmempty = true

for index, value in ipairs({"stop", "start", "restart"}) do
	o = s:option(ListValue, value .. "_week_mode", translate(value .. " automatically mode"))
	o:value("", translate("Disable"))
	o:value(8, translate("Loop Mode"))
	o:value(7, translate("Every day"))
	o:value(1, translate("Every Monday"))
	o:value(2, translate("Every Tuesday"))
	o:value(3, translate("Every Wednesday"))
	o:value(4, translate("Every Thursday"))
	o:value(5, translate("Every Friday"))
	o:value(6, translate("Every Saturday"))
	o:value(0, translate("Every Sunday"))

	o = s:option(ListValue, value .. "_time_mode", translate(value .. " Time(Every day)"))
	for t = 0, 23 do o:value(t, t .. ":00") end
	o.default = 0
	o:depends(value .. "_week_mode", "0")
	o:depends(value .. "_week_mode", "1")
	o:depends(value .. "_week_mode", "2")
	o:depends(value .. "_week_mode", "3")
	o:depends(value .. "_week_mode", "4")
	o:depends(value .. "_week_mode", "5")
	o:depends(value .. "_week_mode", "6")
	o:depends(value .. "_week_mode", "7")

	o = s:option(ListValue, value .. "_interval_mode", translate(value .. " Interval(Hour)"))
	for t = 1, 24 do o:value(t, t .. " " .. translate("Hour")) end
	o.default = 2
	o:depends(value .. "_week_mode", "8")
end

return m
