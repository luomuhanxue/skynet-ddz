local skynet = require "skynet"
local Player = require"player"
local json = require "cjson"
local GameServer = require "poke"
--local GameHandler = require"poke_handler"

local users = {}
local uid_pos = {}
local room_id

local game

local function talk(c,data)
	local pos = uid_pos[data.uid]
	if not pos then return end
	local isok = users[pos]:talk(data)
	if isok then
		for i = 1,3 do
			if i ~= pos and users[i] then
				users[i]:otherTalk(pos,data)
			end
		end
	else
		users[pos]:error(c,-1)
	end
end
--{"c":4,"d":{"prepare":true,"uid":2,"show":true}}
local function prepare(c,data)
	if game then return end
	local pos = uid_pos[data.uid]
	if not pos then return end
	local isok = users[pos]:myprepare(data)
	local prepare_count =  users[pos].prepare and 1 or 0
	if isok then
		for i = 1,3 do
			if i ~= pos and users[i] then
				users[i]:otherPrepare(pos,data)
				if users[i].prepare then
					prepare_count = prepare_count + 1
				end
			end
		end
		skynet.error("prepare count:",prepare_count)
		if prepare_count == 3 then 	--三个人都准备好了 开始游戏
			game = GameServer.new(users)
			game:start()
		end
	else
		users[pos]:error(c,-1)
	end
end

local handle = {}
handle[3] = talk
handle[4] = prepare
skynet.register_protocol{
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = skynet.tostring,
	dispatch = function(_,_,msg,...)
		local isok,t =  pcall(json.decode,msg)
		if not isok then
			skynet.error("ROOM ERROR:",msg)
			return
		end
		skynet.error(t.c)
		if t.c < 50 then		--房间基本功能
			local f = handle[t.c]
			if f then
				f(t.c,t.d)
			end
		else 					--游戏逻辑
			if game and t.d then
				local pos = uid_pos[t.d.uid]
				skynet.error(pos)
				if pos then
					game:handleEvent(t.c,pos,t.d)
				end
			end
		end
	end
}

local CMD = {}
function CMD.enter(user_info,con_info)
	local pos = false
	for i = 1,3 do
		if not users[i] then
			pos = i
			break
		end
	end
	local player
	if pos then
		player = Player.new(pos,user_info,con_info)
		local ret = {}
		for i = 1,3 do
			if users[i] then
				ret[#ret + 1] = users[i]:getInfo()
				users[i]:otherEnter(player:getInfo())
			end
		end
		uid_pos[con_info.uid] = pos
		users[pos] = player
		skynet.call(con_info.gate,"lua","forward",con_info.fd)
		player:enter(room_id, ret)
	end
	return pos
end

function CMD.start(roomid)
	room_id = roomid
end

function CMD.exit(room_pos)
	local uid = users[room_pos].uid
	users[room_pos] = nil
	uid_pos[uid] = nil
	local player_count = 0
	for i = 1,3 do
		if users[i] then
			users[i]:otherExit(room_pos)
			player_count = player_count + 1
		end
	end
	if player_count == 0 and game then
		game:exit()
		game = nil
	end
end

skynet.start(function()
	skynet.dispatch("lua",function(session,source,cmd,...)
		local f = assert(CMD[cmd])
		skynet.ret(skynet.pack(f(...)))
	end)
end)
