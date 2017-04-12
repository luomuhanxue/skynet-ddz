local skynet = require"skynet"
local random = math.random
local randomseed = math.randomseed
local string = string
local tconcat = table.concat
local PokeServer = {}
local PokeServer_mt = {__index=PokeServer}

local function cancelable_timeout( ti,func)
	local function cb( )
		if func then
			func()
		end
	end
	local function cancel( )
		func = nil
	end
	skynet.timeout(ti,cb)
	return cancel
end
--[[
分成三个阶段
1 发牌
2 叫地主
3 打牌
4 结算
--]]
function PokeServer:ctor( users )
	self._users = users			--参与的玩家
end

function PokeServer:initCards( )
	self._game_status = 1		--游戏进度
	self._landlordCards = {}			--地主牌
	self._current_idx = 1		--当前玩家
	self._landlord_idx = nil	--地主id
	self._ask_times = 0			--叫地主次数
	local arr = {}
	for i = 1,13 do
		for j = 1,4 do
			arr[#arr + 1] = string.char((i-1) * 4 + j + 47)
		end
	end
	arr[#arr + 1] = string.char(100) --小王
	arr[#arr + 1] = string.char(104) --大王
	self._cards = arr
	self._playerCards={{},{},{}}
end

--随机
function PokeServer:random( )
	local time = skynet.time()
	randomseed(time)
	local arr = self._cards
	for i = 1,27 do
		local idx = random(27)
		arr[i],arr[27+idx] = arr[27+idx],arr[i]
	end
	for i = 1,54 do
		local idx = random(54)
		arr[i],arr[idx] = arr[idx],arr[i]
	end
end

function PokeServer:start(  )
	self:initCards()
	self:random()
	self._game_over = false
	self._game_status = 1
	self._cancel = cancelable_timeout(100,function()
		self:sendCards()
		self:gameLoop(2)			--10秒不叫则取消切换到下个人
	end)
end

function PokeServer:sendCards( )
	local cards = self._cards
	local playerCards = self._playerCards
	local idx = 1
	for j = 1,17 do
		playerCards[1][j] = cards[idx]
		playerCards[2][j] = cards[idx+1]
		playerCards[3][j] = cards[idx+2]
		idx = idx + 3
	end
	self._landlordCards[1] = cards[52]
	self._landlordCards[2] = cards[53]
	self._landlordCards[3] = cards[54]
	local showArr = {}
	for i = 1,3 do
		local isShow,card_info = self._users[i]:setCards(playerCards[i])
		if isShow then
			showArr[#showArr+1]=card_info
		end
	end
	for i = 1,3 do 
		self._users[i]:sendCards(showArr)
	end
end
--游戏循环
function PokeServer:gameLoop(ti)
	self._cancel = cancelable_timeout(ti*100,function ( )
		skynet.error("-----> change palyer:",self._current_idx)
		local sec = self:playerNotDo()
		if sec then
			self:gameLoop(sec+1)
		end
	end)
end

function PokeServer:sendLandlordCards()
	local cards = tconcat(self._landlordCards,"")
	for i = 1,3 do
		if self._users[i] then
			self._users[i]:sendLandlordCards({p=self._landlord_idx,cards=cards})
		end
	end
	self._current_idx = self._landlord_idx
	--self:gameLoop(2)
end

function PokeServer:playerNotDo()
	if self._game_status == 1 then
		self._game_status = 2
		return  self:askLandlord()	--开始叫地主
	elseif self._game_status == 2 then
		local info = {p=self._current_idx,status=0} --默认不叫,不抢
		if self._landlord_idx == nil then
			if self._ask_times == 3 then  --3次没人叫地主
				--没人叫 重新开始
				self:start()
				return 
			end
			local next_idx = self._current_idx + 1
			if next_idx == 4 then next_idx = 1 end
			self._current_idx = next_idx
			return self:askLandlord(nil,info)
		else
			local next_idx = self._current_idx + 1
			if next_idx == 4 then next_idx = 1 end
			if self._ask_times == 3 and 
				self._landlord_idx == self._first_landlord_idx then	
				--地主为最开始的人
				skynet.error("地主是:",self._landlord_idx)
				self:sendLandlordCards()
				return 
			end
			if self._ask_times == 4 then
				--最开始的人不抢回地主
				skynet.error("地主是:",self._landlord_idx)
				self:sendLandlordCards()
				return
			end
			self._current_idx = next_idx
			return self:askLandlord(nil,info)
		end
	elseif self._game_status == 3 then
		--超时未出牌托管自动出
		if self._max_cidx then	
			if self._max_cidx == self._current_idx then  --改玩家牌很大没人要

			else	--出牌
				local cards = self._users:getDefaultCards(self._play_cards)
				if cards then

				end
			end
		else
			self._max_cidx = self._current_idx	--记录每回合开始出牌的玩家
			local cards = self._users:getDefaultCards(nil)
			self._play_cards = {}	
		end
		
		local info = {p=self._current_idx,status=0} --默认不叫,不抢
		local next_idx = self._current_idx + 1
		if next_idx == 4 then next_idx = 1 end
		return self:askPlay(nil,info)
	end
end

function PokeServer:askPlay(pos,info)
	local wait_time = 25

	return wait_time
end

--发送叫地主通知或者回应
function PokeServer:askLandlord(pos,info)
	local ask_time_out = 15
	self._ask_times = self._ask_times + 1
	local users = self._users
	for i = 1,#users do
		if users[i] then
			if i == pos then
				users[i]:askLandlord(self._current_idx,info,ask_time_out)	
			else
				users[i]:otherAskLandlord(self._current_idx,info,ask_time_out)
			end
		end
	end
	return ask_time_out
end


function PokeServer:handleEvent(cmd,pos,data)
	if pos == self._current_idx then
		if cmd == 51 then 			--叫地主
			self._cancel()			--取消定时器
			if data.status ~= 0 then
				if not self._landlord_idx then
					self._first_landlord_idx = pos --记录第一个人叫地主的位置
				end
				self._landlord_idx = pos
			end
			local info = {p=pos,status = data.status}
			local next_idx
			if self._ask_times == 3 then --一轮结束看是否需要继续抢
				if self._landlord_idx == nil then --三个人都不叫重新发牌
					self:start()
					return
				end
				if self._landlord_idx ~= self._first_landlord_idx then	--地主有争议由最初叫地主的最后一抢
					self._current_idx = self._first_landlord_idx
					next_idx = self._first_landlord_idx
				else
					---结束
					skynet.error("地主是:",self._landlord_idx)
					self:sendLandlordCards()
					return
				end
			elseif self._ask_times == 4 then --最终抢
				--确定地主位置
				skynet.error("地主是:",self._landlord_idx)
				self:sendLandlordCards()
				return
			else
				next_idx = pos + 1
				if next_idx == 4 then next_idx = 1 end
				self._current_idx = next_idx
			end
			local sec = self:askLandlord(pos,info)
			self:gameLoop(sec+1)
		elseif cmd == 52 then 		--出牌
	
		elseif cmd == 53 then 		
	
		elseif cmd == 54 then
	
		end
	else
		if self._users[pos] then
			self._users[pos]:error(cmd,-2)
		end
	end
end

function PokeServer:exit()
	if self._cancel then
		self._cancel()
	end
end

function PokeServer.new(...)
	local instance = {}
	setmetatable(instance,PokeServer_mt)
	instance:ctor(...)
	return instance
end

return PokeServer
