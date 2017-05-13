local skynet = require"skynet"
local LogicCard = require "LogicCard"
local CardTypeDic = require "CardTypeDic"

local t_maxn = table.maxn
local t_concat = table.concat
local t_rm 	= table.remove
local t_sort = table.sort

local flag_num = CardTypeDic.flag_num
local bit_nums = CardTypeDic.bit_nums

local PlayerCards = {}
local p_card_mt = {__index = PlayerCards}

function PlayerCards:ctor(str_arr)
	local card_flags = {}
	local keys = {}
	local card_arr = {}
	local card_dic = {}
	local card_count = #str_arr
	for i = 1,card_count do
		local card_id = str_arr[i]:byte(1)
		skynet.error(card_id)
		local temp_card = LogicCard.new(card_id)
		local temp_num,temp_flower = temp_card:getInfo()
		local is_nil = card_flags[temp_num]
		local flag = is_nil or 0
		flag = flag + bit_nums[temp_flower]
		if not is_nil then
			keys[#keys+1] = temp_num
		end
		local temp_arr = card_arr[temp_num]
		if not temp_arr then
			temp_arr={}
			card_arr[temp_num] = temp_arr
		end
		temp_arr[temp_flower] = temp_card
		card_dic[card_id] = temp_card
		card_flags[temp_num] = flag
	end
	t_sort(keys)
	self._count = card_count
	self._card_flags = card_flags
	self._keys = keys
	self._cards = card_arr
	self._card_dic = card_dic
end

--增加地主牌
function PlayerCards:addLandlordCards( str_arr )
	local card_flags = self._card_flags
	local keys = self._keys
	local card_arr = self._cards
	local card_dic = self._card_dic
	local card_count = #str_arr
	self._count = self._count + card_count
	for i = 1,card_count do
		local card_id = str_arr[i]:byte(1)
		skynet.error(card_id)
		local temp_card = LogicCard.new(card_id)
		local temp_num,temp_flower = temp_card:getInfo()
		local is_nil = card_flags[temp_num]
		local flag = is_nil or 0
		flag = flag + bit_nums[temp_flower]
		if not is_nil then
			keys[#keys+1] = temp_num
		end
		local temp_arr = card_arr[temp_num]
		if not temp_arr then
			temp_arr={}
			card_arr[temp_num] = temp_arr
		end
		temp_arr[temp_flower] = temp_card
		card_dic[card_id] = temp_card
		card_flags[temp_num] = flag
	end
	t_sort(keys)
end

function PlayerCards:show( )
	local arr = {}
	local keys = self._keys
	for i = 1,#keys do
		local str = keys[i]..":"..flag_num[self._card_flags[keys[i]]]
		arr[#arr + 1] = str
	end
	print(t_concat(self._keys,","),"|>>",self._count)
	print(t_concat(arr," , "))
end

--检测是否有这些牌
function PlayerCards:checkCards( str )
	local ret = false
	local t = {}
	local card_dic = self._card_dic
	for i = 1,#str do
		local cid = str:byte(i)
		local card = card_dic[cid]
		if card == nil then
			return nil
		else
			t[#t + 1] = card
		end
	end
	return t
end

--出牌
function PlayerCards:playCards( t )
	local card_dic = self._card_dic
	local cards = self._cards
	local keys = self._keys
	local card_flags = self._card_flags
	for i = 1,#t do
		local card = t[i]
		card_dic[card.cid] = nil
		cards[card.num][card.flower] = nil
		self._count = self._count - 1
		local flag = card_flags[card.num]
		flag = flag - bit_nums[card.flower]
		if flag == 0 then
			for j = #keys,1,-1 do
				if keys[j] == card.num then
					t_rm(keys,j)
					break
				end
			end
		end
		self._card_flags[card.num] = flag
	end
	return self._count == 0
end

--获取最小的一张牌
function PlayerCards:getDefaultCard( )
	local keys = self._keys
	local t = {}
	local num = keys[1]
	local cards = self._cards[num]
	if cards[1] then return {cards[1]} end
	if cards[2] then return {cards[2]} end
	if cards[3] then return {cards[3]} end
	if cards[4] then return {cards[4]} end
end

--根据牌型获取最小的牌
function PlayerCards:getCardByType( card_type )

end

function PlayerCards.new(...)
	local instance = {}
	setmetatable(instance,p_card_mt)
	instance:ctor(...)
	return instance
end

return PlayerCards
