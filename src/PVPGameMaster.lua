require "Manager"
require "Knight"
require "Mage"
require "Actor"
require "GlobalVariables"
require "Piglet"
require "Slime"
require "Rat"
require "Dragon"
require "Archer"
require "Helper"
--require "Boss"

local gloableZOrder = 1
local monsterCount = {dragon=1,slime=7,piglet=2,rat = 0} --rat count must be 0.
local propTypesCnt = 2 --假设3中类型的道具,修改这个数值，必须修改addProp中，往PropManager添加的道具的数量，否则会有nil值出现

local EXIST_MIN_MONSTER = 4
local scheduleid
local stage = 0
local battleSiteX = {-2800,-1800,-800} --设置了触发地点 和 刷新地点,经过这些地方之后，会刷新怪物 -2800 -1800 -800
local frontDistanceWithHeroX = 600
local backwardDistanceWithHeroX = 800
local distanceWithHeroX = 150
local distanceWithHeroY = 150

local PVPGameMaster = class("PVPGameMaster")

local size = cc.Director:getInstance():getWinSize()

function PVPGameMaster:ctor()
	self._totaltime = 0
	self._logicFrq = 1.0

    self._totaltime_prop = 0 --用来控制道具的刷新
    self._propFrq = 20.0 --每5秒钟刷新一个道具
    
    self._myIdx = 0 --默认自己为0号位置上的玩家
end

function PVPGameMaster.create(sg_tbl)
	local gm = PVPGameMaster.new()
    print("in PVPGameMastser.create(): " .. sg_tbl)
	gm:init(sg_tbl)

	return gm
end

--统一把角色创建好，然后分批放出来
function PVPGameMaster:init(sg_msg)
    print("in PVPGameMastser:init(): " .. sg_msg)
	self:AddHeros(sg_msg)

    self:addProps() --添加道具

    stage = 0
    --math.randomseed(tostring(os.time()):reverse():sub(1, 6))
    --for i=1,4 do
    --    self:randomshowMonster(true)
    --end
    stage = 1
end

--每隔一定的时间刷新游戏的逻辑
function PVPGameMaster:update(dt)
    self._totaltime = self._totaltime + dt
	if self._totaltime > self._logicFrq then
		self._totaltime = self._totaltime - self._logicFrq
		self:logicUpdate()
	end
 
    --这里控制道具的刷新
    self._totaltime_prop = self._totaltime_prop + dt
    if self._totaltime_prop > self._propFrq then
        self._totaltime_prop = self._totaltime_prop - self._propFrq
        self:showProp() --刷新道具
    end
end

--帧循环，主要负责控制英雄前进和小怪的刷新,每一阶段刷新出新的怪物
function PVPGameMaster:logicUpdate()    
    
end

function PVPGameMaster:GetClientOwnPlayer()
    --cclog("!!!!!本客户端的玩家索引号: " .. self._myIdx)
    if HeroManager ~= nil and self._myIdx <= #(HeroManager) then
        return HeroManager[self._myIdx]
    else
        cclog("Error: Can't get client Own Player!")
    end
end

--这里要根据服务器下发的位置 放置玩家
function PVPGameMaster:AddHeros(sg_msg) --startgame string
    cclog("in PVPGameMaster:AddHeros()")
    sg_tbl = mysplit(sg_msg, '#')
    
    print(sg_msg)
    print(#(sg_tbl))
    
    if #(sg_tbl) >= 2 then
        players_one_side = sg_tbl[2]
        cclog("单边玩家的数量: " .. players_one_side)
    end
    
    if players_one_side == "1" then --如果是1v1，则后面应该跟本客户端的index和两个玩家的信息
        print("in 1v1: " .. #(sg_tbl))
        if #(sg_tbl) < 5 then return end
        
        
        cclog("清空原来的所有玩家，并生成 1v1 的两个玩家")
        List.removeAll(HeroManager)
        self._myIdx = tonumber(sg_tbl[3])
        
        --0号位置的玩家
        local mage0 = Mage:create()
        mage0:setPosition(battleSiteX[1], 100)
        currentLayer:addChild(mage0)
        mage0:idleMode()
        mage0._camp = string.sub(sg_tbl[4], 3, 3)--camp
        mage0:setVisible(true)
        List.pushlast(HeroManager, mage0)
        
        --1号位置的玩家
        local mage1 = Mage:create()
        mage1:setPosition(battleSiteX[1], 300)
        currentLayer:addChild(mage1)
        mage1:idleMode()
        mage1._camp = string.sub(sg_tbl[5], 3, 3)--camp
        mage1:setVisible(true)
        List.pushlast(HeroManager, mage1)
    elseif players_one_side == "2" then --如果是2v2，则后面应该跟本客户端的index和4个玩家的信息
        print("in 2v2: " .. #(sg_tbl))
        if #(sg_tbl) < 7 then return end
    
    
        cclog("清空原来的所有玩家，并生成 2v2 的两个玩家")
        List.removeAll(HeroManager)
        self._myIdx = tonumber(sg_tbl[3])
        
        --0号位置的玩家
        local mage0 = Mage:create()
        mage0:setPosition(battleSiteX[1], 100)
        currentLayer:addChild(mage0)
        mage0:idleMode()
        mage0._camp = string.sub(sg_tbl[4], 3, 3)--camp
        mage0:setVisible(true)
        List.pushlast(HeroManager, mage0)
        
        --1号位置的玩家
        local mage1 = Mage:create()
        mage1:setPosition(battleSiteX[1], 300)
        currentLayer:addChild(mage1)
        mage1:idleMode()
        mage1._camp = string.sub(sg_tbl[5], 3, 3)--camp
        mage1:setVisible(true)
        List.pushlast(HeroManager, mage1)
        
        --2号位置的玩家
        local mage2 = Mage:create()
        mage2:setPosition(battleSiteX[1] + 500, 100)
        currentLayer:addChild(mage2)
        mage2:idleMode()
        mage2._camp = string.sub(sg_tbl[6], 3, 3)--camp
        mage2:setVisible(true)
        List.pushlast(HeroManager, mage2)
        
        --3号位置的玩家
        local mage3 = Mage:create()
        mage3:setPosition(battleSiteX[1] + 500, 300)
        currentLayer:addChild(mage3)
        mage3:idleMode()
        mage3._camp = string.sub(sg_tbl[7], 3, 3)--camp
        mage3:setVisible(true)
        List.pushlast(HeroManager, mage3)
        print("4 在生成的时候， HeroManager 大小： " .. #HeroManager) --输出为3，因为自定义的List，下标从0开始，而#从下标为1的位置开始
    end
    
    --删除场景中的战士和射手，只留下法师，需要相应的删除左下角的方块头像
    --local mage = Mage:create()
   	--mage:setPosition(battleSiteX[1], 100)--wei add.100
   	--currentLayer:addChild(mage)
   	--mage:idleMode()
    --mage:setVisible(false)--wei add
   	--List.pushlast(HeroManager, mage)
end

--添加道具
function PVPGameMaster:addProps()
    local prop1 = Piglet:create() --第一种类型的道具
    currentLayer:addChild(prop1)
    prop1:setVisible(false)
    prop1:setAIEnabled(false)
    List.pushlast(PropManager, prop1)

    local prop2 = Dragon:create() --第一种类型的道具
    currentLayer:addChild(prop2)
    prop2:setVisible(false)
    prop2:setAIEnabled(false)
    List.pushlast(PropManager, prop2)
end

--这里设置道具的运行轨迹
function PVPGameMaster:showProp()
    local propID = math.random(1, 100) % propTypesCnt -- 2种道具
    cclog(propID)
    local curProp = PropManager[propID]
    curProp:setPosition3D(cc.V3(-1600, -1000, 100))
    curProp:setVisible(true)
    local function hideCurProp()
        curProp:setVisible(false)
    end
    curProp:runAction(cc.Sequence:create(cc.MoveBy:create(10.0,cc.V3(0,1200,0)), cc.CallFunc:create(hideCurProp)))
    --当道具划过之后，如果中途没有被勾勾住，则需要隐藏掉
end

--function PVPGameMaster:showVictoryUI()
    --uiLayer:showVictoryUI()
--end

return PVPGameMaster