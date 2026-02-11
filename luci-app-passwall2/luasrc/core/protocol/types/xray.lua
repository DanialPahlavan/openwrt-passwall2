module("luci.passwall2.core.protocol.types.xray", package.seeall)

local base = require "luci.passwall2.core.protocol.base"

-- Xray protocol implementation
local xray = base:new({
    name = "Xray",
    type = "Xray",
    protocols = {
        "vmess", "vless", "shadowsocks", "shadowsocksr",
        "trojan", "socks", "http", "wireguard",
        "hysteria", "hysteria2", "tuic", "anytls", "ssh"
    },
    config_schema = {
        -- Common fields
        address = {
            required = true,
            datatype = "host",
            title = "Server Address",
            description = "The server address or hostname"
        },
        port = {
            required = true,
            datatype = "port", 
            title = "Server Port",
            description = "The server port number"
        },
        remarks = {
            required = true,
            datatype = "string",
            title = "Remarks",
            description = "Description for this node"
        },
        
        -- TLS settings
        tls = {
            required = false,
            datatype = "boolean",
            title = "Enable TLS",
            description = "Enable TLS encryption"
        },
        tls_serverName = {
            required = false,
            datatype = "string",
            title = "Server Name",
            description = "SNI hostname for TLS"
        },
        tls_allowInsecure = {
            required = false,
            datatype = "boolean",
            title = "Allow Insecure",
            description = "Skip certificate verification"
        },
        alpn = {
            required = false,
            datatype = "string",
            title = "ALPN",
            description = "Application-Layer Protocol Negotiation"
        },
        
        -- Transport settings
        transport = {
            required = false,
            datatype = "string",
            title = "Transport",
            description = "Transport protocol (tcp, ws, grpc, etc.)"
        },
        ws_path = {
            required = false,
            datatype = "string",
            title = "WebSocket Path",
            description = "WebSocket path"
        },
        ws_host = {
            required = false,
            datatype = "string",
            title = "WebSocket Host",
            description = "WebSocket host header"
        },
        
        -- Protocol specific fields
        uuid = {
            required = false,
            datatype = "string",
            title = "UUID",
            description = "User UUID for VMess/VLESS"
        },
        password = {
            required = false,
            datatype = "string",
            title = "Password",
            description = "Password for various protocols"
        },
        method = {
            required = false,
            datatype = "string",
            title = "Method",
            description = "Encryption method for Shadowsocks"
        },
        
        -- Advanced settings
        domain_strategy = {
            required = false,
            datatype = "string",
            title = "Domain Strategy",
            description = "Domain resolution strategy"
        }
    },
    default_config = {
        tls = false,
        tls_allowInsecure = false,
        transport = "tcp",
        domain_strategy = "prefer_ipv4"
    }
})

-- Validate Xray configuration
function xray:validate_config(config)
    local errors = {}
    
    -- Validate protocol-specific requirements
    if config.protocol == "vmess" then
        if not config.uuid then
            table.insert(errors, "UUID is required for VMess protocol")
        end
    elseif config.protocol == "vless" then
        if not config.uuid then
            table.insert(errors, "UUID is required for VLESS protocol")
        end
    elseif config.protocol == "shadowsocks" then
        if not config.method then
            table.insert(errors, "Method is required for Shadowsocks protocol")
        end
        if not config.password then
            table.insert(errors, "Password is required for Shadowsocks protocol")
        end
    elseif config.protocol == "trojan" then
        if not config.password then
            table.insert(errors, "Password is required for Trojan protocol")
        end
    elseif config.protocol == "socks" then
        if not config.username or not config.password then
            table.insert(errors, "Username and password are required for Socks protocol")
        end
    elseif config.protocol == "http" then
        if not config.username or not config.password then
            table.insert(errors, "Username and password are required for HTTP protocol")
        end
    end
    
    -- Validate transport settings
    if config.transport == "ws" then
        if not config.ws_path then
            table.insert(errors, "WebSocket path is required when using WebSocket transport")
        end
    end
    
    -- Validate TLS settings
    if config.tls then
        if not config.tls_serverName then
            table.insert(errors, "Server name is required when TLS is enabled")
        end
    end
    
    return #errors == 0, errors
end

-- Generate Xray configuration
function xray:generate_config(config)
    local protocol = config.protocol or "vmess"
    local generated_config = {
        type = "xray",
        protocol = protocol,
        server = config.address,
        server_port = tonumber(config.port),
        tag = config.remarks or "xray-node"
    }
    
    -- Add TLS configuration
    if config.tls then
        generated_config.tls = {
            enabled = true,
            server_name = config.tls_serverName,
            insecure = config.tls_allowInsecure,
            alpn = config.alpn and { config.alpn } or nil
        }
    end
    
    -- Add transport configuration
    if config.transport then
        if config.transport == "ws" then
            generated_config.transport = {
                type = "ws",
                path = config.ws_path or "/",
                headers = config.ws_host and { Host = config.ws_host } or nil
            }
        elseif config.transport == "grpc" then
            generated_config.transport = {
                type = "grpc",
                service_name = config.grpc_serviceName or ""
            }
        elseif config.transport == "http" then
            generated_config.transport = {
                type = "http",
                host = config.http_host or {},
                path = config.http_path or "/"
            }
        end
    end
    
    -- Add protocol-specific configuration
    if protocol == "vmess" then
        generated_config.uuid = config.uuid
        generated_config.security = config.security or "auto"
        generated_config.alter_id = tonumber(config.alter_id) or 0
    elseif protocol == "vless" then
        generated_config.uuid = config.uuid
        generated_config.flow = config.flow
    elseif protocol == "shadowsocks" then
        generated_config.method = config.method
        generated_config.password = config.password
        generated_config.plugin = config.plugin
        generated_config.plugin_opts = config.plugin_opts
    elseif protocol == "trojan" then
        generated_config.password = config.password
    elseif protocol == "socks" then
        generated_config.username = config.username
        generated_config.password = config.password
    elseif protocol == "http" then
        generated_config.username = config.username
        generated_config.password = config.password
    elseif protocol == "wireguard" then
        generated_config.private_key = config.wireguard_secret_key
        generated_config.peer_public_key = config.wireguard_public_key
        generated_config.pre_shared_key = config.wireguard_preSharedKey
        generated_config.local_address = config.wireguard_local_address
    end
    
    return generated_config
end

-- Test Xray connection
function xray:test_connection(config)
    -- This would implement actual connection testing
    -- For now, return a basic validation result
    local valid, errors = self:validate_config(config)
    if not valid then
        return false, { errors = errors }
    end
    
    -- Basic connectivity test (ping the server)
    local api = require "luci.passwall2.api"
    local result = api.ping_node(config.address, config.port, "tcping")
    
    if result and result.ping then
        return true, { 
            status = "success", 
            latency = result.ping,
            message = "Connection test successful"
        }
    else
        return false, { 
            status = "failed", 
            message = "Connection test failed" 
        }
    end
end

-- Get Xray specific configuration options for UI
function xray:get_ui_options()
    return {
        protocol_options = {
            vmess = {
                uuid = { required = true, datatype = "string", title = "UUID" },
                security = { required = false, datatype = "string", title = "Security" },
                alter_id = { required = false, datatype = "uinteger", title = "Alter ID" }
            },
            vless = {
                uuid = { required = true, datatype = "string", title = "UUID" },
                flow = { required = false, datatype = "string", title = "Flow" }
            },
            shadowsocks = {
                method = { required = true, datatype = "string", title = "Method" },
                password = { required = true, datatype = "string", title = "Password" },
                plugin = { required = false, datatype = "string", title = "Plugin" },
                plugin_opts = { required = false, datatype = "string", title = "Plugin Options" }
            },
            socks = {
                username = { required = true, datatype = "string", title = "Username" },
                password = { required = true, datatype = "string", title = "Password" }
            },
            http = {
                username = { required = true, datatype = "string", title = "Username" },
                password = { required = true, datatype = "string", title = "Password" }
            }
        }
    }
end

-- Get protocol display information
function xray:get_protocol_display_info(protocol)
    local display_info = {
        vmess = { title = "VMess", description = "VMess protocol for Xray" },
        vless = { title = "VLESS", description = "VLESS protocol for Xray" },
        shadowsocks = { title = "Shadowsocks", description = "Shadowsocks protocol" },
        shadowsocksr = { title = "ShadowsocksR", description = "ShadowsocksR protocol" },
        trojan = { title = "Trojan", description = "Trojan protocol" },
        socks = { title = "Socks", description = "Socks protocol" },
        http = { title = "HTTP", description = "HTTP protocol" },
        wireguard = { title = "WireGuard", description = "WireGuard protocol" },
        hysteria = { title = "Hysteria", description = "Hysteria protocol" },
        hysteria2 = { title = "Hysteria2", description = "Hysteria2 protocol" },
        tuic = { title = "TUIC", description = "TUIC protocol" },
        anytls = { title = "AnyTLS", description = "AnyTLS protocol" },
        ssh = { title = "SSH", description = "SSH protocol" }
    }
    
    return display_info[protocol] or { title = protocol, description = "Unknown protocol" }
end

-- Get Xray specific transport options
function xray:get_transport_options()
    return {
        tcp = { title = "TCP", description = "TCP transport" },
        ws = { title = "WebSocket", description = "WebSocket transport" },
        grpc = { title = "gRPC", description = "gRPC transport" },
        http = { title = "HTTP", description = "HTTP transport" },
        quic = { title = "QUIC", description = "QUIC transport" }
    }
end

-- Get Xray specific TLS options
function xray:get_tls_options()
    return {
        tls = { title = "TLS", description = "TLS encryption" },
        reality = { title = "Reality", description = "Reality protocol" }
    }
end

return xray