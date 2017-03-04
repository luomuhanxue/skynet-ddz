local skynet = require "skynet"


local CMD = {}
local SOCKET = {}
local gate
local agent = {}

local function close_agent(fd)
	local a = agent[fd]
	if a then
		skynet.call(gate,"lua","kick",fd)
		skynet.send(a,"lua","disconnect")
		agent[fd] = nil
	end
end

function SOCKET.open(fd,addr)
	skynet.error("new-->",fd,addr)
	agent[fd] = skynet.newservice("agent")
	skynet.call(agent[fd],"lua","start",{gate=gate,client=fd,watchdog=skynet.self()})
end

function SOCKET.close(fd)
	skynet.error("close-->",fd,addr)
	close_agent(fd)
end

function SOCKET.error(fd,msg)
	skynet.error("socket error!",fd,msg)
	close_agent(fd)
end

function SOCKET.data(fd,msg)
	--skynet.error(fd,msg)
end

function CMD.start(conf)
	skynet.error("gate open")
	skynet.call(gate,"lua","open",conf)
end

function CMD.close(fd)
	close_agent(fd)
end

skynet.start(function()
	skynet.dispatch("lua",function(session,source,cmd,subcmd,...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd,...)))
		end
	end)
	gate = skynet.newservice("gate")
end)
