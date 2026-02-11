module("luci.passwall2.controller.main", package.seeall)

local api = require "luci.passwall2.api"
local appname = api.appname
local uci = api.uci
local http = require "luci.http"
local util = require "luci.util"
local i18n = require "luci.i18n"

-- Main controller for PassWall2
-- This replaces the monolithic controller with a modular approach

function index()
    -- Check if configuration exists
    if not nixio.fs.access("/etc/config/passwall2") then
        if nixio.fs.access("/usr/share/passwall2/0_default_config") then
            luci.sys.call('cp -f /usr/share/passwall2/0_default_config /etc/config/passwall2')
        else 
            return 
        end
    end

    -- Create main menu entry
    local e = entry({"admin", "services", appname}, alias("admin", "services", appname, "settings"), _("PassWall 2"), 0)
    e.dependent = true
    e.acl_depends = { "luci-app-passwall2" }

    -- Client section
    entry({"admin", "services", appname, "settings"}, cbi(appname .. "/client/global"), _("Basic Settings"), 1).dependent = true
    entry({"admin", "services", appname, "nodes"}, cbi(appname .. "/client/nodes"), _("Nodes"), 2).dependent = true
    entry({"admin", "services", appname, "nodes", "list"}, cbi(appname .. "/client/node_list"), _("Node List"), 1).leaf = true
    entry({"admin", "services", appname, "nodes", "subscribe"}, cbi(appname .. "/client/node_subscribe"), _("Node Subscribe"), 2).leaf = true
    
    entry({"admin", "services", appname, "node_subscribe_config"}, cbi(appname .. "/client/node_subscribe_config")).leaf = true
    entry({"admin", "services", appname, "node_config"}, cbi(appname .. "/client/node_config")).leaf = true
    entry({"admin", "services", appname, "shunt_rules"}, cbi(appname .. "/client/shunt_rules")).leaf = true
    entry({"admin", "services", appname, "socks_config"}, cbi(appname .. "/client/socks_config")).leaf = true
    entry({"admin", "services", appname, "acl_config"}, cbi(appname .. "/client/acl_config")).leaf = true

    -- Rule management
    entry({"admin", "services", appname, "rule"}, cbi(appname .. "/client/rule"), _("Rule Manage"), 3).leaf = true
    entry({"admin", "services", appname, "shunt_rules_assign"}, cbi(appname .. "/client/shunt_rules_assign"), _("Shunt Rules"), 4).leaf = true

    -- Advanced connection
    entry({"admin", "services", appname, "other"}, cbi(appname .. "/client/other", {autoapply = true}), _("Advanced Connection"), 4).leaf = true

    -- Tools
    entry({"admin", "services", appname, "tools"}, cbi(appname .. "/client/tools"), _("Tools"), 5).dependent = true
    entry({"admin", "services", appname, "tools", "acl"}, cbi(appname .. "/client/acl"), _("Access control"), 1).leaf = true
    entry({"admin", "services", appname, "tools", "geoview"}, form(appname .. "/client/geoview"), _("Geo View"), 2).leaf = true
    if nixio.fs.access("/usr/sbin/haproxy") then
        entry({"admin", "services", appname, "tools", "haproxy"}, cbi(appname .. "/client/haproxy"), _("Load Balancing"), 3).leaf = true
    end

    -- Server-side
    entry({"admin", "services", appname, "server"}, cbi(appname .. "/server/index"), _("Server-Side"), 6).leaf = true
    entry({"admin", "services", appname, "server_user"}, cbi(appname .. "/server/user")).leaf = true

    -- Maintenance
    entry({"admin", "services", appname, "maintenance"}, form(appname .. "/client/maintenance"), _("Maintenance"), 7).dependent = true
    entry({"admin", "services", appname, "maintenance", "panel_settings"}, cbi(appname .. "/client/panel_settings"), _("Panel Settings"), 1).leaf = true
    entry({"admin", "services", appname, "maintenance", "log"}, form(appname .. "/client/maintenance/log"), _("Watch Logs"), 2).leaf = true
    entry({"admin", "services", appname, "maintenance", "update"}, cbi(appname .. "/client/maintenance/app_update"), _("Update Center"), 3).leaf = true
    entry({"admin", "services", appname, "maintenance", "diagnostics"}, cbi(appname .. "/client/maintenance/diagnostics"), _("Diagnostics"), 4).leaf = true
    entry({"admin", "services", appname, "maintenance", "backup"}, cbi(appname .. "/client/maintenance/backup"), _("Backup & Restore"), 5).leaf = true
    entry({"admin", "services", appname, "maintenance", "cache"}, cbi(appname .. "/client/maintenance/cache"), _("System Maintenance"), 6).leaf = true
    entry({"admin", "services", appname, "maintenance", "scheduled_tasks"}, cbi(appname .. "/client/maintenance/scheduled_tasks"), _("Scheduled Tasks"), 7).leaf = true
end

-- Reset configuration
function reset_config()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.info("Resetting PassWall2 configuration")
    
    luci.sys.call('/etc/init.d/passwall2 stop')
    luci.sys.call('[ -f "/usr/share/passwall2/0_default_config" ] && cp -f /usr/share/passwall2/0_default_config /etc/config/passwall2')
    
    logger.info("Configuration reset completed")
    http.redirect(api.url())
end

-- Show menu in LuCI
function show_menu()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.info("Showing PassWall2 menu in LuCI")
    
    api.sh_uci_del(appname, "@global[0]", "hide_from_luci", true)
    luci.sys.call("rm -rf /tmp/luci-*")
    luci.sys.call("/etc/init.d/rpcd restart >/dev/null")
    
    http.redirect(api.url())
end

-- Hide menu from LuCI
function hide_menu()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.info("Hiding PassWall2 menu from LuCI")
    
    api.sh_uci_set(appname, "@global[0]", "hide_from_luci", "1", true)
    luci.sys.call("rm -rf /tmp/luci-*")
    luci.sys.call("/etc/init.d/rpcd restart >/dev/null")
    
    http.redirect(luci.dispatcher.build_url("admin", "status", "overview"))
end

-- Add node via link
function link_add_node()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("link_add_node", { ... })
    
    -- Fragmented reception to overcome uhttpd limitations
    local tmp_file = "/tmp/links.conf"
    local chunk = http.formvalue("chunk")
    local chunk_index = tonumber(http.formvalue("chunk_index"))
    local total_chunks = tonumber(http.formvalue("total_chunks"))
    local group = http.formvalue("group") or "default"

    if chunk and chunk_index ~= nil and total_chunks ~= nil then
        -- Assemble the files in order
        local mode = "a"
        if chunk_index == 0 then
            mode = "w"
        end
        local f = io.open(tmp_file, mode)
        if f then
            f:write(chunk)
            f:close()
        end
        -- If it's the last piece, then it will be executed.
        if chunk_index + 1 == total_chunks then
            logger.info("Processing node subscription for group: " .. group)
            luci.sys.call("lua /usr/share/passwall2/subscribe.lua add " .. group)
            logger.info("Node subscription completed for group: " .. group)
        end
    end
    
    logger.exit("link_add_node")
end

-- Add node to Socks configuration
function socks_autoswitch_add_node()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("socks_autoswitch_add_node", { ... })
    
    local id = http.formvalue("id")
    local key = http.formvalue("key")
    if id and id ~= "" and key and key ~= "" then
        uci:set(appname, id, "enable_autoswitch", "1")
        local new_list = uci:get(appname, id, "autoswitch_backup_node") or {}
        for i = #new_list, 1, -1 do
            if (uci:get(appname, new_list[i], "remarks") or ""):find(key) then
                table.remove(new_list, i)
            end
        end
        for k, e in ipairs(api.get_valid_nodes()) do
            if e.node_type == "normal" and e["remark"]:find(key) then
                table.insert(new_list, e.id)
            end
        end
        uci:set_list(appname, id, "autoswitch_backup_node", new_list)
        api.uci_save(uci, appname)
        
        logger.info("Added node to Socks autoswitch: " .. id)
    end
    
    logger.exit("socks_autoswitch_add_node")
    http.redirect(api.url("socks_config", id))
end

-- Remove node from Socks configuration
function socks_autoswitch_remove_node()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("socks_autoswitch_remove_node", { ... })
    
    local id = http.formvalue("id")
    local key = http.formvalue("key")
    if id and id ~= "" and key and key ~= "" then
        uci:set(appname, id, "enable_autoswitch", "1")
        local new_list = uci:get(appname, id, "autoswitch_backup_node") or {}
        for i = #new_list, 1, -1 do
            if (uci:get(appname, new_list[i], "remarks") or ""):find(key) then
                table.remove(new_list, i)
            end
        end
        uci:set_list(appname, id, "autoswitch_backup_node", new_list)
        api.uci_save(uci, appname)
        
        logger.info("Removed node from Socks autoswitch: " .. id)
    end
    
    logger.exit("socks_autoswitch_remove_node")
    http.redirect(api.url("socks_config", id))
end

-- Generate client configuration
function gen_client_config()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("gen_client_config", { ... })
    
    local id = http.formvalue("id")
    local config_file = api.TMP_PATH .. "/config_" .. id
    luci.sys.call(string.format("/usr/share/passwall2/app.sh run_socks flag=config_%s node=%s bind=127.0.0.1 socks_port=1080 config_file=%s no_run=1", id, id, config_file))
    
    if nixio.fs.access(config_file) then
        http.prepare_content("application/json")
        http.write(luci.sys.exec("cat " .. config_file))
        luci.sys.call("rm -f " .. config_file)
        logger.info("Generated client configuration for node: " .. id)
    else
        logger.warning("Failed to generate client configuration for node: " .. id)
        http.redirect(api.url("node_list"))
    end
    
    logger.exit("gen_client_config")
end

-- Get currently used node
function get_now_use_node()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("get_now_use_node")
    
    local e = {}
    local node = api.get_cache_var("ACL_GLOBAL_node")
    if node then
        e["global"] = node
    end
    
    logger.exit("get_now_use_node")
    http.prepare_content("application/json")
    http.write(luci.jsonc.stringify(e))
end

-- Get diagnostic log
function get_diagnostic_log()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("get_diagnostic_log", { ... })
    
    local log_type = http.formvalue("log_type")
    local log_path = ""
    local log_name = ""
    
    -- Map log types to file paths
    if log_type == "xray" then
        log_path = "/tmp/log/xray.log"
        log_name = "Xray Log"
    elseif log_type == "singbox" then
        log_path = "/tmp/log/sing-box.log"
        log_name = "Sing-Box Log"
    elseif log_type == "dns" then
        log_path = "/tmp/log/dns.log"
        log_name = "DNS Log"
    elseif log_type == "network" then
        log_path = "/tmp/log/network.log"
        log_name = "Network Log"
    elseif log_type == "firewall" then
        log_path = "/tmp/log/firewall.log"
        log_name = "Firewall Log"
    elseif log_type == "system" then
        log_path = "/tmp/log/system.log"
        log_name = "System Log"
    else
        logger.error("Invalid log type: " .. (log_type or "nil"))
        http_write_json_error("Invalid log type")
        return
    end
    
    -- Check if log file exists and read last 1000 lines
    if nixio.fs.access(log_path) then
        local content = luci.sys.exec("tail -n 1000 '" .. log_path .. "'")
        content = content:gsub("\n", "<br />")
        logger.info("Retrieved diagnostic log: " .. log_name)
        http_write_json_ok({
            name = log_name,
            content = content,
            exists = true
        })
    else
        logger.warning("Log file not found: " .. log_path)
        http_write_json_ok({
            name = log_name,
            content = "Log file not found or empty.",
            exists = false
        })
    end
    
    logger.exit("get_diagnostic_log")
end

-- Get connection status
function connect_status()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("connect_status", { ... })
    
    local e = {}
    e.use_time = ""
    local url = http.formvalue("url")
    local result = luci.sys.exec('curl --connect-timeout 3 -o /dev/null -I -sk -w "%{http_code}:%{time_appconnect}" ' .. url)
    local code = tonumber(luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $1}'") or "0")
    if code ~= 0 then
        local use_time = luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $2}'")
        if use_time:find("%.") then
            e.use_time = string.format("%.2f", use_time * 1000)
        else
            e.use_time = string.format("%.2f", use_time / 1000)
        end
        e.ping_type = "curl"
    end
    
    logger.exit("connect_status")
    http_write_json(e)
end

-- Ping node
function ping_node()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("ping_node", { ... })
    
    local index = http.formvalue("index")
    local address = http.formvalue("address")
    local port = http.formvalue("port")
    local type = http.formvalue("type") or "icmp"
    local e = {}
    e.index = index
    if type == "tcping" and luci.sys.exec("echo -n $(command -v tcping)") ~= "" then
        if api.is_ipv6(address) then
            address = api.get_ipv6_only(address)
        end
        e.ping = luci.sys.exec(string.format("echo -n $(tcping -q -c 1 -i 1 -t 2 -p %s %s 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}') 2>/dev/null", port, address))
    else
        e.ping = luci.sys.exec("echo -n $(ping -c 1 -W 1 %q 2>&1 | grep -o 'time=[0-9]*' | awk -F '=' '{print $2}') 2>/dev/null" % address)
    end
    
    logger.exit("ping_node")
    http_write_json(e)
end

-- URL test node
function urltest_node()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("urltest_node", { ... })
    
    local index = http.formvalue("index")
    local id = http.formvalue("id")
    local e = {}
    e.index = index
    local result = luci.sys.exec(string.format("/usr/share/passwall2/test.sh url_test_node %s %s", id, "urltest_node"))
    local code = tonumber(luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $1}'") or "0")
    if code ~= 0 then
        local use_time = luci.sys.exec("echo -n '" .. result .. "' | awk -F ':' '{print $2}'")
        if use_time:find("%.") then
            e.use_time = string.format("%.2f", use_time * 1000)
        else
            e.use_time = string.format("%.2f", use_time / 1000)
        end
    end
    
    logger.exit("urltest_node")
    http_write_json(e)
end

-- Add node
function add_node()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("add_node", { ... })
    
    local redirect = http.formvalue("redirect")
    local uuid = api.gen_short_uuid()
    uci:section(appname, "nodes", uuid)

    local group = http.formvalue("group")
    if group then
        uci:set(appname, uuid, "group", group)
    end

    uci:set(appname, uuid, "type", "Xray")

    if redirect == "1" then
        api.uci_save(uci, appname)
        http.redirect(api.url("node_config", uuid))
    else
        api.uci_save(uci, appname, true, true)
        logger.info("Added new node: " .. uuid)
        http_write_json({result = uuid})
    end
    
    logger.exit("add_node")
end

-- Update node
function update_node()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("update_node", { ... })
    
    local id = http.formvalue("id") -- Node id
    local data = http.formvalue("data") -- json new Data
    if id and data then
        local data_t = luci.jsonc.parse(data) or {}
        if next(data_t) then
            for k, v in pairs(data_t) do
                uci:set(appname, id, k, v)
            end
            api.uci_save(uci, appname)
            logger.info("Updated node: " .. id)
            http_write_json_ok()
            return
        end
    end
    logger.warning("Failed to update node: " .. (id or "unknown"))
    http_write_json_error()
    
    logger.exit("update_node")
end

-- Copy node
function copy_node()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("copy_node", { ... })
    
    local section = http.formvalue("section")
    local uuid = api.gen_short_uuid()
    uci:section(appname, "nodes", uuid)
    for k, v in pairs(uci:get_all(appname, section)) do
        local filter = k:find("%.")
        if filter and filter == 1 then
        else
            xpcall(function()
                uci:set(appname, uuid, k, v)
            end,
            function(e)
            end)
        end
    end
    uci:delete(appname, uuid, "group")
    uci:set(appname, uuid, "add_mode", 1)
    api.uci_save(uci, appname)
    
    logger.info("Copied node: " .. section .. " -> " .. uuid)
    logger.exit("copy_node")
    http.redirect(api.url("node_config", uuid))
end

-- Clear all nodes
function clear_all_nodes()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("clear_all_nodes")
    
    uci:set(appname, '@global[0]', "enabled", "0")
    uci:set(appname, '@global[0]', "socks_enabled", "0")
    uci:set(appname, '@haproxy_config[0]', "balancing_enable", "0")
    uci:delete(appname, '@global[0]', "node")
    uci:foreach(appname, "socks", function(t)
        uci:delete(appname, t[".name"])
        uci:set_list(appname, t[".name"], "autoswitch_backup_node", {})
    end)
    uci:foreach(appname, "haproxy_config", function(t)
        uci:delete(appname, t[".name"])
    end)
    uci:foreach(appname, "acl_rule", function(t)
        uci:delete(appname, t[".name"], "node")
    end)
    uci:foreach(appname, "nodes", function(node)
        uci:delete(appname, node['.name'])
    end)
    uci:foreach(appname, "subscribe_list", function(t)
        uci:delete(appname, t[".name"], "md5")
        uci:delete(appname, t[".name"], "chain_proxy")
        uci:delete(appname, t[".name"], "preproxy_node")
        uci:delete(appname, t[".name"], "to_node")
    end)

    api.uci_save(uci, appname, true, true)
    
    logger.info("Cleared all nodes")
    logger.exit("clear_all_nodes")
end

-- Delete selected nodes
function delete_select_nodes()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("delete_select_nodes", { ... })
    
    local ids = http.formvalue("ids")
    local redirect = http.formvalue("redirect")
    string.gsub(ids, '[^' .. "," .. ']+', function(w)
        if (uci:get(appname, "@global[0]", "node") or "") == w then
            uci:delete(appname, '@global[0]', "node")
        end
        uci:foreach(appname, "socks", function(t)
            if t["node"] == w then
                uci:delete(appname, t[".name"])
            end
            local auto_switch_node_list = uci:get(appname, t[".name"], "autoswitch_backup_node") or {}
            for i = #auto_switch_node_list, 1, -1 do
                if w == auto_switch_node_list[i] then
                    table.remove(auto_switch_node_list, i)
                end
            end
            uci:set_list(appname, t[".name"], "autoswitch_backup_node", auto_switch_node_list)
        end)
        uci:foreach(appname, "haproxy_config", function(t)
            if t["lbss"] == w then
                uci:delete(appname, t[".name"])
            end
        end)
        uci:foreach(appname, "acl_rule", function(t)
            if t["node"] == w then
                uci:delete(appname, t[".name"], "node")
            end
        end)
        uci:foreach(appname, "nodes", function(t)
            if t["preproxy_node"] == w then
                uci:delete(appname, t[".name"], "preproxy_node")
                uci:delete(appname, t[".name"], "chain_proxy")
            end
            if t["to_node"] == w then
                uci:delete(appname, t[".name"], "to_node")
                uci:delete(appname, t[".name"], "chain_proxy")
            end
            local list_name = t["urltest_node"] and "urltest_node" or (t["balancing_node"] and "balancing_node")
            if list_name then
                local nodes = uci:get_list(appname, t[".name"], list_name)
                if nodes then
                    local changed = false
                    local new_nodes = {}
                    for _, node in ipairs(nodes) do
                        if node ~= w then
                            table.insert(new_nodes, node)
                        else
                            changed = true
                        end
                    end
                    if changed then
                        uci:set_list(appname, t[".name"], list_name, new_nodes)
                    end
                end
            end
            if t["fallback_node"] == w then
                uci:delete(appname, t[".name"], "fallback_node")
            end
        end)
        uci:foreach(appname, "subscribe_list", function(t)
            if t["preproxy_node"] == w then
                uci:delete(appname, t[".name"], "preproxy_node")
                uci:delete(appname, t[".name"], "chain_proxy")
            end
            if t["to_node"] == w then
                uci:delete(appname, t[".name"], "to_node")
                uci:delete(appname, t[".name"], "chain_proxy")
            end
        end)
        if (uci:get(appname, w, "add_mode") or "0") == "2" then
            local group = uci:get(appname, w, "group") or ""
            if group ~= "" then
                uci:foreach(appname, "subscribe_list", function(t)
                    if t["remark"] == group then
                        uci:delete(appname, t[".name"], "md5")
                    end
                end)
            end
        end
        uci:delete(appname, w)
    end)
    
    if redirect == "1" then
        api.uci_save(uci, appname)
        logger.info("Deleted selected nodes")
        http.redirect(api.url("node_list"))
    else
        api.uci_save(uci, appname, true, true)
    end
    
    logger.exit("delete_select_nodes")
end

-- Get node information
function get_node()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("get_node", { ... })
    
    local id = http.formvalue("id")
    local result = {}
    local show_node_info = api.uci_get_type("global_other", "show_node_info", "0")

    local function add_is_ipv6_key(o)
        if o and o.address and show_node_info == "1" then
            local f = api.get_ipv6_full(o.address)
            if f ~= "" then
                o.ipv6 = true
                o.full_address = f
            end
        end
    end

    if id then
        result = uci:get_all(appname, id)
        add_is_ipv6_key(result)
    else
        local default_nodes = {}
        local other_nodes = {}
        uci:foreach(appname, "nodes", function(t)
            add_is_ipv6_key(t)
            if not t.group or t.group == "" then
                default_nodes[#default_nodes + 1] = t
            else
                other_nodes[#other_nodes + 1] = t
            end
        end)
        for i = 1, #default_nodes do result[#result + 1] = default_nodes[i] end
        for i = 1, #other_nodes do result[#result + 1] = other_nodes[i] end
    end
    
    logger.exit("get_node")
    http_write_json(result)
end

-- Save node order
function save_node_order()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("save_node_order", { ... })
    
    local ids = http.formvalue("ids") or ""
    local new_order = {}
    for id in ids:gmatch("([^,]+)") do
        new_order[#new_order + 1] = id
    end
    for idx, name in ipairs(new_order) do
        luci.sys.call(string.format("uci -q reorder %s.%s=%d", appname, name, idx - 1))
    end
    api.sh_uci_commit(appname)
    
    logger.info("Saved node order")
    logger.exit("save_node_order")
    http_write_json({ status = "ok" })
end

-- Reassign group
function reassign_group()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("reassign_group", { ... })
    
    local ids = http.formvalue("ids") or ""
    local group = http.formvalue("group") or "default"
    for id in ids:gmatch("([^,]+)") do
        if group ~="" and group ~= "default" then
            api.sh_uci_set(appname, id, "group", group)
        else
            api.sh_uci_del(appname, id, "group")
        end
    end
    api.sh_uci_commit(appname)
    
    logger.info("Reassigned group for nodes")
    logger.exit("reassign_group")
    http_write_json({ status = "ok" })
end

-- Save node list options
function save_node_list_opt()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("save_node_list_opt", { ... })
    
    local option = http.formvalue("option") or ""
    local value = http.formvalue("value") or ""
    if option ~= "" then
        api.sh_uci_set(appname, "@global_other[0]", option, value, true)
    end
    
    logger.info("Saved node list options")
    logger.exit("save_node_list_opt")
    http_write_json({ status = "ok" })
end

-- Update rules
function update_rules()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("update_rules", { ... })
    
    local update = http.formvalue("update")
    luci.sys.call("lua /usr/share/passwall2/rule_update.lua log '" .. update .. "' > /dev/null 2>&1 &")
    
    logger.info("Updated rules")
    logger.exit("update_rules")
    http_write_json()
end

-- Rollback rules
function rollback_rules()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("rollback_rules", { ... })
    
    local arg_type = http.formvalue("type")
    if arg_type ~= "geoip" and arg_type ~= "geosite" then
        logger.error("Invalid rule type for rollback: " .. (arg_type or "nil"))
        http_write_json_error()
        return
    end
    local bak_dir = "/tmp/bak_v2ray/"
    local geo_dir = (uci:get(appname, "@global_rules[0]", "v2ray_location_asset") or "/usr/share/v2ray/")
    fs.move(bak_dir .. arg_type .. ".dat", geo_dir .. arg_type .. ".dat")
    fs.rmdir(bak_dir)
    
    logger.info("Rolled back rules: " .. arg_type)
    logger.exit("rollback_rules")
    http_write_json_ok()
end

-- Subscribe delete node
function subscribe_del_node()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("subscribe_del_node", { ... })
    
    local remark = http.formvalue("remark")
    if remark and remark ~= "" then
        luci.sys.call("lua /usr/share/" .. appname .. "/subscribe.lua truncate " .. luci.util.shellquote(remark) .. " > /dev/null 2>&1")
        logger.info("Deleted subscription node: " .. remark)
    end
    
    logger.exit("subscribe_del_node")
    http.status(200, "OK")
end

-- Subscribe delete all
function subscribe_del_all()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("subscribe_del_all")
    
    luci.sys.call("lua /usr/share/" .. appname .. "/subscribe.lua truncate > /dev/null 2>&1")
    
    logger.info("Deleted all subscription nodes")
    logger.exit("subscribe_del_all")
    http.status(200, "OK")
end

-- Subscribe manual
function subscribe_manual()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("subscribe_manual", { ... })
    
    local section = http.formvalue("section") or ""
    local current_url = http.formvalue("url") or ""
    if section == "" or current_url == "" then
        logger.warning("Missing section or URL for manual subscription")
        http_write_json({ success = false, msg = "Missing section or URL, skip." })
        return
    end
    local uci_url = api.sh_uci_get(appname, section, "url")
    if not uci_url or uci_url == "" then
        logger.warning("No saved URL found for section: " .. section)
        http_write_json({ success = false, msg = i18n.translate("Please save and apply before manually subscribing.") })
        return
    end
    if uci_url ~= current_url then
        api.sh_uci_set(appname, section, "url", current_url, true)
    end
    luci.sys.call("lua /usr/share/" .. appname .. "/subscribe.lua start " .. section .. " manual >/dev/null 2>&1 &")
    
    logger.info("Started manual subscription for section: " .. section)
    logger.exit("subscribe_manual")
    http_write_json({ success = true, msg = "Subscribe triggered." })
end

-- Subscribe manual all
function subscribe_manual_all()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("subscribe_manual_all", { ... })
    
    local sections = http.formvalue("sections") or ""
    local urls = http.formvalue("urls") or ""
    if sections == "" or urls == "" then
        logger.warning("Missing sections or URLs for manual subscription")
        http_write_json({ success = false, msg = "Missing section or URL, skip." })
        return
    end
    local section_list = util.split(sections, ",")
    local url_list = util.split(urls, ",")
    -- Check if there are any unsaved configurations.
    for i, section in ipairs(section_list) do
        local uci_url = api.sh_uci_get(appname, section, "url")
        if not uci_url or uci_url == "" then
            logger.warning("No saved URL found for section: " .. section)
            http_write_json({ success = false, msg = i18n.translate("Please save and apply before manually subscribing.") })
            return
        end
    end
    -- Save URLs that have changed.
    for i, section in ipairs(section_list) do
        local current_url = url_list[i] or ""
        local uci_url = api.sh_uci_get(appname, section, "url")
        if current_url ~= "" and uci_url ~= current_url then
            api.sh_uci_set(appname, section, "url", current_url, true)
        end
    end
    luci.sys.call("lua /usr/share/" .. appname .. "/subscribe.lua start all manual >/dev/null 2>&1 &")
    
    logger.info("Started manual subscription for all sections")
    logger.exit("subscribe_manual_all")
    http_write_json({ success = true, msg = "Subscribe triggered." })
end

-- Flush set
function flush_set()
    local logger = require "luci.passwall2.core.utils.logger"
    logger.enter("flush_set", { ... })
    
    local redirect = http.formvalue("redirect") or "0"
    local reload = http.formvalue("reload") or "0"
    if reload == "1" then
        uci:set(appname, '@global[0]', "flush_set", "1")
        api.uci_save(uci, appname, true, true)
    else
        api.sh_uci_set(appname, "@global[0]", "flush_set", "1", true)
    end
    if redirect == "1" then
        logger.info("Flushed set and redirected")
        http.redirect(api.url("log"))
    else
        logger.info("Flushed set")
    end
    
    logger.exit("flush_set")
end

-- Helper functions for JSON responses
function http_write_json(content)
    http.prepare_content("application/json")
    http.write(luci.jsonc.stringify(content or {code = 1}))
end

function http_write_json_ok(data)
    http.prepare_content("application/json")
    http.write(luci.jsonc.stringify({code = 1, data = data}))
end

function http_write_json_error(data)
    http.prepare_content("application/json")
    http.write(luci.jsonc.stringify({code = 0, data = data}))
end

return {
    index = index,
    reset_config = reset_config,
    show_menu = show_menu,
    hide_menu = hide_menu,
    link_add_node = link_add_node,
    socks_autoswitch_add_node = socks_autoswitch_add_node,
    socks_autoswitch_remove_node = socks_autoswitch_remove_node,
    gen_client_config = gen_client_config,
    get_now_use_node = get_now_use_node,
    get_diagnostic_log = get_diagnostic_log,
    connect_status = connect_status,
    ping_node = ping_node,
    urltest_node = urltest_node,
    add_node = add_node,
    update_node = update_node,
    copy_node = copy_node,
    clear_all_nodes = clear_all_nodes,
    delete_select_nodes = delete_select_nodes,
    get_node = get_node,
    save_node_order = save_node_order,
    reassign_group = reassign_group,
    save_node_list_opt = save_node_list_opt,
    update_rules = update_rules,
    rollback_rules = rollback_rules,
    subscribe_del_node = subscribe_del_node,
    subscribe_del_all = subscribe_del_all,
    subscribe_manual = subscribe_manual,
    subscribe_manual_all = subscribe_manual_all,
    flush_set = flush_set,
    -- JSON helper functions for legacy controller
    http_write_json = http_write_json,
    http_write_json_ok = http_write_json_ok,
    http_write_json_error = http_write_json_error
}
