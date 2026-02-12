-- PassWall2 Statistics API Controller
-- Provides JSON endpoints for real-time monitoring data
local api = require "luci.passwall2.api"
local helpers = require "luci.passwall2.helpers"
local http = require "luci.http"
local jsonc = require "luci.jsonc"

local M = {}

-- Get current monitoring statistics
function M.get_stats()
    local stats = helpers.get_monitor_stats()
    http.prepare_content("application/json")
    http.write(jsonc.stringify(stats))
end

-- Get system resources
function M.get_resources()
    local resources = helpers.get_system_resources()
    http.prepare_content("application/json")
    http.write(jsonc.stringify(resources))
end

-- Run diagnostic test
function M.run_diagnostic()
    local test_type = http.formvalue("type") or "full"
    local param1 = http.formvalue("param1")
    local param2 = http.formvalue("param2")

    local result = helpers.run_diagnostic(test_type, param1, param2)

    http.prepare_content("application/json")
    http.write(jsonc.stringify({
        success = result ~= nil,
        output = result or "Test failed"
    }))
end

-- Get scheduled tasks
function M.get_tasks()
    local tasks = helpers.get_scheduled_tasks()
    http.prepare_content("application/json")
    http.write(jsonc.stringify(tasks))
end

-- Create backup
function M.create_backup()
    local backup_type = http.formvalue("type") or "full"
    local result = helpers.create_backup(backup_type)

    http.prepare_content("application/json")
    http.write(jsonc.stringify({
        success = result ~= nil,
        output = result or "Backup failed"
    }))
end

-- List backups
function M.list_backups()
    local backups = helpers.list_backups()
    http.prepare_content("application/json")
    http.write(jsonc.stringify(backups))
end

-- Start monitoring service
function M.start_monitor()
    local cmd = "/usr/share/passwall2/monitor.sh start &"
    api.sys.call(cmd)

    http.prepare_content("application/json")
    http.write(jsonc.stringify({
        success = true,
        message = "Monitor started"
    }))
end

-- Stop monitoring service
function M.stop_monitor()
    local cmd = "/usr/share/passwall2/monitor.sh stop"
    api.sys.call(cmd)

    http.prepare_content("application/json")
    http.write(jsonc.stringify({
        success = true,
        message = "Monitor stopped"
    }))
end

return M
