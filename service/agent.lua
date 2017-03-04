local skynet = require "skynet"

local CMD = {}
local cards={}

local room				--所在房间号
local room_pos			--所在房间的座位号
local name				--人物名字
local sex				--人物性别
local score				--人物的分数
local ws_service_addr	--websocket服务的地址
local room_manager_addr	--房间管理服务的地址
local room_addr			--房间服务的地址
local prepare_status	--准备的状态

function getUserInfo()
	return {name=name,sex=sex,uid=skynet.self(),rid=room,pid=room_pos}
end

function CMD.start(conf,addr)
	name = conf.d.name
	sex = conf.d.sex
	ws_service_addr = addr
	room_manager_addr = skynet.queryservice(true,"room_manager")
--	skynet.fork(function()
--		while true do
--			skynet.call(ws_service_addr,"lua","send",{c=0},skynet.self())
--			skynet.sleep(500)
--		end
--	end)
	if name and #name>0 and sex then
		return {c=1,flag=1,d=getUserInfo()}
	else
		return {c=1,flag=0}
	end
end

function CMD.info()
	return getUserInfo()
end

function CMD.dispatch(msg)
	if msg.c == 2 then
		--join room
		local debug_room = name:find("ztf")
		local ret,raddr= skynet.call(room_manager_addr,"lua","enter_room",skynet.self(),debug_room)
		if ret then
			room_addr = raddr
			room = ret.rid
			room_pos = ret.pid
			return {c=2,flag=1,d=ret}
		else
			room_addr = nil
			return {c=2,flag=0}
		end
	elseif msg.c == 3 then
		local t=getUserInfo()
		t.msg = msg.d.msg
		local ret = skynet.call(room_manager_addr,"lua","talk_room",skynet.self(),t)
		if ret then
			return {c=3,flag=1,d=t.msg}
		else
			return {c=3,flag=0}
		end
	elseif msg.c == 4 then
		if type(msg.d)~="boolean" and msg.d == prepare_status then
			return {c=4,flag=0}
		end
		local ret = skynet.call(room_addr,"lua","prepare",room_pos,msg.d);
		return {c=4,flag= ret and 1 or 0,d=msg.d}
	end
end

function CMD.disconnect()
	skynet.error("disconnect:",room,skynet.self())
	if room then
		room_addr = nil
		skynet.call(room_manager_addr,"lua","exit_room",room,room_pos,skynet.self())
	end
	skynet.error("agent exit")
	skynet.exit()
end

--发送数据到客户端
local function sendToCline(msg)
	skynet.call(ws_service_addr,"lua","send",msg,skynet.self())
end

--更新房间人物信息
function CMD.update_room(info)
	sendToCline({c=2001,d=info})
end

--房间聊天
function CMD.talk_room(msg)
	sendToCline({c=2002,d=msg})
end

--发牌
function CMD.send_cards(msg)
	local t = {c=4001,d={pid=room_pos,cards=msg}}
	sendToCline(t)
end

--叫地主
function CMD.call_landlord(msg)
	local t = {c=4002,d={pid=room_pos,socre=msg}}
	sendToCline(t)
end

--出牌
function CMD.play_card(msg)

end

--准备
function CMD.prepare_room(pos,msg)
	local ret = {c=3001,d={pid=pos,status=msg}}
	sendToCline(ret)
end

skynet.start(function()
	skynet.dispatch("lua",function(_,_,command,...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
