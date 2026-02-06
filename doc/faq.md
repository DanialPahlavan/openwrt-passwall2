# Frequently Asked Questions (FAQ)

### Q: Why is "Google" accessible but other sites are not?
**A**: Check your DNS settings. PassWall 2 uses specialized DNS forwarding. Ensure you haven't manually overridden DNS on your client device.

### Q: How do I perform a clean reinstall?
**A**:
1.  Uninstall: `opkg remove luci-app-passwall2`
2.  Delete config: `rm -rf /etc/config/passwall2`
3.  Reinstall.

### Q: Where are the logs?
**A**: Go to **Maintenance -> Watch Logs**. Select "App Log" for general errors or "Xray Log" for core issues.
