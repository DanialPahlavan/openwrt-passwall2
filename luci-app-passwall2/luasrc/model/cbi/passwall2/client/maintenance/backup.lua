local api = require "luci.passwall2.api"
local appname = "passwall2"

m = Map(appname)

-- Backup Section
s = m:section(TypedSection, "global", translate("Backup & Restore"))
s.anonymous = true
s.addremove = false

-- Backup Button
o = s:option(Button, "_backup_btn", translate("Backup Config"))
o.inputstyle = "save"
o.description = translate("Click to download the current configuration file.")
function o.write(self, section)
	luci.http.redirect(api.url("backup_config"))
end

-- Restore Upload
o = s:option(FileUpload, "_restore_file", translate("Restore Config"))
o.description = translate("Upload a previously backed up configuration file to restore settings.")
function o.write(self, section, value)
	if value then
		if nixio.fs.access(value) then
			-- Back up current just in case? No, restore is destructive.
			luci.sys.call("cp -f " .. value .. " /etc/config/passwall2")
			luci.sys.call("rm -f " .. value)
			luci.http.redirect(api.url("maintenance", "backup"))
		end
	end
end

return m
