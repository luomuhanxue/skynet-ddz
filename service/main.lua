local skynet = require "skynet"
local driver = require "socketdriver"

skynet.start(function()
	skynet.error("Server start")
	skynet.newservice("debug_console","127.0.0.1",8000)
--	skynet.uniqueservice"mysqldb"
	skynet.uniqueservice"room_mgr"
	local watchdog = skynet.newservice("wswatchdog")
	skynet.call(watchdog,"lua","start",{
		port = 8899,
		maxclient=64,
		nodelay = true
	})
	skynet.error("Watchdog listen on",8899)
	skynet.exit()
end)
