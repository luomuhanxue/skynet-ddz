local skynet = require "skynet"
local websocket = require"websocket"
local json = require "cjson"
local CMD = {}
local SOCKET = {}
local gate
local agent = {}
local fd_uid = {}
local uid_agent = {}
local uid_fd = {}
skynet.register_protocol{
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.tostring
}

local function send_msg(fd,msg)
	websocket:send_text(fd,msg)
end

function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)
	skynet.call(gate,"lua","accept",fd)
end

local function close_agent(fd)
	local uid = fd_uid[fd]
	if uid then
		fd_uid[fd]=nil
		local a = uid_agent[uid]
		uid_agent[uid]=nil
		uid_fd[uid] = nil
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect")
	end
end

function SOCKET.close(fd)
	skynet.error("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	skynet.error("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	skynet.error("socket warning", fd, size)
end

--玩家连接上来 消息没有转发给client处理 这里有watchdog处理验证
function SOCKET.data(fd, msg)
	skynet.error("watchdog:",msg)
	local isok,t =  pcall(json.decode,msg)
	if not isok then
		send_msg(fd,'{"c":1,"f":-1}')	
		return
	end
	--local t = json.decode(msg)
	if t.c == 1 then --登陆验证
		local mysqldb_addr = skynet.uniqueservice"mysqldb"
		if t.d.key and t.d.uid then
			local ret = skynet.call(mysqldb_addr,"lua","checkLogin",t.d)
	--		local ret = {[1]={nickname="xxx",sex=1,coin=100}}
			if ret and #ret==1 then
				local uid=t.d.uid
				--ret[1].uid = uid
				local agent = uid_agent[uid]
				local last_fd = uid_fd[uid]
				if agent then
					close_agent(last_fd)
				end
				agent = skynet.newservice("agent")
				fd_uid[fd] = uid
				uid_fd[uid] = fd
				uid_agent[uid] = agent
				skynet.call(agent, "lua", "start", { gate = gate, client = fd, watchdog = skynet.self(),info=ret[1],uid=uid})
			else
				send_msg(fd,'{"c":1,"f":-1}')	
			end
		else
			send_msg(fd,'{"c":1,"f":-1}')	
		end
	end
end

function CMD.start(conf)
	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		skynet.error("watchdog -- > lua:",cmd,subcmd)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)
	gate = skynet.newservice("wsgate")
end)
