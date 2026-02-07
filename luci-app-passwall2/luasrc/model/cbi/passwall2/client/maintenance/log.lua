local api = require "luci.passwall2.api"
local appname = api.appname

f = SimpleForm(appname)
f.reset = false
f.submit = false
f:append(Template(appname .. "/maintenance/log/log"))


loglevel.default = "warning"
loglevel:value("debug")
loglevel:value("info")
loglevel:value("warning")
loglevel:value("error")


return f