local api = require "luci.passwall2.api"
local appname = api.appname

m = Map(appname)
api.set_apply_on_parse(m)

-- [[ Panel Settings ]]--
s = m:section(TypedSection, "global", translate("Panel Settings"))
s.anonymous = true
s.addremove = false

o = s:option(ListValue, "language", translate("Language"))
o.default = "auto"
o:value("auto", translate("Auto"))
o:value("zh_cn", "简体中文")
o:value("zh_tw", "繁體中文")
o:value("en", "English")
o:value("fa", "فارسی")
o:value("ru", "Pyccĸий")
o:value("ja", "日本語")

o = s:option(Flag, "show_node_info", translate("Show Node Info"), translate("Show detailed node info in node list."))
o.default = 0
o.rmempty = false

return m