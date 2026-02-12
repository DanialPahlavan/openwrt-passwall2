# OpenWrt PassWall 2 🚀

**PassWall 2** is a next-generation proxy client for OpenWrt, designed for performance, stability, and ease of use. It supports modern protocols like **Xray (VLESS, VMess)**, **Sing-box**, **Hysteria2**, and **Trojan**, providing a powerful yet user-friendly interface for managing your network connection.


## ⚠️ Warning

**This is Sandbox/playground branch , dont use it . its all things for testing and brainstorming .


## ✨ Key Features

*   **Modern UI**: A clean, reorganized interface with logical tabs (Nodes, Tools, Maintenance).
*   **Protocol Support**: Full support for Xray, Sing-box, Hysteria2, TUIC, and more.
*   **Smart Routing**:
    *   **GeoIP/Geosite**: Accurate routing based on geographic location and domain lists.
    *   **Load Balancing**: Distribute traffic across multiple nodes (HAProxy).
    *   **Failover**: Automatically switch to a backup node if the primary fails.
*   **Maintenance Tools**:
    *   **Update Center**: Update App, GeoIP, and Geosite databases in one click.
    *   **Scheduled Tasks**: Automate updates and service restarts.
    *   **Backup & Restore**: Easily migrate your configuration.
*   **Multi-Language**: Built-in support for **English**, **Chinese (Simplified/Traditional)**, and **Persian (Farsi)**.

## ⚙️ Requirements

### Minimum System Requirements

| Component | Requirement |
|-----------|-------------|
| **OpenWrt Version** | 24.x or later (Recommended: 24.10+) |
| **Lua Runtime** | LuaJIT (Lua 5.1 compatible) |
| **Architecture** | ARM, MIPS, x86_64, ARM64 |
| **Free Storage** | ~5MB for base package + dependencies |
| **RAM** | 128MB+ (256MB+ recommended) |

### Core Dependencies

PassWall 2 requires the following packages (automatically installed via `opkg`):

**LuCI Framework:**
- `luci-base` (>= 24.x)
- `luci-compat` (for legacy support)
- `luci-lib-jsonc`
- `nixio`

**Proxy Cores** (at least one required):
- `xray-core` **OR** `sing-box` (recommended)
- Optional: `hysteria`, `tuic-client`

**Networking:**
- `iptables-mod-tproxy` **OR** `nftables`
- `ipset`
- `dnsmasq-full` **OR** `dnsmasq` + `dnsmasq-extra`

**Utilities:**
- `wget-ssl` or `curl`
- `ca-bundle` (for HTTPS subscriptions)
- `unzip` (for GeoIP/GeoSite updates)

### Optional Components

- `haproxy` - For load balancing
- `luci-app-firewall` - For advanced firewall rules
- `chinadns-ng` - For DNS pollution mitigation

---

## 📦 Installation

### Method 1: From Pre-built Release (Recommended)

1. **Download**: Get the latest `.ipk` release from the [Releases](https://github.com/DanialPahlavan/openwrt-passwall2/releases) page.
2. **Upload**: Upload the file to your router (e.g., `/tmp/`).
3. **Install**:
   ```bash
   opkg update
   opkg install /tmp/luci-app-passwall2*.ipk
   ```

### Method 2: Build from Source

See the [Build Guide](doc/build.md) for detailed instructions on compiling from source.

### Post-Installation

After installation, the web interface will be available at:
**LuCI > Services > PassWall 2**

## 🚀 Quick Start

1.  **Add a Node**: Go to **Nodes -> Node List** and add your server configuration (link or manual).
2.  **Subscribe**: Or go to **Nodes -> Node Subscribe** to add a subscription URL.
3.  **Basic Settings**: Go to **Basic Settings**, select your **Main Node**, and toggle the switch to **Enable**.
4.  **Verify**: Check connection status in **Maintenance -> Diagnostics**.

## 📖 Documentation

Full documentation is available in the [`doc`](doc/) folder or online at our [GitHub Pages site](https://danialpahlavan.github.io/openwrt-passwall2/).

*   [Installation Guide](doc/installation.md)
*   [User Manual](doc/usermanual.md)
*   [FAQ](doc/faq.md)

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details on how to submit pull requests and report issues.

## 📄 License

This project is licensed under the [Apache-2.0 License](LICENSE).
