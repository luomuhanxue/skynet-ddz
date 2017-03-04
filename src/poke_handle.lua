local PokeHandle= {}

local game_mt={__index=PokeHandle}
--设置回调更多的自定义事件
function PokeHandle:sendCards(pidx,cards)
	self.msg2one(pidx,"send_cards",cards)
end
--玩家出牌
function PokeHandle:playerPlay()

end

--玩家退出
function PokeHandle:playerExit()

end


function PokeHandle.new(all_event,one_event)
	local instance = {
		msg2all = all_event,
		msg2one = one_event
	}
	return setmetatable(instance,game_mt)
end

return PokeHandle 
