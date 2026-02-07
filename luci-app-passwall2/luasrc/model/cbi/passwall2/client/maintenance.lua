module("luci.model.cbi.passwall2.client.maintenance", package.seeall)

local api = require "luci.passwall2.api"
local appname = api.appname
local fs = api.fs

function index()
	entry({"admin", "services", appname, "maintenance"}, alias("admin", "services", appname, "maintenance", "log"), _("Maintenance"), 100).dependent = true
	entry({"admin", "services", appname, "maintenance", "log"}, form(appname .. "/client/maintenance/log"), _("Watch Logs"), 1).leaf = true
	entry({"admin", "services", appname, "maintenance", "update"}, cbi(appname .. "/client/maintenance/app_update"), _("Update Center"), 2).leaf = true
	entry({"admin", "services", appname, "maintenance", "diagnostics"}, cbi(appname .. "/client/maintenance/diagnostics"), _("Diagnostics"), 3).leaf = true
	entry({"admin", "services", appname, "maintenance", "backup"}, cbi(appname .. "/client/maintenance/backup"), _("Backup & Restore"), 4).leaf = true
	entry({"admin", "services", appname, "maintenance", "cache"}, cbi(appname .. "/client/maintenance/cache"), _("System Maintenance"), 5).leaf = true
	entry({"admin", "services", appname, "maintenance", "scheduled_tasks"}, cbi(appname .. "/client/maintenance/scheduled_tasks"), _("Scheduled Tasks"), 6).leaf = true
	entry({"admin", "services", appname, "maintenance", "faq"}, form(appname .. "/client/maintenance/faq"), _("FAQ"), 7).leaf = true
end