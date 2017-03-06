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
	self._current_idx = 0
	self._playerCards = {{},{},{}}
	self._landlord = {}
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
		for i = 1,3 do
			playerCards[i][j] = cards[idx]
			idx = idx + 1
		end
	end
	for i = 1,3 do
		self._delegate:sendCards(i, tconcat(playerCards[i]))
	end
end

--玩家出牌
function Poke:playCard(card,playerId)

end

function Poke:initStart()
	
end

--切换玩家
function Poke:next()
	if self.game_over then return end
	if self:initStart() then --开始前的准备

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

function Poke:setStartI(zid)
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
