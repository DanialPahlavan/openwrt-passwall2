module("luci.passwall2.core.protocol.factory", package.seeall)

local base = require "luci.passwall2.core.protocol.base"

-- Protocol registry to store all registered protocols
local protocols = {}
local protocol_instances = {}

-- Register a protocol class
-- @param name: Protocol name (e.g., "sing-box", "xray")
-- @param protocol_class: The protocol class/table
function register(name, protocol_class)
    if not name or not protocol_class then
        error("Protocol name and class are required")
    end
    
    -- Ensure the protocol class inherits from base
    if not protocol_class.new then
        -- If it doesn't have a new method, make it inherit from base
        setmetatable(protocol_class, { __index = base })
        protocol_class.__index = protocol_class
    end
    
    protocols[name] = protocol_class
end

-- Create a protocol instance
-- @param name: Protocol name
-- @param config: Configuration table (optional)
-- @return: Protocol instance
function create(name, config)
    local protocol_class = protocols[name]
    if not protocol_class then
        error("Unknown protocol: " .. tostring(name))
    end
    
    -- Create instance
    local instance = protocol_class:new()
    
    -- Store instance for potential reuse
    local instance_key = name .. "_" .. tostring(config and config.address or "default")
    protocol_instances[instance_key] = instance
    
    -- Apply configuration if provided
    if config then
        instance = instance:merge_with_defaults(config)
    end
    
    return instance
end

-- Get all registered protocol names
-- @return: Table of protocol names
function get_supported_protocols()
    local supported = {}
    for name, _ in pairs(protocols) do
        table.insert(supported, name)
    end
    return supported
end

-- Check if a protocol is registered
-- @param name: Protocol name
-- @return: Boolean indicating if protocol is supported
function is_protocol_supported(name)
    return protocols[name] ~= nil
end

-- Get protocol class by name
-- @param name: Protocol name
-- @return: Protocol class or nil
function get_protocol_class(name)
    return protocols[name]
end

-- Get all protocol instances
-- @return: Table of protocol instances
function get_all_instances()
    return protocol_instances
end

-- Clear all protocol instances (useful for testing)
function clear_instances()
    protocol_instances = {}
end

-- Get protocol information
-- @param name: Protocol name
-- @return: Table with protocol info or nil
function get_protocol_info(name)
    local protocol_class = protocols[name]
    if not protocol_class then
        return nil
    end
    
    return {
        name = name,
        supported_protocols = protocol_class:get_supported_protocols(),
        config_schema = protocol_class:get_config_schema(),
        default_config = protocol_class:get_default_config()
    }
end

-- List all registered protocols with their details
-- @return: Table of protocol details
function list_all_protocols()
    local protocol_list = {}
    for name, protocol_class in pairs(protocols) do
        protocol_list[name] = get_protocol_info(name)
    end
    return protocol_list
end

-- Validate protocol configuration
-- @param name: Protocol name
-- @param config: Configuration to validate
-- @return: Boolean (valid/invalid), errors table
function validate_protocol_config(name, config)
    local protocol_class = protocols[name]
    if not protocol_class then
        return false, { "Protocol not found: " .. name }
    end
    
    -- Create temporary instance for validation
    local instance = protocol_class:new()
    instance = instance:merge_with_defaults(config)
    
    -- Validate required fields
    local valid, errors = instance:validate_required_fields(config)
    if not valid then
        return false, errors
    end
    
    -- Call protocol-specific validation
    local protocol_valid, protocol_errors = pcall(function()
        return instance:validate_config(config)
    end)
    
    if not protocol_valid then
        table.insert(errors, "Protocol validation failed: " .. tostring(protocol_errors))
        return false, errors
    end
    
    return true, {}
end

-- Test protocol connection
-- @param name: Protocol name
-- @param config: Configuration to test
-- @return: Boolean (success/failure), result details
function test_protocol_connection(name, config)
    local protocol_class = protocols[name]
    if not protocol_class then
        return false, { error = "Protocol not found: " .. name }
    end
    
    -- Create instance
    local instance = protocol_class:new()
    instance = instance:merge_with_defaults(config)
    
    -- Test connection
    local success, result = pcall(function()
        return instance:test_connection(config)
    end)
    
    if not success then
        return false, { error = "Connection test failed: " .. tostring(result) }
    end
    
    return true, result
end

return {
    register = register,
    create = create,
    get_supported_protocols = get_supported_protocols,
    is_protocol_supported = is_protocol_supported,
    get_protocol_class = get_protocol_class,
    get_all_instances = get_all_instances,
    clear_instances = clear_instances,
    get_protocol_info = get_protocol_info,
    list_all_protocols = list_all_protocols,
    validate_protocol_config = validate_protocol_config,
    test_protocol_connection = test_protocol_connection
}