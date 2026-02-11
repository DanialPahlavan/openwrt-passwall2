module("luci.passwall2.core.protocol.base", package.seeall)

-- Protocol base class that defines the interface for all protocols
local base = {
    name = "",
    type = "",
    protocols = {},
    config_schema = {},
    default_config = {}
}

-- Constructor
function base:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

-- Abstract methods that must be implemented by protocol subclasses
-- These will be overridden by specific protocol implementations

-- Validate configuration for this protocol
function base:validate_config(config)
    error("validate_config method must be implemented by protocol subclass")
end

-- Generate configuration for this protocol
function base:generate_config(config)
    error("generate_config method must be implemented by protocol subclass")
end

-- Test connection for this protocol
function base:test_connection(config)
    error("test_connection method must be implemented by protocol subclass")
end

-- Get supported protocols for this protocol type
function base:get_supported_protocols()
    return self.protocols or {}
end

-- Get configuration schema for this protocol
function base:get_config_schema()
    return self.config_schema or {}
end

-- Get default configuration for this protocol
function base:get_default_config()
    return self.default_config or {}
end

-- Check if a protocol is supported
function base:is_protocol_supported(protocol)
    local supported = self:get_supported_protocols()
    for _, p in ipairs(supported) do
        if p == protocol then
            return true
        end
    end
    return false
end

-- Merge configuration with defaults
function base:merge_with_defaults(config)
    local defaults = self:get_default_config()
    local merged = {}
    
    -- Copy defaults first
    for k, v in pairs(defaults) do
        merged[k] = v
    end
    
    -- Override with provided config
    for k, v in pairs(config or {}) do
        merged[k] = v
    end
    
    return merged
end

-- Validate required fields
function base:validate_required_fields(config)
    local schema = self:get_config_schema()
    local errors = {}
    
    for field_name, field_config in pairs(schema) do
        if field_config.required and (config[field_name] == nil or config[field_name] == "") then
            table.insert(errors, string.format("Required field '%s' is missing", field_name))
        end
    end
    
    return #errors == 0, errors
end

-- Get field datatype
function base:get_field_datatype(field_name)
    local schema = self:get_config_schema()
    if schema[field_name] then
        return schema[field_name].datatype
    end
    return nil
end

-- Format configuration for display
function base:format_config_for_display(config)
    local formatted = {}
    local schema = self:get_config_schema()
    
    for field_name, value in pairs(config) do
        local field_config = schema[field_name]
        if field_config then
            formatted[field_name] = {
                value = value,
                title = field_config.title or field_name,
                description = field_config.description or "",
                datatype = field_config.datatype or "string"
            }
        else
            formatted[field_name] = {
                value = value,
                title = field_name,
                description = "",
                datatype = "string"
            }
        end
    end
    
    return formatted
end

return base