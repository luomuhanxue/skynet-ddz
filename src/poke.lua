local skynet = require"skynet"
local random = math.random
local randomseed = math.randomseed
local string = string
local tconcat = table.concat
local Poke = {}
local poke_mt = {__index=Poke}
--初始化
function Poke:init()
	local arr = {}
	for i = 1,13 do
		for j = 1,4 do
			arr[#arr + 1] = string.char((i-1) * 4 + j + 47)
		end
	end
	arr[#arr + 1] = string.char(100) --小王
	arr[#arr + 1] = string.char(104) --大王
	self._cards = arr
	self._out_cards = {}
	self._players = {}
	self._current_idx = 0	--当前玩家
	self._ask_times = 0 	--叫地主的次数
	self._ask_score = 0		--当前分数
	self._playerCards = {{},{},{}}	--三个玩家牌
	self._landlord = {} 	--地主额外牌
	self._landlord_idx = 0	--地主的下标
	self._game_status = 0 	--0 未开始  1 叫地主   2 打牌  3 结算
end

--洗牌
function Poke:random()
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

--发牌
function Poke:sendCards()
	local cards = self._cards
	local playerCards = self._playerCards
	local idx = 1
	for j = 1,17 do
		playerCards[1][j] = cards[idx]
		playerCards[2][j] = cards[idx+1]
		playerCards[3][j] = cards[idx+2]
		idx = idx + 3
	end
	self._landlord[1] = cards[52]
	self._landlord[2] = cards[53]
	self._landlord[3] = cards[54]
	for i = 1,3 do
		self._delegate:sendCards(i, tconcat(playerCards[i]))
	end
	self._game_status = 1
end

--玩家出牌
function Poke:playCard(card,playerId)
	self._current_idx = self._current_idx + 1
	self._current_idx = self._current_idx > 3 and 1 or self._current_idx
end

--初始化
function Poke:initStart()
	--让第i个人开始叫分
end

--叫分
function Poke:askScore( idx,score)
	--是当前的叫分的人，且叫的分数大于已有的分数
	print("in---->",idx,score)
	if idx == self._current_idx and score <=3 and score > self._ask_score then
		self._ask_score = score
		if score ==  3 then		--3分
			self._ask_times = 3
			self._landlord_idx = idx
			self._current_idx = idx
			self._game_status = 2
			self._delegate:sendLordCards(idx,tconcat(self._landlord)) 	--通知更新地主牌
			print("----------ask--end-----------")
		elseif score < 3 then
			if self._ask_times == 3 then		--达到三次
				self._landlord_idx = idx 		--这个叫分的人就是地主
				self._current_idx = idx
				self._game_status = 2
				self._delegate:sendLordCards(idx,tconcat(self._landlord))
				print("----------ask--end-----------")
			else
				self._current_idx = self._current_idx + 1
				self._current_idx = self._current_idx > 3 and 1 or self._current_idx 
				print("----------ask--ct-----------",self._current_idx)
			end
			self._ask_times = self._ask_times + 1
		end
		return true
	end
	return false
end

--切换玩家
function Poke:next()
	if self._game_status == 0 then return end
	if self._game_status == 1 then
		self._delegate:askScore(self._current_idx)
	elseif self._game_status == 2 then
		self._delegate:play(self._current_idx)
	elseif self._game_status == 3 then

	end
end

--重新开始
function Poke:restart()

end

--开始游戏
function Poke:start()
	self:random()
	self:sendCards()
end

function Poke:setStartId(zid)
	self._current_idx = zid
end

function Poke:addGameEvent(handle)
	self._delegate = handle
end

function Poke.new()
	local instance = {}
	return setmetatable(instance,poke_mt)
end

return Poke
