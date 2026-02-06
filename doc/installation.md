# Installation Guide

## Requirements

*   **OpenWrt Version**: 21.02 or later (Snapshot recommended).
*   **Architecture**: Supports x86_64, aarch64_cortex-a53, aarch64_generic, arm_cortex-a9, etc.
*   **Space**: At least 10MB free space (Flash/Overlay).

## Step-by-Step

### 1. Download Package
Download `luci-app-passwall2_*.ipk` from the releases page.

### 2. Upload to Router
Use `scp` or WinSCP to upload the file to `/tmp/`.

### 3. Install
Run the following commands via SSH:

```bash
opkg update
opkg install /tmp/luci-app-passwall2_*.ipk
```
### 4. Verify
Log in to LuCI. You should see **PassWall 2** in the **Services** menu.
