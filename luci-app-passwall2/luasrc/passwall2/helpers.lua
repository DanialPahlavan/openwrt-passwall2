-- PassWall2 Helper Utilities
-- Lua module for common functions
-- Optimized for low memory usage

local api = require "luci.passwall2.api"
local sys = require "luci.sys"

module("luci.passwall2.helpers", package.seeall)

-- Execute shell script and return JSON result
function exec_script(script_path, args)
    local cmd = script_path
    if args then
        cmd = cmd .. " " .. args
    end
    
    local result = api.sys.exec(cmd)
    if result and result ~= "" then
        return result
    end
    return nil
end

-- Get monitoring statistics
function get_monitor_stats()
    local stats_file = "/tmp/passwall2_stats.json"
    local content = api.fs.readfile(stats_file)
    
    if content then
        local json = require "luci.jsonc"
        return json.parse(content)
    end
    
    return {
        error = "No stats available"
    }
end

-- Format bytes to human readable
function format_bytes(bytes)
    local units = {"B", "KB", "MB", "GB"}
    local unit_index = 1
    local value = tonumber(bytes) or 0
    
    while value >= 1024 and unit_index < #units do
        value = value / 1024
        unit_index = unit_index + 1
    end
    
    return string.format("%.2f %s", value, units[unit_index])
end

-- Format uptime to human readable
function format_uptime(seconds)
    local secs = tonumber(seconds) or 0
    local days = math.floor(secs / 86400)
    local hours = math.floor((secs % 86400) / 3600)
    local mins = math.floor((secs % 3600) / 60)
    
    if days > 0 then
        return string.format("%dd %dh %dm", days, hours, mins)
    elseif hours > 0 then
        return string.format("%dh %dm", hours, mins)
    else
        return string.format("%dm", mins)
    end
end

-- Run diagnostic test
function run_diagnostic(test_type, param1, param2)
    local script = "/usr/share/passwall2/diagnostics.sh"
    local args = test_type
    
    if param1 then
        args = args .. " " .. param1
    end
    if param2 then
        args = args .. " " .. param2
    end
    
    return exec_script(script, args)
end

-- Get scheduled tasks list
function get_scheduled_tasks()
    local schedule_dir = "/etc/passwall2/schedules"
    local tasks = {}
    
    if api.fs.isdirectory(schedule_dir) then
        for file in api.fs.glob(schedule_dir .. "/*") do
            local task_name = api.fs.basename(file)
            local content = api.fs.readfile(file)
            
            if content then
                local task = {
                    name = task_name,
                    enabled = false,
                    schedule = "",
                    command = ""
                }
                
                for line in content:gmatch("[^\r\n]+") do
                    local key, value = line:match("^(%w+)=(.+)$")
                    if key == "ENABLED" then
                        task.enabled = (value == "1")
                    elseif key == "SCHEDULE" then
                        task.schedule = value
                    elseif key == "COMMAND" then
                        task.command = value
                    end
                end
                
                table.insert(tasks, task)
            end
        end
    end
    
    return tasks
end

-- Create backup
function create_backup(backup_type)
    local script = "/usr/share/passwall2/backup.sh"
    backup_type = backup_type or "full"
    return exec_script(script, backup_type)
end

-- List available backups
function list_backups()
    local script = "/usr/share/passwall2/backup.sh"
    local result = exec_script(script, "list")
    
    local backups = {}
    if result then
        for line in result:gmatch("[^\r\n]+") do
            -- Parse backup file information
            local filepath, size = line:match("([^ ]+)%s+%-+%s+(%S+)")
            if filepath then
                table.insert(backups, {
                    path = filepath,
                    size = size,
                    name = api.fs.basename(filepath)
                })
            end
        end
    end
    
    return backups
end

-- Check if service is running
function is_service_running()
    local result = api.sys.exec("pgrep -f passwall2 >/dev/null 2>&1; echo $?")
    return (result and result:match("^0"))
end

-- Get system resource usage
function get_system_resources()
    local resources = {}
    
    -- Memory
    local meminfo = api.fs.readfile("/proc/meminfo")
    if meminfo then
        local total = meminfo:match("MemTotal:%s+(%d+)")
        local free = meminfo:match("MemFree:%s+(%d+)")
        local available = meminfo:match("MemAvailable:%s+(%d+)")
        
        if total and available then
            resources.memory = {
                total = tonumber(total) * 1024,
                free = tonumber(free or 0) * 1024,
                available = tonumber(available) * 1024,
                used = (tonumber(total) - tonumber(available)) * 1024,
                usage_percent = math.floor(((tonumber(total) - tonumber(available)) / tonumber(total)) * 100)
            }
        end
    end
    
    -- Load average
    local loadavg = api.fs.readfile("/proc/loadavg")
    if loadavg then
        local load1, load5, load15 = loadavg:match("(%S+)%s+(%S+)%s+(%S+)")
        resources.load = {
            one = tonumber(load1) or 0,
            five = tonumber(load5) or 0,
            fifteen = tonumber(load15) or 0
        }
    end
    
    return resources
end

-- Validate cron schedule format
function validate_cron_schedule(schedule)
    if not schedule or schedule == "" then
        return false
    end
    
    local parts = {}
    for part in schedule:gmatch("%S+") do
        table.insert(parts, part)
    end
    
    -- Cron needs 5 parts: minute hour day month weekday
    return #parts == 5
end

-- Safe execute with timeout
function exec_with_timeout(cmd, timeout)
    timeout = timeout or 30
    local full_cmd = string.format("timeout %d %s 2>&1", timeout, cmd)
    return api.sys.exec(full_cmd)
end

return _M
