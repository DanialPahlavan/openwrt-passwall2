local appname = "passwall2"
local m, s, o

m = Map(appname)

s = m:section(TypedSection, "global")
s.anonymous = true
s.addremove = false

s:append(Template(appname .. "/maintenance/diagnostics"))

return m
