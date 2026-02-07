local api = require "luci.passwall2.api"
local appname = "passwall2"
local fs = api.fs
local sys = api.sys

m = Map(appname)

-- [[ Backup & Restore ]]--
s = m:section(TypedSection, "global", translate("Backup & Restore"))
s.anonymous = true
s.addremove = false

-- Backup Button
o = s:option(Button, "create_backup", translate("Backup Config"))
o.inputstyle = "save"
o.description = translate("Click to download the current configuration file (passwall2, passwall2_server, domains_excluded).")
o.write = function()
	luci.http.redirect(api.url("maintenance", "create_backup"))
end

-- Advanced Backup Button
o = s:option(Button, "create_advanced_backup", translate("Advanced Backup"))
o.inputstyle = "save"
o.description = translate("Create a comprehensive backup including logs, cache, and system state.")
o.write = function()
	luci.http.redirect(api.url("maintenance", "create_advanced_backup"))
end

-- Restore Upload
o = s:option(FileUpload, "restore_backup", translate("Restore Config"))
o.description = translate("Upload a previously backed up configuration file (.tar.gz) to restore settings.")
o.write = function(self, section, value)
	if value and fs.access(value) then
		-- Verify it's a tar.gz (magic bytes or extension check? simpler to just try tar)
		-- The file is at 'value' path in /tmp usually
		local temp_dir = "/tmp/passwall2_restore"
		sys.call("rm -rf " .. temp_dir)
		sys.call("mkdir -p " .. temp_dir)
		
		-- Attempt to extract
		if sys.call("tar -xzf " .. value .. " -C " .. temp_dir) == 0 then
			local backup_files = {
				"/etc/config/passwall2",
				"/etc/config/passwall2_server",
				"/usr/share/passwall2/domains_excluded"
			}
			
			for _, f in ipairs(backup_files) do
				-- If file exists in backup, copy it to system
				-- Note: backup preserves absolute paths? or relative?
				-- Usually standard tar backup is absolute (leading /) or relative. 
				-- Let's check create_backup. It uses "tar -czf ... /etc/config/passwall2 ..." 
				-- Tar normally removes leading '/' from member names. 
				-- So it will be in temp_dir/etc/config/passwall2
				
				local rel_f = f:sub(2) -- remove leading /
				local extracted_file = temp_dir .. "/" .. rel_f
				
				if fs.access(extracted_file) then
					sys.call("cp -f " .. extracted_file .. " " .. f)
				end
			end
			
			sys.call("rm -rf " .. temp_dir)
			sys.call("rm -f " .. value) 
			
			-- Restart services
			sys.call("/etc/init.d/passwall2 restart >/dev/null 2>&1 &")
			
			-- Redirect to show success (maybe reload page)
			luci.http.redirect(api.url("maintenance", "backup"))
			return
		else
			sys.call("rm -rf " .. temp_dir)
			sys.call("rm -f " .. value)
			-- Extraction failed
			return nil 
		end
	end
end

-- System Maintenance
s = m:section(TypedSection, "global", translate("System Maintenance"))
s.anonymous = true
s.addremove = false

-- Clear DNS Cache
o = s:option(Button, "clear_dns_cache", translate("Clear DNS Cache"))
o.inputstyle = "apply"
o.description = translate("Clear the DNS cache to resolve domain name issues.")
o.write = function()
	sys.call("/etc/init.d/dnsmasq restart >/dev/null 2>&1 &")
	luci.http.redirect(api.url("maintenance", "backup"))
end

-- Restart Service
o = s:option(Button, "restart_service", translate("Restart Service"))
o.inputstyle = "reset"
o.description = translate("Restart the PassWall2 service to apply changes.")
o.write = function()
	sys.call("/etc/init.d/passwall2 restart >/dev/null 2>&1 &")
	luci.http.redirect(api.url("maintenance", "backup"))
end

-- Clear Logs
o = s:option(Button, "clear_logs", translate("Clear Logs"))
o.inputstyle = "reset"
o.description = translate("Clear all PassWall2 logs to free up space.")
o.write = function()
	sys.call("echo '' > /tmp/log/passwall2.log")
	sys.call("echo '' > /tmp/log/passwall2_access.log")
	luci.http.redirect(api.url("maintenance", "backup"))
end

-- Flush Rules
o = s:option(Button, "flush_rules", translate("Flush Rules"))
o.inputstyle = "reset"
o.description = translate("Flush all firewall and routing rules.")
o.write = function()
	api.sh_uci_set(appname, "@global[0]", "flush_set", "1", true)
	sys.call("/etc/init.d/passwall2 restart >/dev/null 2>&1 &")
	luci.http.redirect(api.url("maintenance", "backup"))
end

return m
