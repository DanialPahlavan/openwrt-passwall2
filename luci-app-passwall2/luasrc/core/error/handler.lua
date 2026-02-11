module("luci.passwall2.core.error.handler", package.seeall)

-- Error codes and messages
local error_codes = {
    -- Configuration errors (1000-1999)
    CONFIG_INVALID = 1001,
    CONFIG_MISSING_REQUIRED = 1002,
    CONFIG_INVALID_DATATYPE = 1003,
    CONFIG_VALIDATION_FAILED = 1004,
    
    -- Protocol errors (2000-2999)
    PROTOCOL_NOT_FOUND = 2001,
    PROTOCOL_NOT_SUPPORTED = 2002,
    PROTOCOL_CONFIG_INVALID = 2003,
    PROTOCOL_CONNECTION_FAILED = 2004,
    
    -- Network errors (3000-3999)
    CONNECTION_TIMEOUT = 3001,
    CONNECTION_REFUSED = 3002,
    NETWORK_UNREACHABLE = 3003,
    DNS_RESOLUTION_FAILED = 3004,
    
    -- System errors (4000-4999)
    SYSTEM_ERROR = 4001,
    FILE_NOT_FOUND = 4002,
    PERMISSION_DENIED = 4003,
    INSUFFICIENT_MEMORY = 4004,
    
    -- API errors (5000-5999)
    API_ERROR = 5001,
    API_TIMEOUT = 5002,
    API_INVALID_RESPONSE = 5003,
    API_RATE_LIMITED = 5004,
    
    -- UI errors (6000-6999)
    UI_ERROR = 6001,
    UI_INVALID_INPUT = 6002,
    UI_RENDER_FAILED = 6003,
    UI_COMPONENT_NOT_FOUND = 6004
}

local error_messages = {
    [1001] = "Configuration is invalid: %s",
    [1002] = "Required configuration field missing: %s",
    [1003] = "Invalid data type for field '%s': %s",
    [1004] = "Configuration validation failed: %s",
    
    [2001] = "Protocol not found: %s",
    [2002] = "Protocol not supported: %s",
    [2003] = "Protocol configuration is invalid: %s",
    [2004] = "Protocol connection failed: %s",
    
    [3001] = "Connection timeout: %s",
    [3002] = "Connection refused: %s",
    [3003] = "Network unreachable: %s",
    [3004] = "DNS resolution failed: %s",
    
    [4001] = "System error: %s",
    [4002] = "File not found: %s",
    [4003] = "Permission denied: %s",
    [4004] = "Insufficient memory: %s",
    
    [5001] = "API error: %s",
    [5002] = "API timeout: %s",
    [5003] = "API invalid response: %s",
    [5004] = "API rate limited: %s",
    
    [6001] = "UI error: %s",
    [6002] = "Invalid UI input: %s",
    [6003] = "UI render failed: %s",
    [6004] = "UI component not found: %s"
}

-- Error severity levels
local error_severity = {
    DEBUG = "debug",
    INFO = "info",
    WARNING = "warning",
    ERROR = "error",
    CRITICAL = "critical"
}

-- Error context information
local error_context = {
    component = nil,
    function_name = nil,
    line_number = nil,
    timestamp = nil,
    user_id = nil,
    session_id = nil
}

-- Create error object
function create_error(code, message, context)
    local error_obj = {
        code = code,
        message = string.format(error_messages[code] or "Unknown error: %s", message),
        severity = get_error_severity(code),
        context = context or {},
        timestamp = os.time(),
        stacktrace = debug.traceback()
    }
    
    -- Add context information
    if error_context.component then
        error_obj.context.component = error_context.component
    end
    if error_context.function_name then
        error_obj.context.function_name = error_context.function_name
    end
    if error_context.line_number then
        error_obj.context.line_number = error_context.line_number
    end
    if error_context.user_id then
        error_obj.context.user_id = error_context.user_id
    end
    if error_context.session_id then
        error_obj.context.session_id = error_context.session_id
    end
    
    return error_obj
end

-- Get error severity based on error code
function get_error_severity(code)
    if code >= 6000 then
        return error_severity.CRITICAL
    elseif code >= 5000 then
        return error_severity.ERROR
    elseif code >= 4000 then
        return error_severity.WARNING
    elseif code >= 3000 then
        return error_severity.INFO
    else
        return error_severity.DEBUG
    end
end

-- Handle error with logging
function handle_error(code, message, context)
    local logger = require "luci.passwall2.core.utils.logger"
    local error_obj = create_error(code, message, context)
    
    -- Log error based on severity
    local severity = error_obj.severity
    if severity == error_severity.CRITICAL then
        logger:critical(error_obj.message, error_obj)
    elseif severity == error_severity.ERROR then
        logger:error(error_obj.message, error_obj)
    elseif severity == error_severity.WARNING then
        logger:warning(error_obj.message, error_obj)
    elseif severity == error_severity.INFO then
        logger:info(error_obj.message, error_obj)
    else
        logger:debug(error_obj.message, error_obj)
    end
    
    return error_obj
end

-- Handle configuration errors
function handle_config_error(message, field_name)
    return handle_error(error_codes.CONFIG_INVALID, message, { field = field_name })
end

-- Handle protocol errors
function handle_protocol_error(message, protocol_name)
    return handle_error(error_codes.PROTOCOL_NOT_FOUND, message, { protocol = protocol_name })
end

-- Handle network errors
function handle_network_error(message, address)
    return handle_error(error_codes.CONNECTION_TIMEOUT, message, { address = address })
end

-- Handle system errors
function handle_system_error(message, file_path)
    return handle_error(error_codes.SYSTEM_ERROR, message, { file = file_path })
end

-- Handle API errors
function handle_api_error(message, api_endpoint)
    return handle_error(error_codes.API_ERROR, message, { endpoint = api_endpoint })
end

-- Handle UI errors
function handle_ui_error(message, component_name)
    return handle_error(error_codes.UI_ERROR, message, { component = component_name })
end

-- Set error context
function set_context(key, value)
    error_context[key] = value
end

-- Clear error context
function clear_context()
    error_context = {
        component = nil,
        function_name = nil,
        line_number = nil,
        timestamp = nil,
        user_id = nil,
        session_id = nil
    }
end

-- Get error context
function get_context()
    return error_context
end

-- Error recovery strategies
local recovery_strategies = {
    [error_codes.CONFIG_INVALID] = function(error_obj)
        return "Please check your configuration and try again"
    end,
    [error_codes.PROTOCOL_NOT_FOUND] = function(error_obj)
        return "Please select a valid protocol and try again"
    end,
    [error_codes.CONNECTION_TIMEOUT] = function(error_obj)
        return "Please check your network connection and try again"
    end,
    [error_codes.SYSTEM_ERROR] = function(error_obj)
        return "Please restart the application and try again"
    end
}

-- Get recovery suggestion
function get_recovery_suggestion(code)
    local strategy = recovery_strategies[code]
    if strategy then
        return strategy()
    end
    return "Please contact support for assistance"
end

-- Error formatting for display
function format_error_for_display(error_obj)
    local formatted = {
        code = error_obj.code,
        message = error_obj.message,
        severity = error_obj.severity,
        timestamp = os.date("%Y-%m-%d %H:%M:%S", error_obj.timestamp),
        recovery = get_recovery_suggestion(error_obj.code)
    }
    
    if error_obj.context then
        formatted.context = error_obj.context
    end
    
    return formatted
end

-- Error formatting for logging
function format_error_for_logging(error_obj)
    local log_entry = string.format(
        "[%s] Error %d (%s): %s",
        os.date("%Y-%m-%d %H:%M:%S", error_obj.timestamp),
        error_obj.code,
        error_obj.severity,
        error_obj.message
    )
    
    if error_obj.context then
        local context_parts = {}
        for k, v in pairs(error_obj.context) do
            table.insert(context_parts, string.format("%s=%s", k, v))
        end
        if #context_parts > 0 then
            log_entry = log_entry .. " [" .. table.concat(context_parts, ", ") .. "]"
        end
    end
    
    return log_entry
end

-- Error wrapper for functions
function wrap_function(func, context_info)
    return function(...)
        local success, result = pcall(func, ...)
        if not success then
            local error_msg = tostring(result)
            local error_obj = handle_error(error_codes.SYSTEM_ERROR, error_msg, context_info)
            return false, error_obj
        end
        return true, result
    end
end

-- Validate error code
function is_valid_error_code(code)
    return error_messages[code] ~= nil
end

-- Get all error codes
function get_all_error_codes()
    local codes = {}
    for code, _ in pairs(error_messages) do
        table.insert(codes, code)
    end
    table.sort(codes)
    return codes
end

-- Get error codes by category
function get_error_codes_by_category(category)
    local codes = {}
    local start_code, end_code
    
    if category == "config" then
        start_code, end_code = 1000, 1999
    elseif category == "protocol" then
        start_code, end_code = 2000, 2999
    elseif category == "network" then
        start_code, end_code = 3000, 3999
    elseif category == "system" then
        start_code, end_code = 4000, 4999
    elseif category == "api" then
        start_code, end_code = 5000, 5999
    elseif category == "ui" then
        start_code, end_code = 6000, 6999
    else
        return codes
    end
    
    for code, _ in pairs(error_messages) do
        if code >= start_code and code <= end_code then
            table.insert(codes, code)
        end
    end
    
    table.sort(codes)
    return codes
end

return {
    codes = error_codes,
    messages = error_messages,
    severity = error_severity,
    create_error = create_error,
    handle_error = handle_error,
    handle_config_error = handle_config_error,
    handle_protocol_error = handle_protocol_error,
    handle_network_error = handle_network_error,
    handle_system_error = handle_system_error,
    handle_api_error = handle_api_error,
    handle_ui_error = handle_ui_error,
    set_context = set_context,
    clear_context = clear_context,
    get_context = get_context,
    get_recovery_suggestion = get_recovery_suggestion,
    format_error_for_display = format_error_for_display,
    format_error_for_logging = format_error_for_logging,
    wrap_function = wrap_function,
    is_valid_error_code = is_valid_error_code,
    get_all_error_codes = get_all_error_codes,
    get_error_codes_by_category = get_error_codes_by_category
}