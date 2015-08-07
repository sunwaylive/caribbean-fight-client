require "GlobalVariables"
require "Actor"
require "Manager"
	
local BloodbarLayer = class("bloodbarLayer",function() return cc.Layer:create() end)

function BloodbarLayer.create()
    local layer = BloodbarLayer.new()
	return layer
end

--初始化做的事情就是根据角色数增加血条
function BloodbarLayer:ctor()
	-- self.bloodbarList = List.new()
	-- --self.bloodbarBackList = List.new()
	-- self.arrowList = List.new()
	-- self.circleList = List.new()
	-- self:addChild(self.bloodbarList)
	-- self:addChild(self.arrowList)
	-- self:addChild(self.circleList)
end

function BloodbarLayer:init()
	--英雄的血条
	for val = HeroManager.first, HeroManager.last do
        local actor = HeroManager[val]
		bloodbar = cc.ProgressTimer:create(cc.Sprite:createWithSpriteFrameName("UI-1136-640_36_clone.png"))
		bloodbar:setColor(cc.c3b(149,254,26))
		bloodbar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
		bloodbar:setMidpoint(cc.vertex2F(0,0))
		bloodbar:setBarChangeRate(cc.vertex2F(1,0))
		bloodbar:setPercentage(100)
		bloodbar:setPosition3D(cc.V3(actor:getPositionX(), actor:getPositionY(),4))
		bloodbar:setScale(1,2)
		List.pushlast(bloodbarList,bloodbar)
		self:addChild(bloodbar)
    end
	--小怪的血条，实际可能用不到，或者给AI用
	for val = MonsterList.first, MonsterList.last do
        local actor = MonsterList[val]
		bloodbar = cc.ProgressTimer:create(cc.Sprite:createWithSpriteFrameName("UI-1136-640_36_clone.png"))
		bloodbar:setColor(cc.c3b(255,0,0))
		bloodbar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
		bloodbar:setMidpoint(cc.vertex2F(0,0))
		bloodbar:setBarChangeRate(cc.vertex2F(1,0))
		bloodbar:setPercentage(100)
		bloodbar:setPosition3D(cc.V3(actor:getPositionX(), actor:getPositionY(),4))
		bloodbar:setScale(1,2)
		bloodbar:setVisible(false)
		List.pushlast(monsterBloodbarList,bloodbar)
		self:addChild(bloodbar)
    end
end

return BloodbarLayer