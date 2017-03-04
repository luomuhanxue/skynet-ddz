local skynet = require "skynet"
local queue = require "skynet.queue"

local CMD = {}
local cs = queue()
local rooms = {}
local rooms_count = {}
local room_number = 5
local function create_room()
	for i = 1,room_number+1 do
		rooms[i] = skynet.newservice"room"
		skynet.call(rooms[i],"lua","start",i)
		rooms_count[i] = 0
	end
end

function enter_room(agent,isDebug)
	local ret = false
	local room_addr = false
	
	if isDebug then
		ret = skynet.call(rooms[room_number+1],"lua","enter",agent)
		room_addr = rooms[room_number+1]
		return ret,room_addr
	end

	for i = 1,room_number do
		if rooms_count[i] < 3 then
			ret = skynet.call(rooms[i],"lua","enter",agent)
			if ret then
				room_addr = rooms[i]
				break	
			end
		end
	end
	return ret,room_addr
end

function CMD.enter_room(agent,isDebug)
	return cs(enter_room,agent,isDebug)
end

function exit_room(room_id,room_pos,agent)
	skynet.call(rooms[room_id],"lua","exit",agent,room_pos)
	rooms_count[room_id] = rooms_count[room_id] - 1
end

function CMD.exit_room(room_id,room_pos,agent)
	cs(exit_room,room_id,room_pos,agent)
end

function CMD.talk_room(agent,info)
	local ret = skynet.call(rooms[info.rid],"lua","talk",agent,info)
	return ret
end

skynet.start(function ()
	create_room()
	skynet.dispatch("lua",function(_,address,cmd,...)
		local f = CMD[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		end
	end)
end)
