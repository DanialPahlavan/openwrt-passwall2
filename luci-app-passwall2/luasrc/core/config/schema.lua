module("luci.passwall2.core.config.schema", package.seeall)

-- Configuration schemas for different components
local schemas = {
    -- Global configuration schema
    global = {
        enabled = {
            required = false,
            datatype = "boolean",
            title = "Main Switch",
            description = "Enable or disable PassWall2"
        },
        node = {
            required = false,
            datatype = "string",
            title = "Main Node",
            description = "Default node for proxy"
        },
        localhost_proxy = {
            required = false,
            datatype = "boolean",
            title = "Localhost Proxy",
            description = "Allow localhost to use proxy"
        },
        client_proxy = {
            required = false,
            datatype = "boolean",
            title = "Client Proxy",
            description = "Allow clients to use proxy"
        },
        node_socks_port = {
            required = false,
            datatype = "port",
            title = "Node Socks Port",
            description = "Socks proxy port"
        },
        node_socks_bind_local = {
            required = false,
            datatype = "boolean",
            title = "Bind Local",
            description = "Bind to localhost only"
        },
        socks_enabled = {
            required = false,
            datatype = "boolean",
            title = "Socks Enabled",
            description = "Enable Socks proxy"
        },
        log_node = {
            required = false,
            datatype = "boolean",
            title = "Log Node",
            description = "Enable node logging"
        },
        loglevel = {
            required = false,
            datatype = "string",
            title = "Log Level",
            description = "Logging level"
        }
    },
    
    -- Node configuration schema
    node = {
        type = {
            required = true,
            datatype = "string",
            title = "Type",
            description = "Protocol type (sing-box, xray, etc.)"
        },
        protocol = {
            required = true,
            datatype = "string",
            title = "Protocol",
            description = "Protocol (vmess, vless, shadowsocks, etc.)"
        },
        address = {
            required = true,
            datatype = "host",
            title = "Address",
            description = "Server address"
        },
        port = {
            required = true,
            datatype = "port",
            title = "Port",
            description = "Server port"
        },
        remarks = {
            required = true,
            datatype = "string",
            title = "Remarks",
            description = "Node description"
        },
        tls = {
            required = false,
            datatype = "boolean",
            title = "TLS",
            description = "Enable TLS encryption"
        },
        tls_serverName = {
            required = false,
            datatype = "string",
            title = "Server Name",
            description = "SNI hostname"
        },
        tls_allowInsecure = {
            required = false,
            datatype = "boolean",
            title = "Allow Insecure",
            description = "Skip certificate verification"
        },
        transport = {
            required = false,
            datatype = "string",
            title = "Transport",
            description = "Transport protocol"
        },
        uuid = {
            required = false,
            datatype = "string",
            title = "UUID",
            description = "User UUID"
        },
        password = {
            required = false,
            datatype = "string",
            title = "Password",
            description = "Password"
        },
        method = {
            required = false,
            datatype = "string",
            title = "Method",
            description = "Encryption method"
        }
    },
    
    -- DNS configuration schema
    dns = {
        direct_dns_query_strategy = {
            required = false,
            datatype = "string",
            title = "Direct Query Strategy",
            description = "DNS query strategy for direct connections"
        },
        remote_dns_protocol = {
            required = false,
            datatype = "string",
            title = "Remote DNS Protocol",
            description = "Protocol for remote DNS"
        },
        remote_dns = {
            required = false,
            datatype = "string",
            title = "Remote DNS",
            description = "Remote DNS server"
        },
        remote_dns_doh = {
            required = false,
            datatype = "string",
            title = "Remote DNS DoH",
            description = "Remote DNS over HTTPS"
        },
        remote_dns_client_ip = {
            required = false,
            datatype = "string",
            title = "Remote DNS Client IP",
            description = "EDNS client subnet"
        },
        remote_dns_detour = {
            required = false,
            datatype = "string",
            title = "Remote DNS Detour",
            description = "DNS detour outbound"
        },
        remote_dns_query_strategy = {
            required = false,
            datatype = "string",
            title = "Remote Query Strategy",
            description = "DNS query strategy for remote connections"
        },
        remote_fakedns = {
            required = false,
            datatype = "boolean",
            title = "Remote FakeDNS",
            description = "Enable FakeDNS for remote"
        }
    },
    
    -- Shunt rules schema
    shunt_rule = {
        remarks = {
            required = true,
            datatype = "string",
            title = "Remarks",
            description = "Rule description"
        },
        protocol = {
            required = false,
            datatype = "string",
            title = "Protocol",
            description = "Protocol filter"
        },
        inbound = {
            required = false,
            datatype = "string",
            title = "Inbound",
            description = "Inbound filter"
        },
        source = {
            required = false,
            datatype = "string",
            title = "Source",
            description = "Source IP filter"
        },
        sourcePort = {
            required = false,
            datatype = "string",
            title = "Source Port",
            description = "Source port filter"
        },
        port = {
            required = false,
            datatype = "string",
            title = "Port",
            description = "Destination port filter"
        },
        domain_list = {
            required = false,
            datatype = "string",
            title = "Domain List",
            description = "Domain rules"
        },
        ip_list = {
            required = false,
            datatype = "string",
            title = "IP List",
            description = "IP rules"
        },
        invert = {
            required = false,
            datatype = "boolean",
            title = "Invert",
            description = "Invert rule matching"
        }
    },
    
    -- Socks configuration schema
    socks = {
        enabled = {
            required = false,
            datatype = "boolean",
            title = "Enabled",
            description = "Enable Socks proxy"
        },
        node = {
            required = true,
            datatype = "string",
            title = "Node",
            description = "Socks node"
        },
        port = {
            required = true,
            datatype = "port",
            title = "Port",
            description = "Socks port"
        },
        http_port = {
            required = false,
            datatype = "port",
            title = "HTTP Port",
            description = "HTTP proxy port"
        },
        username = {
            required = false,
            datatype = "string",
            title = "Username",
            description = "Authentication username"
        },
        password = {
            required = false,
            datatype = "string",
            title = "Password",
            description = "Authentication password"
        }
    },
    
    -- ACL rule schema
    acl_rule = {
        remarks = {
            required = true,
            datatype = "string",
            title = "Remarks",
            description = "ACL rule description"
        },
        enabled = {
            required = false,
            datatype = "boolean",
            title = "Enabled",
            description = "Enable ACL rule"
        },
        sources = {
            required = false,
            datatype = "string",
            title = "Sources",
            description = "Source addresses"
        },
        node = {
            required = true,
            datatype = "string",
            title = "Node",
            description = "ACL node"
        },
        tcp_no_redir_ports = {
            required = false,
            datatype = "string",
            title = "TCP No Redirect Ports",
            description = "TCP ports to exclude from redirection"
        },
        udp_no_redir_ports = {
            required = false,
            datatype = "string",
            title = "UDP No Redirect Ports",
            description = "UDP ports to exclude from redirection"
        },
        tcp_redir_ports = {
            required = false,
            datatype = "string",
            title = "TCP Redirect Ports",
            description = "TCP ports to redirect"
        },
        udp_redir_ports = {
            required = false,
            datatype = "string",
            title = "UDP Redirect Ports",
            description = "UDP ports to redirect"
        },
        tcp_proxy_tag = {
            required = false,
            datatype = "string",
            title = "TCP Proxy Tag",
            description = "TCP proxy tag"
        },
        udp_proxy_tag = {
            required = false,
            datatype = "string",
            title = "UDP Proxy Tag",
            description = "UDP proxy tag"
        }
    }
}

-- Get schema for a specific component
function get_schema(component)
    return schemas[component] or {}
end

-- Get all available schemas
function get_all_schemas()
    return schemas
end

-- Get required fields for a component
function get_required_fields(component)
    local schema = get_schema(component)
    local required_fields = {}
    
    for field_name, field_config in pairs(schema) do
        if field_config.required then
            table.insert(required_fields, field_name)
        end
    end
    
    return required_fields
end

-- Get field datatype
function get_field_datatype(component, field_name)
    local schema = get_schema(component)
    if schema[field_name] then
        return schema[field_name].datatype
    end
    return nil
end

-- Get field title
function get_field_title(component, field_name)
    local schema = get_schema(component)
    if schema[field_name] then
        return schema[field_name].title
    end
    return field_name
end

-- Get field description
function get_field_description(component, field_name)
    local schema = get_schema(component)
    if schema[field_name] then
        return schema[field_name].description
    end
    return ""
end

-- Validate configuration against schema
function validate_config(component, config)
    local schema = get_schema(component)
    local errors = {}
    
    if not schema or not config then
        return false, { "Invalid schema or configuration" }
    end
    
    -- Check required fields
    for field_name, field_config in pairs(schema) do
        if field_config.required and (config[field_name] == nil or config[field_name] == "") then
            table.insert(errors, string.format("Required field '%s' is missing", field_name))
        end
    end
    
    -- Basic datatype validation
    for field_name, value in pairs(config) do
        local field_config = schema[field_name]
        if field_config then
            local datatype = field_config.datatype
            if datatype then
                -- Basic datatype checks
                if datatype == "boolean" then
                    if value ~= true and value ~= false and value ~= "1" and value ~= "0" then
                        table.insert(errors, string.format("Field '%s' must be boolean", field_name))
                    end
                elseif datatype == "port" then
                    local port = tonumber(value)
                    if not port or port < 1 or port > 65535 then
                        table.insert(errors, string.format("Field '%s' must be a valid port number", field_name))
                    end
                elseif datatype == "string" then
                    if type(value) ~= "string" then
                        table.insert(errors, string.format("Field '%s' must be a string", field_name))
                    end
                end
            end
        end
    end
    
    return #errors == 0, errors
end

-- Merge configuration with defaults
function merge_with_defaults(component, config)
    local schema = get_schema(component)
    local merged = {}
    
    -- Copy defaults first
    for field_name, field_config in pairs(schema) do
        if field_config.default ~= nil then
            merged[field_name] = field_config.default
        end
    end
    
    -- Override with provided config
    for field_name, value in pairs(config or {}) do
        merged[field_name] = value
    end
    
    return merged
end

-- Format configuration for display
function format_config_for_display(component, config)
    local schema = get_schema(component)
    local formatted = {}
    
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

-- Get component fields
function get_component_fields(component)
    local schema = get_schema(component)
    local fields = {}
    
    for field_name, field_config in pairs(schema) do
        table.insert(fields, {
            name = field_name,
            title = field_config.title or field_name,
            description = field_config.description or "",
            datatype = field_config.datatype or "string",
            required = field_config.required or false,
            default = field_config.default
        })
    end
    
    return fields
end

return {
    get_schema = get_schema,
    get_all_schemas = get_all_schemas,
    get_required_fields = get_required_fields,
    get_field_datatype = get_field_datatype,
    get_field_title = get_field_title,
    get_field_description = get_field_description,
    validate_config = validate_config,
    merge_with_defaults = merge_with_defaults,
    format_config_for_display = format_config_for_display,
    get_component_fields = get_component_fields
}