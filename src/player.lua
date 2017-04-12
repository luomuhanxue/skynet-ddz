local skynet = require "skynet"
local websocket = require"websocket"
local json = require "cjson"
local function send_msg(fd,msg)
	local json_str = json.encode(msg)
	skynet.error("room: send--->",json_str,#json_str,fd)
	websocket:send_text(fd,json_str)
end

local M = {}
M.__index = M

function M:talk( data )
	local isok = false
	if type(data)=="table" and type(data.type) == "number" then
		if data.type == 1 then
			isok = (type(data.msg)=="number") and (data.msg >= 1) and (data.msg <= 11)
		elseif data.type == 2 then
			isok = (type(data.msg)=="number") and (data.msg >= 1) and (data.msg <= 51)
		elseif data.type == 3 then
			isok = true
		else
			isok = false
		end
	end
	if isok then
		send_msg(self.fd,{c=3,f=1,d={msg=data.msg,p=self.pos,type=data.type}})
	end
	return isok
end

function M:otherTalk( pos,data )
	send_msg(self.fd,{c=2001,d={msg=data.msg,p=pos,type=data.type}})
end

function M:myprepare( data )
	local isok = type(data)=="table" and type(data.prepare) == "boolean" and type(data.show) == "boolean"
	if isok then
		self.show = data.show
		self.prepare = data.prepare
		send_msg(self.fd,{c=4,f=1,d={p=self.pos,prepare=data.prepare}})
	end
	return isok
end

function M:otherPrepare( pos,data )
	send_msg(self.fd,{c=2002,d={p=pos,prepare=data.prepare}})
end

function M:enter(rid,others)
	local ret = {c=2,f=1, d = {rid = rid,pos = self.pos,others = others}}
	send_msg(self.fd,ret)
end

function M:otherEnter(other)
	local ret = {c=1001,d = other}
	send_msg(self.fd,ret)
end

function M:exit( )
	
end

function M:otherExit( pos )
	send_msg(self.fd,{c=1002,pos=pos})
end

function M:getInfo( )
	return {
		pos = self.pos,
		nickname = self.nickname,
		coin = self.coin,
		sex = self.sex,
		prepare = self.prepare
	}
end

function M:error(cmd_id,f)
	send_msg(self.fd,{c=cmd_id,f=f})
end

-----------------------------------------
function M:setCards(cards)
	self._cards = cards
	if self.show then
		return true,{cards = table.concat(cards,""),pos = self.pos}
	end
	return false
end

function M:sendCards(others)
	send_msg(self.fd,{c=3001,d={
		pos = self.pos,
		cards=table.concat(self._cards,""),
		others=others
	}})
end

function M:askLandlord(npos,info,time)
	send_msg(self.fd,{c=51,f = 1,p = npos,d = info,t=time})
end
function M:otherAskLandlord(pos,info,time)
	send_msg(self.fd,{c=3002,p = pos, d = info,t=time})	
end
function M:sendLandlordCards(data)
	send_msg(self.fd,{c=3003,d = data})
end
--------------------------------------------------------
function M:play()

end
function M:otherPlay()

end
-----------------------------------------

function M.new( pos,info,con )
	local instance = setmetatable({
		pos = pos,
		prepare = false,
		coin = info.coin,
		nickname = info.nickname,
		sex = info.sex,
		uid = con.uid,
		fd = con.fd
	},M)
	return instance
end

return M
