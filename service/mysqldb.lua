local skynet = require "skynet"
local mysql = require "mysql"
local utils = require "utils"

local CMD = {}
local db

local function connect(dbname,t)

end
--验证是否登陆
function CMD.checkLogin(user_info)
	local sql_fmt = "SELECT users_info.coin,users_info.nickname,users_info.sex FROM users_info INNER JOIN users ON users_info.userid = users.userid WHERE (users.userid=%d) AND (users.loginkey=%d);"
	local select_sql = string.format(sql_fmt,user_info.uid,user_info.key)
	local res = db:query(select_sql)
	return res
end

function CMD.updateUserInfo()

end

function CMD.start()

end

function CMD.stop()

end

local function keep_alive()
	while true do
		skynet.error("mysqldb:  timer keep alive!")
		skynet.sleep(2*60*100)
		if db then
			db:query("set charset utf8")
		end
	end
end

skynet.start(function()
	local function on_connect(db)
		db:query("set charset utf8");
	end

	db = mysql.connect({
		host="127.0.0.1",
	--	host="192.168.1.98",
		port=3306,
		database="ddz",
		user="root",
		password="123456",
		--password="ztf123456789ha",
		max_packet_size = 1024*1024,
		on_connect = on_connect
	})
	if not db then
		skynet.error("failed to connect db!")
		skynet.exit()
		return
	end

	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = assert(CMD[cmd])
		skynet.ret(skynet.pack(f(...)))
	end)
	skynet.error("mysqldb service start!")	
	skynet.fork(keep_alive)
end)
