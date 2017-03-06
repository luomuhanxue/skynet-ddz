local skynet = require"skynet"
local game = require"poke"
local game_handle = require"poke_handle"

local CMD = {}
local is_start		--游戏是否开始
local game_logic	--游戏逻辑
local game_cb		--游戏逻辑适配层
local agents = {}	--连入的客户端
local prepares={}	--玩家准备
local max = 3		--最大人数
local room_id		--房间id号（从1开始）
local count = 0		--房间进入的玩家数量

--玩家进入房间
function CMD.enter(agent)
	skynet.error("enter room:",agent)
	if count < max then
		local new_user = skynet.call(agent,"lua","info")
		local p = {}
		for k,v in pairs(agents) do
			local temp_user = skynet.call(v,"lua","info")
			temp_user.status = prepares[k]
			p[#p+1] = temp_user
		end
		count = count + 1
		local pos = 1
		for i = 1,max do
			if not agents[i] then
				pos = i
				break
			end
		end
		new_user.pid=pos
		new_user.rid=room_id
		new_user.rf="enter"
		for k,v in pairs(agents) do
			skynet.call(v,"lua","update_room",new_user)
		end
		agents[pos] = agent
		return {rid=room_id,pid=pos,others=p}
	else
		return false
	end
end

local function post_msg_all(msg,kind)
	for k,v in pairs(agents) do
		skynet.call(v,"lua",kind,msg)	
	end
end

local function send_msg(pidx,kind,msg)
	if agents[pidx] then
		skynet.call(agents[pidx],"lua",kind,msg)
	end
end

--房间服务启动
function CMD.start(roomid)
	skynet.error("room start",roomid)
	room_id = roomid
	count = 0
	prepare_count = 0
	is_start = false
	game_logic = game.new()
	game_logic:init()
	game_cb = game_handle.new(post_msg_all,send_msg)
	game_logic:addGameEvent(game_cb)
end

--聊天
function CMD.talk(agent,msg)
	for k,v in pairs(agents) do
		if agent ~= v then
			skynet.call(v,"lua","talk_room",msg)
		end
	end
	return true
end

--玩家退出房间
function CMD.exit(agent,room_pos)
	skynet.error("room exit",agent)
	count = count - 1
	agents[room_pos] = nil
	prepares[room_pos] = false
	local user_info = skynet.call(agent,"lua","info")
	user_info.rf="exit"
	for k,v in pairs(agents) do
		skynet.call(v,"lua","update_room",user_info)
	end
end

--准备
function CMD.prepare(pos,p)
--	if is_start then return false end	--游戏开始
	local pcount = 0
	for k,v in pairs(agents) do
		if k == pos then
			prepares[pos] = p
		else
			skynet.call(v,"lua","prepare_room",pos,p)
		end
		if prepares[k] then pcount = pcount + 1 end
	end
	if pcount == 3 then
		is_start = true
		game_logic:start()
	end
	return true
end

skynet.start(function()
	skynet.dispatch("lua",function(session,source,cmd,...)
		local f = assert(CMD[cmd])
		skynet.ret(skynet.pack(f(...)))
	end)
end)
