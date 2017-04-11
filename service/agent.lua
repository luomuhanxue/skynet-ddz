local skynet = require "skynet"
local json = require "cjson"
local websocket = require"websocket"

local WATCHDOG
local CMD = {}
local client_fd
local user_info 
local handle={}
local gate
local room_idx
local room_pos
local uid

local function send_msg(fd,msg)
	websocket:send_text(fd,msg)
end

--进入房间
local function enter_room(data)
	local room_id  
	if type(data) == "table" then
		room_id = data.rid
	end
	local con_info ={
		fd = client_fd,
		watchdog = WATCHDOG,
		gate = gate,
		uid=uid
	}
	local room_mgr_addr = skynet.uniqueservice"room_mgr"
	skynet.error("agent enter_room",room_mgr_addr,"room_id:",room_id)
	local ret,idx,pos = skynet.call(room_mgr_addr,"lua","enter",user_info,con_info,room_id)
	--skynet.error("----",json.encode(ret))
	room_idx = idx
	room_pos = pos
	if not ret then
		room_idx = nil
		room_pos = nil
		send_msg(client_fd,json.encode({c=2,f=-1}))
	end
end

local function exit_room()
	if room_idx then
		local room_mgr_addr = skynet.uniqueservice"room_mgr"
		local ret = skynet.call(room_mgr_addr,"lua","exit",room_idx,room_pos)
		room_idx = nil
		room_pos = nil
	end
end

handle[2] = enter_room

skynet.register_protocol{
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.tostring,
	dispatch = function(_,_,msg,...)
		skynet.error("agent:",msg)
		local isok,t =  pcall(json.decode,msg)
		if not isok then
			send_msg(client_fd,'{"c":1,"f":-1}')	
			return
		end
		skynet.error(t.c)
		if handle[t.c] then
			handle[t.c](t.d)
		else
			send_msg(client_fd,json.encode({c=t.c,f=-1}))
		end
	end
}

function CMD.start(conf)
	local fd = conf.client
	gate = conf.gate
	WATCHDOG = conf.watchdog
	user_info = conf.info
	uid = conf.uid
	client_fd = fd
	skynet.call(gate,"lua","forward",fd)
	send_msg(client_fd,'{"c":1,"f":1}')
end

function CMD.disconnect()
	exit_room()	
	skynet.error("agent exit!")
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua",function(_,_,cmd,...)
		local f = CMD[cmd]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
