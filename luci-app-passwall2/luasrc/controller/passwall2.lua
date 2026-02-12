-- Modern Lua module pattern for OpenWrt 24.x
local M = {}

-- Import the newmodular controller
local main_controller = require "luci.controller.main"
local api = require "luci.passwall2.api"
local appname = api.appname
local uci = api.uci
local http = require "luci.http"
local util = require "luci.util"
local i18n = require "luci.i18n"
local jsonc = require "luci.jsonc"
local nixio = require "nixio"
local fs = api.fs
local sys = api.sys
local jsonStringify = jsonc.stringify
local jsonParse = jsonc.parse

function M.index()
	-- Use the new modular controller's index function
	return main_controller.index()
end

-- Keep only the functions that are not in the new modular controller
-- These are the server-side and backup functions that are specific to the old controller

function M.server_user_status()
	local e = {}
	e.index = http.formvalue("index")
	e.status = sys.call(string.format(
		"/bin/busybox top -bn1 | grep -v 'grep' | grep '%s/bin/' | grep -i '%s' >/dev/null", appname .. "_server",
		http.formvalue("id"))) == 0
	main_controller.http_write_json(e)
end

function M.server_user_log()
	local id = http.formvalue("id")
	if nixio.fs.access("/tmp/etc/passwall2_server/" .. id .. ".log") then
		local content = sys.exec("cat /tmp/etc/passwall2_server/" .. id .. ".log")
		content = content:gsub("\n", "<br />")
		http.write(content)
	else
		http.write(string.format("<script>alert('%s');window.close();</script>", i18n.translate("Not enabled log")))
	end
end

function M.server_get_log()
	http.write(sys.exec("[ -f '/tmp/log/passwall2_server.log' ] && cat /tmp/log/passwall2_server.log"))
end

function M.server_clear_log()
	sys.call("echo '' > /tmp/log/passwall2_server.log")
end

function M.app_check()
	local json = api.to_check_self()
	main_controller.http_write_json(json)
end

function M.com_check(comname)
	local json = api.to_check("", comname)
	main_controller.http_write_json(json)
end

function M.com_update(comname)
	local json = nil
	local task = http.formvalue("task")
	if task == "extract" then
		json = api.to_extract(comname, http.formvalue("file"), http.formvalue("subfix"))
	elseif task == "move" then
		json = api.to_move(comname, http.formvalue("file"))
	else
		json = api.to_download(comname, http.formvalue("url"), http.formvalue("size"))
	end

	main_controller.http_write_json(json)
end

local backup_files = {
	"/etc/config/passwall2",
	"/etc/config/passwall2_server",
	"/usr/share/passwall2/domains_excluded"
}

function M.create_backup()
	local date = os.date("%y%m%d%H%M")
	local tar_file = "/tmp/passwall2-" .. date .. "-backup.tar.gz"
	fs.remove(tar_file)
	local cmd = "tar -czf " .. tar_file .. " " .. table.concat(backup_files, " ")
	api.sys.call(cmd)
	http.header("Content-Disposition", "attachment; filename=passwall2-" .. date .. "-backup.tar.gz")
	http.header("X-Backup-Filename", "passwall2-" .. date .. "-backup.tar.gz")
	http.prepare_content("application/octet-stream")
	http.write(fs.readfile(tar_file))
	fs.remove(tar_file)
end

function M.restore_backup()
	local result = { status = "error", message = "unknown error" }
	local ok, err = pcall(function()
		local filename = http.formvalue("filename")
		local chunk = http.formvalue("chunk")
		local chunk_index = tonumber(http.formvalue("chunk_index") or "-1")
		local total_chunks = tonumber(http.formvalue("total_chunks") or "-1")
		if not filename then
			result = { status = "error", message = "Missing filename" }
			return
		end
		if not chunk then
			result = { status = "error", message = "Missing chunk data" }
			return
		end
		local file_path = "/tmp/" .. filename
		local decoded = nixio.bin.b64decode(chunk)
		if not decoded then
			result = { status = "error", message = "Base64 decode failed" }
			return
		end
		local fp = io.open(file_path, "a+")
		if not fp then
			result = { status = "error", message = "Failed to open file: " .. file_path }
			return
		end
		fp:write(decoded)
		fp:close()
		if chunk_index + 1 == total_chunks then
			api.sys.call("echo '' > /tmp/log/passwall2.log")
			api.log(0, string.format(" * PassWall2 %s", i18n.translate("Configuration file uploaded successfully…")))
			local temp_dir = '/tmp/passwall2_bak'
			api.sys.call("mkdir -p " .. temp_dir)
			if api.sys.call("tar -xzf " .. file_path .. " -C " .. temp_dir) == 0 then
				for _, backup_file in ipairs(backup_files) do
					local temp_file = temp_dir .. backup_file
					if fs.access(temp_file) then
						api.sys.call("cp -f " .. temp_file .. " " .. backup_file)
					end
				end
				api.log(0, string.format(" * PassWall2 %s", i18n.translate("Configuration restored successfully…")))
				api.log(0, string.format(" * PassWall2 %s", i18n.translate("Service restarting…")))
				sys.call('/etc/init.d/passwall2 restart > /dev/null 2>&1 &')
				sys.call('/etc/init.d/passwall2_server restart > /dev/null 2>&1 &')
				result = { status = "success", message = "Upload completed", path = file_path }
			else
				api.log(0,
					string.format(" * PassWall2 %s",
						i18n.translate("Configuration file decompression failed, please try again!")))
				result = { status = "error", message = "Decompression failed" }
			end
			api.sys.call("rm -rf " .. temp_dir)
			fs.remove(file_path)
		else
			result = { status = "success", message = "Chunk received" }
		end
	end)
	if not ok then
		result = { status = "error", message = tostring(err) }
	end
	main_controller.http_write_json(result)
end

function M.geo_view()
	local action = luci.http.formvalue("action")
	local value = luci.http.formvalue("value")
	if not value or value == "" then
		http.prepare_content("text/plain")
		http.write(i18n.translate("Please enter query content!"))
		return
	end
	local function get_rules(str, type)
		local rules_id = {}
		uci:foreach(appname, "shunt_rules", function(s)
			local list
			if type == "geoip" then list = s.ip_list else list = s.domain_list end
			for line in string.gmatch((list or ""), "[^\r\n]+") do
				if line ~= "" and not line:find("#") then
					local prefix, main = line:match("^(.-):(.*)")
					if not main then main = line end
					if type == "geoip" and (api.datatypes.ipaddr(str) or api.datatypes.ip6addr(str)) then
						if main:find(str, 1, true) then rules_id[#rules_id + 1] = s[".name"] end
					else
						if main == str then rules_id[#rules_id + 1] = s[".name"] end
					end
				end
			end
		end)
		return rules_id
	end
	local geo_dir = (uci:get(appname, "@global_rules[0]", "v2ray_location_asset") or "/usr/share/v2ray/"):match("^(.*)/")
	local geosite_path = geo_dir .. "/geosite.dat"
	local geoip_path = geo_dir .. "/geoip.dat"
	local geo_type, file_path, cmd
	local geo_string = ""
	if action == "lookup" then
		if api.datatypes.ipaddr(value) or api.datatypes.ip6addr(value) then
			geo_type, file_path = "geoip", geoip_path
		else
			geo_type, file_path = "geosite", geosite_path
		end
		cmd = string.format("geoview -type %s -action lookup -input '%s' -value '%s' -lowmem=true", geo_type, file_path,
			value)
		geo_string = sys.exec(cmd):lower()
		if geo_string ~= "" then
			local lines, rules, seen = {}, {}, {}
			for line in geo_string:gmatch("([^\n]+)") do
				lines[#lines + 1] = geo_type .. ":" .. line
				for _, r in ipairs(get_rules(line, geo_type) or {}) do
					if not seen[r] then
						seen[r] = true; rules[#rules + 1] = r
					end
				end
			end
			for _, r in ipairs(get_rules(value, geo_type) or {}) do
				if not seen[r] then
					seen[r] = true; rules[#rules + 1] = r
				end
			end
			geo_string = table.concat(lines, "\n")
			if #rules > 0 then
				geo_string = geo_string .. "\n--------------------\n"
				geo_string = geo_string .. i18n.translate("Rules containing this value:") .. "\n"
				geo_string = geo_string .. table.concat(rules, "\n")
			end
		end
	elseif action == "extract" then
		local prefix, list = value:match("^(geoip:)(.*)$")
		if not prefix then
			prefix, list = value:match("^(geosite:)(.*)$")
		end
		if prefix and list and list ~= "" then
			geo_type = prefix:sub(1, -2)
			file_path = (geo_type == "geoip") and geoip_path or geosite_path
			cmd = string.format("geoview -type %s -action extract -input '%s' -list '%s' -lowmem=true", geo_type,
				file_path, list)
			geo_string = sys.exec(cmd)
		end
	end
	http.prepare_content("text/plain")
	if geo_string and geo_string ~= "" then
		http.write(geo_string)
	else
		http.write(i18n.translate("No results were found!"))
	end
end

function M.backup_config()
	local config_path = "/etc/config/passwall2"
	http.header('Content-Disposition', 'attachment; filename="passwall2_backup.config"')
	http.prepare_content("application/octet-stream")

	-- Stream file content without ltn12
	local fp = io.open(config_path, "r")
	if fp then
		local chunk_size = 4096
		while true do
			local chunk = fp:read(chunk_size)
			if not chunk then break end
			http.write(chunk)
		end
		fp:close()
	end
end

function M.restore_config()
	-- Legacy placeholder or custom upload handler if needed.
	-- Actual restore handled by CBI model upload for simplicity.
	http.redirect(api.url("maintenance", "backup"))
end

function M.clear_dns_cache()
	-- Flush DNS cache logic (e.g. reload dnsmasq or flush ipset)
	-- Passwall usually handles this on restart/reload, but we can try specific commands.
	-- For now, allow simple restart of DNS helper or full reload.
	sys.call("/etc/init.d/dnsmasq restart")
	main_controller.http_write_json({ code = 1, msg = "DNS Cache Cleared" })
end

function M.restart_service()
	sys.call("/etc/init.d/passwall2 restart")
	main_controller.http_write_json({ code = 1, msg = "Service Restarted" })
end

function M.create_advanced_backup()
	local date = os.date("%y%m%d%H%M")
	local tar_file = "/tmp/passwall2-" .. date .. "-advanced-backup.tar.gz"
	fs.remove(tar_file)

	-- Create comprehensive backup including logs, cache, and system state
	local backup_files = {
		"/etc/config/passwall2",
		"/etc/config/passwall2_server",
		"/usr/share/passwall2/domains_excluded",
		"/tmp/log/passwall2.log",
		"/tmp/log/passwall2_access.log",
		"/tmp/log/passwall2_server.log",
		"/tmp/etc/passwall2",
		"/tmp/etc/passwall2_server"
	}

	-- Filter out files that don't exist
	local existing_files = {}
	for _, file in ipairs(backup_files) do
		if fs.access(file) then
			table.insert(existing_files, file)
		end
	end

	if #existing_files > 0 then
		local cmd = "tar -czf " .. tar_file .. " " .. table.concat(existing_files, " ")
		api.sys.call(cmd)
	end

	http.header("Content-Disposition", "attachment; filename=passwall2-" .. date .. "-advanced-backup.tar.gz")
	http.header("X-Backup-Filename", "passwall2-" .. date .. "-advanced-backup.tar.gz")
	http.prepare_content("application/octet-stream")
	http.write(fs.readfile(tar_file))
	fs.remove(tar_file)
end

-- JSON helper functions are provided by main_controller
-- Use main_controller.http_write_json(), main_controller.http_write_json_ok(), main_controller.http_write_json_error()

return M
