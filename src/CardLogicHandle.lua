--local LogicCard = require "LogicCard"
local CardTypeDic = require "CardTypeDic"
local CardLogicHandle = {}
local t_concat = table.concat
local t_rm 	= table.remove
local t_sort = table.sort
local math_ceil = math.ceil

local flag_num = CardTypeDic.flag_num
local bit_nums = CardTypeDic.bit_nums

local function check_keep(keys,s,e)
	local last_num
	s = s or 1
	e = e or #keys
	if keys[e] >= 13 then  --A2不能组合 过了12不存在连续
		return false
	end
	local max = keys[e]
	for i = s,e do
		local num = keys[i]
		if num then
			if last_num == nil then
				last_num = num
			else
				if last_num-num ~= -1 then
					return false
				end
				last_num = num
			end
		end
	end
	return true,max
end

local function getInfo(number)
	local cid = number - 47
	return math_ceil(cid/4),(cid-1)%4+1
end

local handleByCount={}

handleByCount[CardTypeDic.SHUANG] = function (str)
	local temp_card1 = math_ceil((str:byte(1)-47)/4)
	local temp_card2 = math_ceil((str:byte(2)-47)/4)
--LogicCard.new(str:byte(2))
	if temp_card1 > temp_card2 then
		temp_card1,temp_card2 = temp_card2,temp_card1
	end
	if temp_card1 == temp_card2 then							--对子
		return CardTypeDic.SHUANG,temp_card1,1
	elseif temp_card1 == 14 and temp_card2 == 15 then   --王炸
		return CardTypeDic.WZ,14,2
	else 	 													--不符合要求
		return nil
	end
end

handleByCount[CardTypeDic.SAN] = function (str)		--三
	local temp_card1 =	math_ceil((str:byte(1)-47)/4)
-- LogicCard.new(str:byte(1))
	local temp_card2 =	math_ceil((str:byte(2)-47)/4)
-- LogicCard.new(str:byte(2))		
	local temp_card3 =	math_ceil((str:byte(3)-47)/4)
-- LogicCard.new(str:byte(3))
	if temp_card1 == temp_card2 and
		temp_card2 == temp_card3 then
		return CardTypeDic.SAN,temp_card1,1
	else
		return nil
	end
end
local function getMaxNumByCount(keys,count_dic,count)
	local num = keys[1]
	for i = 1,#count_dic do
		if count_dic[i].c == count then
			if count_dic[i].n > num then
				num = count_dic[i].n
			end
		end
	end
	return num
end
handleByCount[CardTypeDic.ZHA] = function (keys,count_dic) 	--炸弹
	return CardTypeDic.ZHA,keys[1],1
end
handleByCount[CardTypeDic.SAN_D] = function (keys,count_dic)		--三带一
	return CardTypeDic.SAN_D,getMaxNumByCount(keys,count_dic,3),1
end
handleByCount[CardTypeDic.SAN_S] = function (keys,count_dic)		--三带二
	return CardTypeDic.SAN_S,getMaxNumByCount(keys,count_dic,3),1
end
handleByCount[CardTypeDic.SI_D] = function (keys,count_dic) 	--四带一
	return CardTypeDic.SI_D,getMaxNumByCount(keys,count_dic,4),1
end
handleByCount[CardTypeDic.SI_S] = function (keys,count_dic)	    --四带二
	return CardTypeDic.SI_S,getMaxNumByCount(keys,count_dic,4),1
end
handleByCount[CardTypeDic.SI_2S] = function (keys,count_dic) 	--四带两对
	return CardTypeDic.SI_2S,getMaxNumByCount(keys,count_dic,4),1
end
handleByCount[CardTypeDic.SHUN] = function (keys,count_dic)	    --顺子
	local isok,max = check_keep(keys)
	if isok then
		return CardTypeDic.SHUN,max,#keys
	end
end
handleByCount[CardTypeDic.FEI] = function (keys,count_dic)			--飞机
	local isok,min = check_keep(keys)
	if isok then
		return CardTypeDic.FEI,min
	elseif #keys == 4 then
		--print(table.concat( keys, ", ",2))
		isok,min = check_keep(keys,2)
		if isok then
			return CardTypeDic.FEI_S,min,#keys-1
		end
		isok,min = check_keep(keys,1,#keys-1)
		if isok then
			return CardTypeDic.FEI_S,min,#keys-1
		end
	end
end

handleByCount[CardTypeDic.FEI_D] = function (keys,count_dic,dic)	--飞机带单
	local maxn = #keys
	local temp_keys = {}
	local e_pos = nil
	local dan_count = 0
	for i = 1,#count_dic do
		if count_dic[i].c < 3 then
			if e_pos == nil then e_pos = i - 1 end
			keys[dic[count_dic[i].n]] = nil
			dan_count = dan_count + count_dic[i].c
		end
	end
	e_pos = e_pos or #count_dic
	for i = 1,maxn do
		if keys[i] then
			temp_keys[#temp_keys + 1] = keys[i]
		end
	end
	-- print(table.concat( temp_keys, ", "),"|",e_pos,dan_count)
	local isok,min = check_keep(temp_keys)
	if not isok then
		if count_dic[1].c == 4 and count_dic[e_pos].c == 3 then
			dan_count = dan_count + 3
			if dan_count > 5 then return false end
			isok,min = check_keep(temp_keys,2)
			if isok then
				return CardTypeDic.FEI_D,min,#temp_keys-1
			end
			isok,min = check_keep(temp_keys,1,#temp_keys-1)
			if isok then
				return CardTypeDic.FEI_D,min,#temp_keys-1
			end
		elseif count_dic[1].c == 3 and count_dic[e_pos].c == 3 then
			dan_count = dan_count + 3
			if dan_count > 5 then return false end
			isok,min = check_keep(temp_keys,2)
			if isok then
				return CardTypeDic.FEI_D,min,#temp_keys-1
			end
			isok,min = check_keep(temp_keys,1,#temp_keys-1)
			if isok then
				return CardTypeDic.FEI_D,min,#temp_keys
			end
		end
	else
		return CardTypeDic.FEI_D,min,#temp_keys
	end
end
handleByCount[CardTypeDic.FEI_S] = function (keys,count_dic,dic)  --飞机带双
	local maxn = #keys
	local temp_keys = {}
	for i = 1,#count_dic do
		if count_dic[i].c ~= 3 then
			keys[dic[count_dic[i].n]] = nil
		end
	end
	for i = 1,maxn do
		if keys[i] then
			temp_keys[#temp_keys + 1] = keys[i]
		end
	end
	-- print(table.concat( temp_keys, ", "),"|",e_pos,dan_count)
	local isok,min = check_keep(temp_keys)
	if not isok then return end
	return CardTypeDic.FEI_S,min,#temp_keys
end

handleByCount[CardTypeDic.LIAN] = function (keys,count_dic,dic)	--连对
	local isok,min = check_keep(keys)
	if isok then
		return CardTypeDic.LIAN,min,#keys
	end
end

local function getCounts(keys,flags)
	if #keys == 1 then
		local num = keys[1]
		local c = flag_num[flags[num]]
		return ""..c,{{c=c,n=num}}
	else
		t_sort( keys )
		local dic = {}
		local counts = {}
		local count_dic={}
		for i = 1,#keys do
			local num = keys[i]
			local c = flag_num[flags[num]]
			counts[i] = c
			count_dic[i] = {
				c=c,
				n=num
			}
			dic[num] = i
		end
		t_sort( counts,function ( a,b ) return a > b end )
		t_sort( count_dic, function( a,b ) return a.c > b.c	end )
		return t_concat(counts,""),count_dic,dic
	end
end

local function check_cardType(keys,flags,card_count)
	local key,count_dic,dic = getCounts(keys,flags)
	print(key,CardTypeDic[key])
	local card_type,min,len= CardTypeDic[key],keys[1]
	if card_type then
		card_type,min,len= handleByCount[card_type](keys,count_dic,dic)
	end
	return card_type,min,len
end

function CardLogicHandle:getCardType(str)
	local card_flags = {} 					--数量
	local keys = {}							--牌的种类
	local card_count = #str
	local card_type,num,len
	if card_count == 1 then									    --单
		local temp_card = math_ceil((str:byte(1)-47)/4)
 --LogicCard.new(str:byte(1))
		card_type,num,len = CardTypeDic.DAN,temp_card,1,1
	elseif card_count == 2 then
		card_type,num,len = handleByCount[CardTypeDic.SHUANG](str)
	elseif card_count == 3 then
		card_type,num,len = handleByCount[CardTypeDic.SAN](str)
	else
		for i = 1,card_count do
			local card_id = str:byte(i)
			local temp_num,temp_flower = math_ceil((card_id-47)/4),(card_id-1)%4+1
			local is_nil = card_flags[temp_num]
			local flag = is_nil or 0
			flag = flag + bit_nums[temp_flower]
			if not is_nil then
				keys[#keys+1] = temp_num
			end
			card_flags[temp_num] = flag
		end
		card_type,num,len = check_cardType(keys,card_flags,card_count)		
	end
	return card_type,num,len,card_count
end

return CardLogicHandle
