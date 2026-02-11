module("luci.passwall2.core.utils.logger", package.seeall)

local fs = require "nixio.fs"
local sys = require "luci.sys"

-- Log levels
local LOG_LEVELS = {
    DEBUG = 1,
    INFO = 2,
    WARNING = 3,
    ERROR = 4,
    CRITICAL = 5
}

-- Log level names
local LOG_LEVEL_NAMES = {
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARNING",
    [4] = "ERROR",
    [5] = "CRITICAL"
}

-- Default configuration
local default_config = {
    level = LOG_LEVELS.INFO,
    file = "/tmp/log/passwall2.log",
    max_size = 1024 * 1024, -- 1MB
    max_files = 5,
    format = "[%timestamp%] [%level%] %message%",
    enabled = true,
    console = true
}

-- Logger state
local logger_state = {
    config = default_config,
    file_handle = nil,
    buffer = {},
    buffer_size = 0,
    buffer_max_size = 1024 * 1024, -- 1MB buffer
    flush_interval = 5, -- seconds
    last_flush = 0
}

-- Initialize logger
function init(config)
    if config then
        for k, v in pairs(config) do
            logger_state.config[k] = v
        end
    end
    
    -- Ensure log directory exists
    local log_dir = logger_state.config.file:match("(.*/)")
    if log_dir then
        fs.mkdirr(log_dir)
    end
    
    -- Open log file
    open_log_file()
    
    -- Set up periodic flush
    sys.call(string.format('echo "lua -e \\"require \\'luci.passwall2.core.utils.logger\\'.flush()\\" > /dev/null 2>&1" | at now + %d minutes', logger_state.flush_interval))
end

-- Open log file
function open_log_file()
    if logger_state.config.file then
        logger_state.file_handle = io.open(logger_state.config.file, "a")
        if logger_state.file_handle then
            logger_state.file_handle:setvbuf("line")
        end
    end
end

-- Close log file
function close_log_file()
    if logger_state.file_handle then
        logger_state.file_handle:close()
        logger_state.file_handle = nil
    end
end

-- Rotate log file
function rotate_log()
    if not logger_state.config.file then return end
    
    local log_file = logger_state.config.file
    local max_files = logger_state.config.max_files or 5
    
    -- Close current file
    close_log_file()
    
    -- Rotate existing files
    for i = max_files - 1, 1, -1 do
        local old_file = log_file .. "." .. i
        local new_file = log_file .. "." .. (i + 1)
        if fs.access(old_file) then
            fs.move(old_file, new_file)
        end
    end
    
    -- Move current log to .1
    if fs.access(log_file) then
        fs.move(log_file, log_file .. ".1")
    end
    
    -- Open new log file
    open_log_file()
end

-- Check if log file needs rotation
function check_rotation()
    if not logger_state.config.file then return end
    
    local file_size = fs.stat(logger_state.config.file, "size")
    if file_size and file_size > (logger_state.config.max_size or 1024 * 1024) then
        rotate_log()
    end
end

-- Format log message
function format_message(level, message, context)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local level_name = LOG_LEVEL_NAMES[level] or "UNKNOWN"
    
    local formatted = logger_state.config.format
        :gsub("%%timestamp%%", timestamp)
        :gsub("%%level%%", level_name)
        :gsub("%%message%%", message)
    
    -- Add context information
    if context then
        local context_str = ""
        for k, v in pairs(context) do
            context_str = context_str .. string.format(" [%s=%s]", k, tostring(v))
        end
        formatted = formatted .. context_str
    end
    
    return formatted
end

-- Write to console
function write_to_console(message)
    if logger_state.config.console then
        print(message)
    end
end

-- Write to file
function write_to_file(message)
    if logger_state.file_handle then
        logger_state.file_handle:write(message .. "\n")
        logger_state.file_handle:flush()
    end
end

-- Write to buffer
function write_to_buffer(message)
    table.insert(logger_state.buffer, message)
    logger_state.buffer_size = logger_state.buffer_size + #message + 1
    
    -- Check buffer size
    if logger_state.buffer_size > logger_state.buffer_max_size then
        flush()
    end
end

-- Flush buffer
function flush()
    if #logger_state.buffer > 0 then
        for _, message in ipairs(logger_state.buffer) do
            write_to_file(message)
        end
        logger_state.buffer = {}
        logger_state.buffer_size = 0
        logger_state.last_flush = os.time()
    end
end

-- Check if message should be logged
function should_log(level)
    return logger_state.config.enabled and level >= logger_state.config.level
end

-- Log message
function log(level, message, context)
    if not should_log(level) then return end
    
    local formatted_message = format_message(level, message, context)
    
    -- Write to console
    write_to_console(formatted_message)
    
    -- Write to buffer (for performance)
    write_to_buffer(formatted_message)
    
    -- Check rotation
    check_rotation()
end

-- Debug level logging
function debug(message, context)
    log(LOG_LEVELS.DEBUG, message, context)
end

-- Info level logging
function info(message, context)
    log(LOG_LEVELS.INFO, message, context)
end

-- Warning level logging
function warning(message, context)
    log(LOG_LEVELS.WARNING, message, context)
end

-- Error level logging
function error(message, context)
    log(LOG_LEVELS.ERROR, message, context)
end

-- Critical level logging
function critical(message, context)
    log(LOG_LEVELS.CRITICAL, message, context)
end

-- Log function entry
function enter(function_name, args)
    if should_log(LOG_LEVELS.DEBUG) then
        local arg_str = ""
        if args then
            local arg_parts = {}
            for i, arg in ipairs(args) do
                table.insert(arg_parts, tostring(arg))
            end
            arg_str = " [" .. table.concat(arg_parts, ", ") .. "]"
        end
        debug("Entering " .. function_name .. arg_str, { function = function_name })
    end
end

-- Log function exit
function exit(function_name, result)
    if should_log(LOG_LEVELS.DEBUG) then
        local result_str = ""
        if result then
            result_str = " [result=" .. tostring(result) .. "]"
        end
        debug("Exiting " .. function_name .. result_str, { function = function_name })
    end
end

-- Log function with timing
function timed(function_name, func, ...)
    enter(function_name, {...})
    local start_time = os.clock()
    local success, result = pcall(func, ...)
    local end_time = os.clock()
    local duration = end_time - start_time
    
    if success then
        exit(function_name, result)
        if should_log(LOG_LEVELS.INFO) then
            info(string.format("%s completed in %.3f seconds", function_name, duration), { function = function_name, duration = duration })
        end
        return result
    else
        error(string.format("%s failed after %.3f seconds: %s", function_name, duration, result), { function = function_name, duration = duration })
        return nil, result
    end
end

-- Log configuration changes
function config_change(config_key, old_value, new_value)
    info(string.format("Configuration changed: %s = %s -> %s", config_key, tostring(old_value), tostring(new_value)), {
        type = "config_change",
        key = config_key,
        old_value = old_value,
        new_value = new_value
    })
end

-- Log errors with stack trace
function error_with_stack(message, stack)
    local context = { stacktrace = stack or debug.traceback() }
    error(message, context)
end

-- Set log level
function set_level(level)
    if type(level) == "string" then
        for k, v in pairs(LOG_LEVEL_NAMES) do
            if v:lower() == level:lower() then
                level = k
                break
            end
        end
    end
    
    if LOG_LEVELS[level] then
        logger_state.config.level = LOG_LEVELS[level]
        info(string.format("Log level changed to %s", LOG_LEVEL_NAMES[level]), { level = level })
    end
end

-- Get current log level
function get_level()
    return logger_state.config.level
end

-- Enable/disable logging
function set_enabled(enabled)
    logger_state.config.enabled = enabled
    info(string.format("Logging %s", enabled and "enabled" or "disabled"))
end

-- Get log file path
function get_log_file()
    return logger_state.config.file
end

-- Clear log file
function clear_log()
    if logger_state.config.file and fs.access(logger_state.config.file) then
        fs.writefile(logger_state.config.file, "")
        info("Log file cleared")
    end
end

-- Get log file size
function get_log_size()
    if logger_state.config.file then
        local size = fs.stat(logger_state.config.file, "size")
        return size or 0
    end
    return 0
end

-- Get log statistics
function get_stats()
    return {
        level = logger_state.config.level,
        level_name = LOG_LEVEL_NAMES[logger_state.config.level],
        file = logger_state.config.file,
        enabled = logger_state.config.enabled,
        console = logger_state.config.console,
        buffer_size = logger_state.buffer_size,
        buffer_count = #logger_state.buffer,
        last_flush = logger_state.last_flush,
        file_size = get_log_size()
    }
end

-- Wrap function with logging
function wrap_with_logging(func_name, func)
    return function(...)
        enter(func_name, {...})
        local result = { func(...) }
        exit(func_name, result[1])
        return unpack(result)
    end
end

-- Create a child logger with specific context
function create_child(context)
    return {
        debug = function(message)
            debug(message, context)
        end,
        info = function(message)
            info(message, context)
        end,
        warning = function(message)
            warning(message, context)
        end,
        error = function(message)
            error(message, context)
        end,
        critical = function(message)
            critical(message, context)
        end,
        timed = function(func_name, func, ...)
            return timed(func_name, func, ...)
        end
    }
end

-- Log performance metrics
function log_performance(metric_name, value, unit)
    info(string.format("Performance metric: %s = %s %s", metric_name, tostring(value), unit or ""), {
        type = "performance",
        metric = metric_name,
        value = value,
        unit = unit
    })
end

-- Log memory usage
function log_memory_usage()
    local memory = collectgarbage("count")
    log_performance("memory_usage", memory, "KB")
end

-- Log system information
function log_system_info()
    local sys_info = {
        os = sys.exec("uname -s"),
        arch = sys.exec("uname -m"),
        uptime = sys.exec("uptime"),
        memory = sys.exec("free -h"),
        disk = sys.exec("df -h")
    }
    
    for key, value in pairs(sys_info) do
        info(string.format("System %s: %s", key, value:gsub("\n", " ")), { type = "system_info", key = key })
    end
end

-- Initialize default logger
init()

return {
    init = init,
    debug = debug,
    info = info,
    warning = warning,
    error = error,
    critical = critical,
    enter = enter,
    exit = exit,
    timed = timed,
    config_change = config_change,
    error_with_stack = error_with_stack,
    set_level = set_level,
    get_level = get_level,
    set_enabled = set_enabled,
    get_log_file = get_log_file,
    clear_log = clear_log,
    get_log_size = get_log_size,
    get_stats = get_stats,
    wrap_with_logging = wrap_with_logging,
    create_child = create_child,
    log_performance = log_performance,
    log_memory_usage = log_memory_usage,
    log_system_info = log_system_info,
    flush = flush
}