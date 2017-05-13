local skynet = require "skynet"
local websocket = require"websocket"
local json = require "cjson"
local PlayerCards = require"PlayerCards"
local CardLogicHandle = require"CardLogicHandle"
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
	self._player_cards = PlayerCards.new(cards)	
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
function M:setLandlordCards(cards)
	self._player_cards:addLandlordCards(cards)
end
function M:sendLandlordCards(data)
	send_msg(self.fd,{c=3003,d = data})
end
--------------------------------------------------------
function M:getDefaultCards()
	local card = self._player_cards:getDefaultCard()
	local is_win = self._player_cards:playCards(card)
	return is_win,{
		card[1].char,1,card[1].num,1,1
	}
end

function M:checkCards(cards,type_info)
	local card_arr = self._player_cards:checkCards(cards)
	if not card_arr then return nil end
	local is_win
	local ctype,num,len,count =	CardLogicHandle:getCardType(cards)
	skynet.error("my----->",ctype,num,len,count)
	if ctype == 15 then		--王炸
		is_win = self._player_cards:playCards(card_arr)
		return is_win,{cards,ctype,num,len,count}
	end
	if type_info then
		skynet.error("last--->",type_info[2],type_info[3],type_info[4],type_info[5])
		if ctype == 14 and ctype > type_info[2] then --炸弹炸其他牌
			is_win = self._player_cards:playCards(card_arr)
			return is_win,{cards,ctype,num,len,count}
		end
		if ctype == type_info[2] and num > type_info[3] 
			and len==type_info[4] and count == type_info[5] then	--本类型的牌比较

			is_win = self._player_cards:playCards(card_arr)
			return is_win,{cards,ctype,num,len,count}
		else
			--不符合要求
			return nil
		end
	else
		is_win = self._player_cards:playCards(card_arr)
		return is_win,{cards,ctype,num,len,count}
	end
end

function M:getCardsByInfo(info)
end

function M:play(npos,info,time)
	send_msg(self.fd,{c=52,f = 1,p = npos,d = info,t=time})
end
function M:otherPlay(pos,info,time)
	send_msg(self.fd,{c=3004,p = pos,d = info,t=time})
end

function M:gameOver()

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
