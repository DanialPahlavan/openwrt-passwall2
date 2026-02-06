local api = require "luci.passwall2.api"
local appname = api.appname
local fs = api.fs
local has_singbox = api.finded_com("sing-box")
local has_xray = api.finded_com("xray")

local port_validate = function(self, value, t)
	return value:gsub("-", ":")
end

m = Map(appname)
api.set_apply_on_parse(m)



-- [[ Panel Settings ]]--
s = m:section(TypedSection, "global", translate("Panel Settings"))
s.anonymous = true
s.addremove = false

o = s:option(ListValue, "language", translate("Language"))
o.default = "auto"
o:value("auto", translate("Auto"))
o:value("zh_cn", "简体中文")
o:value("zh_tw", "繁體中文")
o:value("en", "English")
o:value("fa", "فارسی")
o:value("ru", "Pyccĸий")
o:value("ja", "日本語")

o = s:option(Flag, "show_node_info", translate("Show Node Info"), translate("Show detailed node info in node list."))
o.default = 0
o.rmempty = false

-- [[ Forwarding Settings ]]--
s = m:section(TypedSection, "global_forwarding", translate("Forwarding Settings"))
s.anonymous = true
s.addremove = false

---- TCP No Redir Ports
o = s:option(Value, "tcp_no_redir_ports", translate("TCP No Redir Ports"))
o.default = "disable"
o:value("disable", translate("No patterns are used"))
o:value("1:65535", translate("All"))
o.validate = port_validate

---- UDP No Redir Ports
o = s:option(Value, "udp_no_redir_ports", translate("UDP No Redir Ports"),
	"<font color='red'>" ..
	translate("Fill in the ports you don't want to be forwarded by the agent, with the highest priority.") ..
	"</font>")
o.default = "disable"
o:value("disable", translate("No patterns are used"))
o:value("1:65535", translate("All"))
o.validate = port_validate

---- TCP Redir Ports
o = s:option(Value, "tcp_redir_ports", translate("TCP Redir Ports"))
o.default = "22,25,53,80,143,443,465,587,853,873,993,995,5222,8080,8443,9418"
o:value("1:65535", translate("All"))
o:value("22,25,53,80,143,443,465,587,853,873,993,995,5222,8080,8443,9418", translate("Common Use"))
o:value("80,443", translate("Only Web"))
o.validate = port_validate

---- UDP Redir Ports
o = s:option(Value, "udp_redir_ports", translate("UDP Redir Ports"))
o.default = "1:65535"
o:value("1:65535", translate("All"))
o.validate = port_validate

o = s:option(DummyValue, "tips", " ")
o.rawhtml = true
o.cfgvalue = function(t, n)
	return string.format('<font color="red">%s</font>',
	translate("The port settings support single ports and ranges.<br>Separate multiple ports with commas (,).<br>Example: 21,80,443,1000:2000."))
end

---- Use nftables
o = s:option(ListValue, "prefer_nft", translate("Prefer firewall tools"))
o.default = "1"
o:value("0", "Iptables")
o:value("1", "Nftables")

---- Check the transparent proxy component
local handle = io.popen("lsmod")
local mods = ""
if handle then
	mods = handle:read("*a") or ""
	handle:close()
end

if (mods:find("REDIRECT") and mods:find("TPROXY")) or (mods:find("nft_redir") and mods:find("nft_tproxy")) then
	o = s:option(ListValue, "tcp_proxy_way", translate("TCP Proxy Way"))
	o.default = "redirect"
	o:value("redirect", "REDIRECT")
	o:value("tproxy", "TPROXY")
	o:depends("ipv6_tproxy", false)
	o.remove = function(self, section)
		-- Do not delete while hidden
	end

	o = s:option(ListValue, "_tcp_proxy_way", translate("TCP Proxy Way"))
	o.default = "tproxy"
	o:value("tproxy", "TPROXY")
	o:depends("ipv6_tproxy", true)
	o.write = function(self, section, value)
		self.map:set(section, "tcp_proxy_way", value)
	end

	if mods:find("ip6table_mangle") or mods:find("nft_tproxy") then
		---- IPv6 TProxy
		o = s:option(Flag, "ipv6_tproxy", translate("IPv6 TProxy"),
			"<font color='red'>" ..
			translate("Experimental feature. Make sure that your node supports IPv6.") ..
			"</font>")
		o.default = 0
		o.rmempty = false
	end
end

o = s:option(Flag, "accept_icmp", translate("Hijacking ICMP (PING)"))
o.default = 0

o = s:option(Flag, "accept_icmpv6", translate("Hijacking ICMPv6 (IPv6 PING)"))
o:depends("ipv6_tproxy", true)
o.default = 0

if has_xray then
	s_xray = m:section(TypedSection, "global_xray", "Xray " .. translate("Settings"))
	s_xray.anonymous = true
	s_xray.addremove = false

	o = s_xray:option(Flag, "fragment", translate("Fragment"), translate("TCP fragments, which can deceive the censorship system in some cases, such as bypassing SNI blacklists."))
	o.default = 0
	
	o = s_xray:option(ListValue, "fragment_packets", translate("Fragment Packets"), translate(" \"1-3\" is for segmentation at TCP layer, applying to the beginning 1 to 3 data writes by the client. \"tlshello\" is for TLS client hello packet fragmentation."))
	o.default = "tlshello"
	o:value("tlshello", "tlshello")
	o:value("1-1", "1-1")
	o:value("1-2", "1-2")
	o:value("1-3", "1-3")
	o:value("1-5", "1-5")
	o:depends("fragment", true)

	o = s_xray:option(Value, "fragment_length", translate("Fragment Length"), translate("Fragmented packet length (byte)"))
	o.default = "100-200"
	o:depends("fragment", true)

	o = s_xray:option(Value, "fragment_interval", translate("Fragment Interval"), translate("Fragmentation interval (ms)"))
	o.default = "10-20"
	o:depends("fragment", true)

	o = s_xray:option(Value, "fragment_maxSplit", translate("Max Split"), translate("Limit the maximum number of splits."))
	o.default = "100-200"
	o:depends("fragment", true)

	o = s_xray:option(Flag, "noise", translate("Noise"), translate("UDP noise, Under some circumstances it can bypass some UDP based protocol restrictions."))
	o.default = 0

	o = s_xray:option(Flag, "sniffing_override_dest", translate("Override the connection destination address"))
	o.default = 0
	o.description = translate("Override the connection destination address with the sniffed domain.<br />Otherwise use sniffed domain for routing only.<br />If using shunt nodes, configure the domain shunt rules correctly.")

	o = s_xray:option(Flag, "route_only", translate("Sniffing Route Only"))
	o.default = 0
	o:depends("sniffing", true)

	local domains_excluded = string.format("/usr/share/%s/domains_excluded", appname)
	o = s_xray:option(TextValue, "excluded_domains", translate("Excluded Domains"), translate("If the traffic sniffing result is in this list, the destination address will not be overridden."))
	o.rows = 15
	o.wrap = "off"
	o.cfgvalue = function(self, section) return fs.readfile(domains_excluded) or "" end
	o.write = function(self, section, value) fs.writefile(domains_excluded, value:gsub("\r\n", "\n")) end
	o:depends({sniffing_override_dest = true})

	o = s_xray:option(Value, "buffer_size", translate("Buffer Size"), translate("Buffer size for every connection (kB)"))
	o.datatype = "uinteger"

	s_xray_noise = m:section(TypedSection, "xray_noise_packets", translate("Xray Noise Packets"),"<font color='red'>" .. translate("To send noise packets, select \"Noise\" in Xray Settings.") .. "</font>")
	s_xray_noise.template = "cbi/tblsection"
	s_xray_noise.sortable = true
	s_xray_noise.anonymous = true
	s_xray_noise.addremove = true

	s_xray_noise.create = function(e, t)
		TypedSection.create(e, api.gen_short_uuid())
	end

	s_xray_noise.remove = function(self, section)
		for k, v in pairs(self.children) do
			v.rmempty = true
			v.validate = nil
		end
		TypedSection.remove(self, section)
	end

	o = s_xray_noise:option(Flag, "enabled", translate("Enable"))
	o.default = 1
	o.rmempty = false

	o = s_xray_noise:option(ListValue, "type", translate("Type"))
	o:value("rand", "rand")
	o:value("str", "str")
	o:value("hex", "hex")
	o:value("base64", "base64")

	o = s_xray_noise:option(Value, "packet", translate("Packet"))
	o.datatype = "minlength(1)"
	o.rmempty = false

	o = s_xray_noise:option(Value, "delay", translate("Delay (ms)"))
	o.datatype = "or(uinteger,portrange)"
	o.rmempty = false

	o = s_xray_noise:option(ListValue, "applyTo", translate("IP Type"))
	o:value("ip", "ALL")
	o:value("ipv4", "IPv4")
	o:value("ipv6", "IPv6")
end

if has_singbox then
	local version = api.get_app_version("sing-box"):match("[^v]+")
	local version_ge_1_12_0 = api.compare_versions(version, ">=", "1.12.0")

	s = m:section(TypedSection, "global_singbox", "Sing-Box " .. translate("Settings"))
	s.anonymous = true
	s.addremove = false

	o = s:option(Flag, "sniff_override_destination", translate("Override the connection destination address"))
	o.default = 0
	o.rmempty = false
	o.description = translate("Override the connection destination address with the sniffed domain.<br />When enabled, traffic will match only by domain, ignoring IP rules.<br />If using shunt nodes, configure the domain shunt rules correctly.")

	if version_ge_1_12_0 then
		o = s:option(Flag, "record_fragment", "TLS Record " .. translate("Fragment"),
			translate("Split handshake data into multiple TLS records for better censorship evasion. Low overhead. Recommended to enable first."))
		o.default = 0

		o = s:option(Flag, "fragment", "TLS TCP " .. translate("Fragment"),
			translate("Split handshake into multiple TCP segments. Enhances obfuscation. May increase delay. Use only if needed."))
		o.default = 0
	end
end

return m
