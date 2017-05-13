local LogicCard = {}
local logic_card_mt = {__index = LogicCard}
local string_char = string.char
function LogicCard:ctor(number)
	local cid = number - 47
	self.num = math.ceil(cid / 4)
	self.flower = (cid - 1) % 4 + 1
	self.cid = number
	self.char = string_char(number)
end

function LogicCard:getInfo( )
	return self.num,self.flower
end

function LogicCard.new( ... )
	local instance = {}
	setmetatable(instance,logic_card_mt)
	instance:ctor(...)
	return instance
end

return LogicCard
