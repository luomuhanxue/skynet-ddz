local PokeHandle= {}

local game_mt={__index=PokeHandle}
--设置回调更多的自定义事件
function PokeHandle:sendCards(pidx,cards)
	self.msg2one(pidx,1,cards)
end

function PokeHandle:askScore( pidx )
	self.msg2one(pidx,2)
end

function PokeHandle:play( pidx )
	self.msg2one(pidx,3)
end

function PokeHandle:sendLordCards( lordIdx,cards )
	self.msg2all(1, {lord=lordIdx, cards=cards})
end

function PokeHandle.new(all_event,one_event)
	local instance = {
		msg2all = all_event,
		msg2one = one_event
	}
	return setmetatable(instance,game_mt)
end

return PokeHandle 
