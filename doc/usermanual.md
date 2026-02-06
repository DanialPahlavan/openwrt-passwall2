# User Manual

## Basic Configuration

1.  **Add Node**: Go to **Nodes -> Node List** and click **Add Node**.
    *   Enter your VLESS/VMess/Hysteria2 details.
    *   You can also import links starting with `vless://`, `vmess://`, etc.
2.  **Enable Service**:
    *   Go to **Basic Settings**.
    *   Check **Main Switch**.
    *   Select your node in **TCP Node** (and UDP Node).
    *   Click **Save & Apply**.

## Advanced Features

### Load Balancing
Go to **Tools -> Load Balancing** (HAProxy) to combine multiple nodes for faster speeds or redundancy.

### Access Control
Go to **Tools -> Access Control** to specific which LAN devices use the proxy and which go direct.

### Maintenance
Go to **Maintenance** to:
*   Update GeoIP/Geosite databases.
*   Backup your configuration.
*   Check connection diagnostics.
