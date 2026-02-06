# OpenWrt PassWall 2 🚀

**PassWall 2** is a next-generation proxy client for OpenWrt, designed for performance, stability, and ease of use. It supports modern protocols like **Xray (VLESS, VMess)**, **Sing-box**, **Hysteria2**, and **Trojan**, providing a powerful yet user-friendly interface for managing your network connection.

![License](https://img.shields.io/github/license/xiaorouji/openwrt-passwall)
![Generic badge](https://img.shields.io/badge/OpenWrt-21.02%2B-blue.svg)

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

## 📦 Installation

1.  **Download**: Get the latest `.ipk` release from the [Releases](https://github.com/DanialPahlavan/openwrt-passwall2/releases) page.
2.  **Upload**: Upload the file to your router (e.g., `/tmp/`).
3.  **Install**:
    ```bash
    opkg update
    opkg install /tmp/luci-app-passwall2*.ipk
    ```
4.  **Dependencies**: Ensure you have the core components installed (usually handled automatically):
    *   `xray-core` or `sing-box`
    *   `iptables-mod-tproxy` or `nftables`

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
