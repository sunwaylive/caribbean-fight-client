require "Helper"
require "Manager"
require "MessageDispatchCenter"
require "BloodbarUI"

local fontPath = "chooseRole/actor_param.ttf"

bloodbarLayer = nil
currentLayer = nil
uiLayer = nil
gameMaster = nil
circle = nil
arrow = nil
t = nil

isGameOver = false
totalTimeLeft = 60
totalScore = 0

local specialCamera = {valid = false, position = cc.p(0,0)}
local size = cc.Director:getInstance():getWinSize()
local scheduler = cc.Director:getInstance():getScheduler()
local cameraOffset =  cc.V3(0, -700, 300 * 0.5)
local cameraOffsetMin = {x=-300, y=-400}
local cameraOffsetMax = {x=300, y=400}

--移动相机
local function moveCamera(dt)
    --cclog("moveCamera")
    if camera == nil then return end

    local cameraPosition = getPosTable(camera)
    --获取英雄的平均位置
    local focusPoint = getFocusPointOfHeros() --在manager.lua中被定义
    
    --如果正在特写
    --实际上是在specialCamera.valid被置为true的几秒内，临时改变了 camera位置的朝向(lookAt)的计算方式。
    if specialCamera.valid == true then
        local position = cc.pLerp(cameraPosition, cc.p(specialCamera.position.x, (cameraOffset.y + focusPoint.y-size.height*3/4)*0.5), 5*dt)
        
        camera:setPosition(position)
        camera:lookAt(cc.V3(position.x, specialCamera.position.y, 50.0), cc.V3(0.0, 1.0, 0.0))
    elseif List.getSize(HeroManager) > 0 then
        --更新相机的位置，每一帧都更新。自动随着角色的移动而更新相机的位置。让camera 和 FocusPoint 的y坐标保持一致
        --local temp = cc.pLerp(cameraPosition,
          --                    cc.p(focusPoint.x + cameraOffset.x, cameraOffset.y + focusPoint.y - size.height * 3 / 4), 2 * dt)
        --上一句是为了平滑过渡相机，这里我们不需要，直接设置相机的位置和便宜更加有控制感
        local temp = cc.V3(focusPoint.x + cameraOffset.x, cameraOffset.y + focusPoint.y)
        local position = cc.V3(temp.x, temp.y, 700)
        camera:setPosition3D(position)
        camera:lookAt(cc.V3(focusPoint.x, focusPoint.y + 0, 10.0), cc.V3(0.0, 0.0, 1.0)) --TODO: 要调整相机的视角，可以修改cameraOffset！！！
        --cclog("\ncalf %f %f %f \ncalf %f %f 50.000000", position.x, position.y, position.z, focusPoint.x, focusPoint.y)            
    end
end

local function moveHero(dt)
    --首先更新角色的朝向
    for val = HeroManager.last, HeroManager.first , -1 do
        local sprite = HeroManager[val]
        
        sprite._curFacing = cc.pToAngleSelf(sprite._heroMoveDir)
        sprite:setRotation(-RADIANS_TO_DEGREES(sprite._curFacing))
        local curPos = sprite._myPos
        local newPos = cc.pAdd(curPos, cc.p(sprite._heroMoveDir.x * sprite._heroMoveSpeed * dt, sprite._heroMoveDir.y * sprite._heroMoveSpeed * dt))
        sprite:setPosition(newPos)
    end
    
    return true
end

--每帧都执行
local function heroAttack(dt)
    for val = HeroManager.first, HeroManager.last do
        local sprite = HeroManager[val]
        if sprite:getStateType() == EnumStateType.ATTACKING then
            sprite:attackUpdate(dt)
        end
    end
end

--让粒子效果跟随角色移动
local function updateParticlePos()
    --cclog("updateParticlePos")
    for val = HeroManager.first, HeroManager.last do
        local sprite = HeroManager[val]
        if sprite._effectNode ~= nil then --effectNode保存着粒子特效
            sprite._effectNode:setPosition(getPosTable(sprite))
        end
    end
end

local function updateTimeLabel()
    if uiLayer.timeLabel == nil then return end
    
    totalTimeLeft = totalTimeLeft - 1
    if totalTimeLeft < 0 then totalTimeLeft = 0 end
    uiLayer.timeLabel:setString(tostring(totalTimeLeft))
end

local function updateScoreLabel()
    if gameMaster == nil or uiLayer.scoreLabel == nil then return end
    
    uiLayer.scoreLabel:setString(tostring(totalScore))
end

local function checkWinOrLose()
    if totalTimeLeft > 0 or isGameOver then return end
    
    if totalScore < 10 then
        uiLayer:showGameResultUI(false, true)
    else
        uiLayer:showGameResultUI(true, false)
    end
    isGameOver = true
    scheduler:unscheduleScriptEntry(updateScoreLabelScheduleID)
    scheduler:unscheduleScriptEntry(updateTimeLabelScheduleID)
    scheduler:unscheduleScriptEntry(checkWinOrLoseScheduleID)
end

local function showStartPopup(UILayer)
    --color layer
    local layer = cc.LayerColor:create(cc.c4b(10,10,10,150))
    layer:ignoreAnchorPointForPosition(false)
    layer:setPosition3D(cc.V3(G.winSize.width*0.5, G.winSize.height*0.5,0))
    
    --add victory
    local victory = cc.Sprite:createWithSpriteFrameName("rule.png")
    
    victory:setPosition3D(cc.V3(G.winSize.width*0.5,G.winSize.height*0.5,3))
    victory:setScale(0.1)
    victory:setGlobalZOrder(UIZorder)
    layer:addChild(victory,1)
    
    --victory run action
    local action = cc.EaseElasticOut:create(cc.ScaleTo:create(1.5,1))
    victory:runAction(action)
    
    --touch event
    local function onTouchBegan(touch, event)
        return true
    end
    
    local function onTouchEnded(touch,event)
		if layer:isVisible() == true then
			--当用户点击开始这个popup的时候，开始播放背景音乐
			AUDIO_ID.BATTLEFIELDBGM = ccexp.AudioEngine:play2d(BGM_RES.BATTLEFIELDBGM, true,0.6)
			victory:setVisible(false)
			layer:setVisible(false)
			updateTimeLabelScheduleID  = scheduler:scheduleScriptFunc(updateTimeLabel, 1, false)
			updateScoreLabelScheduleID = scheduler:scheduleScriptFunc(updateScoreLabel, 0.5, false)
			checkWinOrLoseScheduleID = scheduler:scheduleScriptFunc(checkWinOrLose, 1, false)
		end
    end
    
    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = layer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener,layer)
    
    UILayer:addChild(layer)
end


--设置主场景中的地图和背景
local function createBackground()
    --local spriteBg = cc.Sprite3D:create("model/scene/changing.c3b")
    -- local spriteBg = cc.Sprite3D:create("minigame/map5.c3t")
	local spriteBg = cc.Sprite3D:create("minigame/background/sea1.c3t")

    currentLayer:addChild(spriteBg)
    spriteBg:setScale(20000) --要放很大，不然看不见
    spriteBg:setPosition3D(cc.V3(-2000,0,-100))
    spriteBg:setRotation3D(cc.V3(90,0,0)) --添加了地图的旋转
    spriteBg:setGlobalZOrder(-100)

	local spriteBoat = cc.Sprite3D:create("minigame/background/boatNewRight.c3t")

    currentLayer:addChild(spriteBoat)
    spriteBoat:setScale(15) 
    spriteBoat:setPosition3D(cc.V3(-3500,0,-220))
    spriteBoat:setRotation3D(cc.V3(90,0,0)) --添加了地图的旋转
    spriteBoat:setGlobalZOrder(-50)
	
	local spriteBoat = cc.Sprite3D:create("minigame/background/boatNewRight.c3t")

    currentLayer:addChild(spriteBoat)
    spriteBoat:setScale(15) 
    spriteBoat:setPosition3D(cc.V3(-2000,0,-220))
    spriteBoat:setRotation3D(cc.V3(90,0,0)) --添加了地图的旋转
    spriteBoat:setGlobalZOrder(-50)
	
    --cc.Water:create 水的实现：在Water.cpp中。
    local water = cc.Water:create("shader3D/water.png", "shader3D/wave1.jpg", "shader3D/18.jpg", {width=5500, height=400}, 0.77, 0.3797, 1.2)
    currentLayer:addChild(water)
    water:setScaleX(2)
    water:setPosition3D(cc.V3(-1800,1200,-110)) --设定河流的位置
    water:setRotation3D(cc.V3(0, 0, 90))
    water:setAnchorPoint(0,0)
    water:setGlobalZOrder(-10)
    --先隐藏河流
    water:setVisible(false)
    
    --[[
    --test model
    sp = cc.Sprite3D:create("minigame/test-weapon/miaolian.c3b") --("minigame/maoRedoUv.c3b")
    --ret.sp:setCamera(camera)
    sp:setPosition3D(cc.V3(-1800,200,510))
    sp:setScale(3)
    sp:setVisible(true)
    sp:setGlobalZOrder(200)
    currentLayer:addChild(sp)--]]
end

--创建相机
local function setCamera()
    --创建透视相机
    camera = cc.Camera:createPerspective(60.0, size.width/size.height, 10.0, 4000.0)
    camera:setGlobalZOrder(10)
    --把camera对象添加到scene但中即可替代默认的camera(方向向量与 x,y 平面垂直)
    currentLayer:addChild(camera)

    for val = HeroManager.first, HeroManager.last do
        local sprite = HeroManager[val]
        if sprite._puff then
            sprite._puff:setCamera(camera)
        end
    end      
    --在相机上面加了UI层
    camera:addChild(uiLayer)
end

--核心控制游戏的地方
local function gameController(dt)
    gameMaster:update(dt)--负责刷怪、刷新对话框、提示等等
    moveHero(dt) --监听角色控制的移动,这个必须要放到collisionDetect(dt)前面，来保证角色移动之后，能检测是否出界
    collisionDetect(dt)--碰撞检测：由Manager.lua 来维护
	BloodbarUpdate(dt)
	ArrowUpdate(dt)
    solveAttacks(dt)--伤害计算：由attackCommand来维护
    moveCamera(dt)--移动相机
end

--初始化UI层
local function initUILayer()
    --创建战场层, uiLayer就是BattleFieldUI的一个实例
    uiLayer = require("BattleFieldUI").create()

    uiLayer:setPositionZ(-1 * cc.Director:getInstance():getZEye()/4)--getZEye获取到近平面的距离
    uiLayer:setScale(0.25)--设置UI的大小
    uiLayer:ignoreAnchorPointForPosition(false)
    uiLayer:setGlobalZOrder(5000)--确保UI盖在最上面
end

function BloodbarUpdate(dt)
	for val = HeroManager.first, HeroManager.last do
        local actor = HeroManager[val]
		local percent = actor._hp/actor._maxhp*100
        local progressTo = cc.ProgressTo:create(0.3,percent)
		local progressToClone = cc.ProgressTo:create(1,percent)
		bloodbarList[val]:setPercentage(percent)
		bloodbarList[val]:stopAllActions()
		bloodbarList[val]:setPosition3D(cc.V3(actor._myPos.x,actor._myPos.y,actor._heroHeight+10))
		--bloodbarList[val]:runAction(progressTo)
		-- bloodBarClone:setPercentage(percent)
		-- bloodBarClone:runAction(progressToClone)
    end
	for val = MonsterList.first, MonsterList.last do
        local actor = MonsterList[val]
		if actor._isalive then
			local percent = actor._hp/actor._maxhp*100
			local progressTo = cc.ProgressTo:create(0.3,percent)
			local progressToClone = cc.ProgressTo:create(1,percent)
			monsterBloodbarList[val]:setVisible(true)
			monsterBloodbarList[val]:setPercentage(percent)
			monsterBloodbarList[val]:stopAllActions()
			monsterBloodbarList[val]:setPosition3D(cc.V3(actor._myPos.x,actor._myPos.y,actor._heroHeight+10))
		else 
			monsterBloodbarList[val]:setVisible(false)
		end
    end
end
--初始化箭头和圈
function initArrowCircle(layer)
	--角色脚下的圈和箭头，放在这儿实现可以解决双摇杆操纵箭头方向的问题。
	layer.circle = cc.Sprite:createWithSpriteFrameName("circle.png")
    layer.circle:setScale(6.2)
	layer.circle:setOpacity(255*0.7)
	layer.circle:setGlobalZOrder(100)
	layer.circle:setVisible(false)
	layer:addChild(layer.circle)
	
	layer.arrow = cc.Sprite:createWithSpriteFrameName("arrow.png")
    layer.arrow:setScale(1.8)
	layer.arrow:setOpacity(255*0.7)
	layer.arrow:setAnchorPoint(0.05,0.5)
	layer.arrow:setGlobalZOrder(UIZorder - 1)
	layer.arrow:setVisible(false)
	layer:addChild(layer.arrow)
end

--更新圈和箭头的位置和方向
function ArrowUpdate(dt)
	for val = HeroManager.first, HeroManager.last do
        local actor = HeroManager[val]
		--可能会需要条件判断一下哪个角色是玩家控制的
		bloodbarLayer.circle:setPosition(actor:getPosition())
		bloodbarLayer.arrow:setPosition(actor:getPosition())
    end
end

--类定义
local BattleScene = class("BattleScene",function()
    return cc.Scene:create()
end)

local function bloodMinus(heroActor)
        uiLayer:bloodDrop(heroActor)
end

local function angryChange(angry)
        uiLayer:angryChange(angry)
end

--特效的时候，在当前层上面蒙一层灰色
local function specialPerspective(param)
    if specialCamera.valid == true then return end
    
    specialCamera.position = param.pos
    specialCamera.valid = true
    currentLayer:setColor(cc.c3b(125, 125, 125))--deep grey， color3 byte ＝ c3b

    local function restoreTimeScale()
        specialCamera.valid = false
        currentLayer:setColor(cc.c3b(255, 255, 255))--default white        
        cc.Director:getInstance():getScheduler():setTimeScale(1.0)
        param.target:setCascadeColorEnabled(true)--restore to the default state  
    end    
    delayExecute(currentLayer, restoreTimeScale, param.dur)

    cc.Director:getInstance():getScheduler():setTimeScale(param.speed)
end

--控制英雄行走
function BattleScene:enableTouch()
    local function onTouchBegin(touch,event)
        --根据摇杆，控制英雄行走方向
        if self:UIcontainsPoint(touch:getLocation()) == "JOYSTICK" then
            --让摇杆按钮的中心点随点击中心点移动
            uiLayer.JoystickBtn:setPosition(touch:getLocation())
            
            local touchPoint = cc.p(touch:getLocation().x, touch:getLocation().y)--getLocation返回的是table，两个属性x， y
            local joystickFrameCenter = cc.p(uiLayer.JoystickFrame:getPosition())--getPosition两个返回值的，第一个x， 第二个y
            
            local heroMoveDir = cc.pNormalize(cc.p(touchPoint.x - joystickFrameCenter.x, touchPoint.y - joystickFrameCenter.y))
            local heroMoveSpeed = 250 --设置玩家的移动速度
            for val = HeroManager.first, HeroManager.last do
                local sprite = HeroManager[val]
				if(sprite:getStateType()==EnumStateType.ATTACKING) then
					break;
				end
                sprite._heroMoveDir = heroMoveDir
                sprite._heroMoveSpeed = heroMoveSpeed
                if sprite:getStateType() ~= EnumStateType.WALKING then
                    sprite:walkMode()
                end
            end
        elseif self:UIcontainsPoint(touch:getLocation()) == "ATTACKBTN" then
            --玩家点击攻击按钮时,显示范围和箭头
			uiLayer.AttackRange:setVisible(true)
			uiLayer.AttackArrow:setVisible(true)
			
			--bloodbarLayer.circle:setVisible(true)
			bloodbarLayer.arrow:setVisible(true)
		elseif self:UIcontainsPoint(touch:getLocation()) == "BACK" then
			print("BACK")
			-- cc.Director:getInstance():endToLua()
			-- package.loaded["MainMenuScene"] = nil
			-- package.loaded["Helper"]=nil
			scheduler:unscheduleScriptEntry(gameControllerScheduleID)
			scheduler:unscheduleScriptEntry(uiLayer._tmSchedule)
			scheduler:unscheduleScriptEntry(updateScoreLabelScheduleID)
			scheduler:unscheduleScriptEntry(updateTimeLabelScheduleID)
			scheduler:unscheduleScriptEntry(checkWinOrLoseScheduleID)
			local scene = require("MainMenuScene")
            cc.Director:getInstance():replaceScene(scene.create())
        end
        return true
    end
    
    --玩家滑动改变相机的位置 self._weaponItem:setPosition(self._bag:convertToNodeSpace(touch:getLocation()))
    local function onTouchMoved(touch,event)
        if self:UIcontainsPoint(touch:getLocation()) == "JOYSTICK" then
            uiLayer.JoystickBtn:setPosition(touch:getLocation())
            
            local touchPoint = cc.p(touch:getLocation().x, touch:getLocation().y)
            local joystickFrameCenter = cc.p(uiLayer.JoystickFrame:getPosition())
            
            local heroMoveDir = cc.pNormalize(cc.p(touchPoint.x - joystickFrameCenter.x, touchPoint.y - joystickFrameCenter.y))
            local heroMoveSpeed = 250 --设置玩家的移动速度
            for val = HeroManager.first, HeroManager.last do
                local sprite = HeroManager[val]
				if(sprite:getStateType()==EnumStateType.ATTACKING) then
					break;
				end
                sprite._heroMoveDir = heroMoveDir
                sprite._heroMoveSpeed = heroMoveSpeed
                if sprite:getStateType() ~= EnumStateType.WALKING then
                    sprite:walkMode()
                end
            end
        elseif self:UIcontainsPoint(touch:getLocation()) == "ATTACKRANGE" or self:UIcontainsPoint(touch:getLocation()) == "ATTACKBTN"then
            --让技能摇杆箭头随手指移动
			--手指与圆心的方向
			local m = cc.p(touch:getLocation().x - uiLayer.AttackArrow:getPositionX(), 
							touch:getLocation().y - uiLayer.AttackArrow:getPositionY())
			--箭头初始方向
			local n = cc.p(1,0)
			--m，n间的弧度
			a = cc.pGetAngle(m,n)
			--弧度转成角度
			local b = 180 * a / 3.14
			uiLayer.AttackArrow:setRotation(b)
			bloodbarLayer.arrow:setRotation(b)
			
			uiLayer.label:setString("AttackBegin 1")
		end
        
        --不改变相机的视角
        --[[
        if self:UIcontainsPoint(touch:getLocation()) == nil then
            local delta = touch:getDelta()
            --因为是像滑动的反方向，所以是sub。通过pGetClampPoint限制位移的max和min。
            cameraOffset = cc.pGetClampPoint(cc.pSub(cameraOffset, delta),cameraOffsetMin,cameraOffsetMax)
        end
         --]]
    end
    
    local function onTouchEnded(touch,event)
        --松手之后，让英雄停止移动
        local location = touch:getLocation()
        local message = self:UIcontainsPoint(location)
		
		if message == "ATTACKBTN" or message == "ATTACKRANGE" then
		
			--松开手时，如果技能箭头可见，则说明应该释放技能
			if uiLayer.AttackRange:isVisible() then
				for val = HeroManager.first, HeroManager.last do
					local sprite = HeroManager[val]
					--将角色转向调为箭头方向
					local touchPoint = cc.p(touch:getLocation().x, touch:getLocation().y)
					local heroMoveDir = cc.pNormalize(cc.p(touchPoint.x - uiLayer.AttackBtn:getPositionX(), touchPoint.y - uiLayer.AttackBtn:getPositionY()))
					sprite._heroMoveDir = heroMoveDir
					--sprite._curFacing = heroMoveDir --_curFacing 是一个number， 不能用dir去赋值！
					sprite._heroMoveSpeed = 0
					--攻击
					uiLayer.label:setString("AttackBegin 2")
					sprite._attackTimer = 0
					if sprite:getStateType() ~= EnumStateType.ATTACKING then
						sprite:setStateType(EnumStateType.ATTACKING)
					end
				end
			end
			--重置技能UI为不可见
			uiLayer.AttackRange:setVisible(false)
			uiLayer.AttackArrow:setVisible(false)
			
			bloodbarLayer.circle:setVisible(false)
			bloodbarLayer.arrow:setVisible(false)

            --do nothing
        elseif message == "JOYSTICK" then
            --恢复按钮的位置
            uiLayer.JoystickBtn:setPosition(uiLayer.JoystickFrame:getPosition())
        
            for val = HeroManager.first, HeroManager.last do
                local sprite = HeroManager[val]
				if(sprite:getStateType()==EnumStateType.ATTACKING) then
					break
				end
                --sprite._heroMoveDir = heroMoveDir --方向不变
                sprite._heroMoveSpeed = 0 --速度变为0
                if sprite:getStateType() ~= EnumStateType.IDLE then
                    sprite:idleMode()
                end
            end
        elseif message ~= nil then
            --处理其他的消息，如
            MessageDispatchCenter:dispatchMessage(message, 1)
        elseif message == nil then
            --nil message
            --恢复按钮的位置
            uiLayer.JoystickBtn:setPosition(uiLayer.JoystickFrame:getPosition())
            for val = HeroManager.first, HeroManager.last do
                local sprite = HeroManager[val]
                --sprite._heroMoveDir = heroMoveDir --方向不变
                sprite._heroMoveSpeed = 0 --速度变为0
                if sprite:getStateType() ~= EnumStateType.IDLE then
                    sprite:idleMode()
                end
            end
        end
    end

    local touchEventListener = cc.EventListenerTouchOneByOne:create()
    
    touchEventListener:registerScriptHandler(onTouchBegin,cc.Handler.EVENT_TOUCH_BEGAN)
    touchEventListener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED)
    touchEventListener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED)
    
    currentLayer:getEventDispatcher():addEventListenerWithSceneGraphPriority(touchEventListener, currentLayer)        
end

--添加键盘监听事件
function BattleScene:enableKeyboard()
    cclog("enable kyeboard!")
    local function keyboardPressed(keyCode, event)
        cclog("key pressed")
    end
    
    local function keyboardReleased(keyCode, event)
        cclog("key released")
    end
    
    local keyboardEventListener = cc.EventListenerKeyboard:create()
    keyboardEventListener:registerScriptHandler(keyboardPressed, cc.Handler.EVENT_KEYBOARD_PRESSED)
    keyboardEventListener:registerScriptHandler(keyboardReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)
    currentLayer:getEventDispatcher():addEventListenerWithSceneGraphPriority(keyboardEventListener, currentLayer)
end

--根据点击的位置和怒气值，返回相应的消息
function BattleScene:UIcontainsPoint(position)
    local message  = nil

    --获取右下角的三个职业的小方块
    --local rectKnight = uiLayer.KnightPngFrame:getBoundingBox()
    --没有法师和射手了
    --local rectArcher = uiLayer.ArcherPngFrame:getBoundingBox()
    local rectMage = uiLayer.MagePngFrame:getBoundingBox()

    --[[
    if cc.rectContainsPoint(rectKnight, position) and uiLayer.KnightAngry:getPercentage() == 100 then
        --cclog("rectKnight")
        message = MessageDispatchCenter.MessageType.SPECIAL_KNIGHT        

    elseif cc.rectContainsPoint(rectArcher, position) and uiLayer.ArcherAngry:getPercentage() == 100  then
        --cclog("rectArcher")
        message = MessageDispatchCenter.MessageType.SPECIAL_ARCHER
     --]]
    if cc.rectContainsPoint(rectMage, position)  and uiLayer.MageAngry:getPercentage() == 100 then
        --cclog("rectMage")
        message = MessageDispatchCenter.MessageType.SPECIAL_MAGE
    end
    
    local rectJoystick = uiLayer.JoystickFrame:getBoundingBox()
	local rectJoystickRange = {x=0,y=0,width=size.width/2,height=size.height}
    local rectAttackBtn = uiLayer.AttackBtn:getBoundingBox()
    --local rectAttackRange = uiLayer.AttackRange:getBoundingBox() --新加的技能范围
	local rectAttackRange = {x=size.width/2,y=0,width=size.width/2,height=size.height}
	local rectBackBtn = uiLayer.BackBtn:getBoundingBox()
	
    if cc.rectContainsPoint(rectJoystick, position) then
        message = MessageDispatchCenter.MessageType.JOYSTICK
    elseif cc.rectContainsPoint(rectAttackBtn, position) then --到这了都是对的
        message = MessageDispatchCenter.MessageType.ATTACKBTN
	elseif cc.rectContainsPoint(rectBackBtn, position) then
		message = MessageDispatchCenter.MessageType.BACK
    elseif cc.rectContainsPoint(rectAttackRange, position) then --如果技能范围显示出来
		if uiLayer.AttackRange:isVisible() then
			message = MessageDispatchCenter.MessageType.ATTACKRANGE
		else
			message = nil
		end
	elseif cc.rectContainsPoint(rectJoystickRange, position) then --如果技能范围显示出来
		if uiLayer.AttackRange:isVisible() then
			message = MessageDispatchCenter.MessageType.JOYSTICKRANGE
		else
			message = nil
		end
	end
    
    return message 
end

--创建场景
function BattleScene.create()
    local scene = BattleScene:new()
	
	t = {}
	setmetatable(t, {__mode = "k"})
    --wei add, heros and monsters are both on currentLayer
    currentLayer = cc.Layer:create()
    currentLayer:setCascadeColorEnabled(true) --自节点能够随着父节点的颜色改变而改变
    scene:addChild(currentLayer)
	currentLayer:setGlobalZOrder(100)
	
    cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565)

    --监听触摸事件，这个可以仿照MainMenuScene:addButton 中使用另外一种更加高效的方式去实现
    scene:enableTouch()
    --监听键盘事件
    scene:enableKeyboard()
    
    --创建场景
    createBackground()
    
    initUILayer()
	--initBloodbarLayer()
	
	-- local sprite = cc.Sprite3D:create("minigame/maoRedoUv.c3b")
	-- sprite:setScale(7,42)
	-- sprite:setPosition3D(cc.V3(-2000,-500,30))
	-- sprite:setRotation3D(cc.V3(0,0,0))
	-- currentLayer:addChild(sprite,1,5)
	
	-- local sprite2 = cc.Sprite3D:create("minigame/maolianRedoUv.c3b")
	-- sprite2:setScale(1)
	-- sprite2:setPosition3D(cc.V3(-2300,-500,30))
	-- sprite2:setRotation3D(cc.V3(90,0,90))
	-- currentLayer:addChild(sprite2,1,5)
	
	-- local sprite3 = cc.Sprite3D:create("minigame/maoNEW.c3b")
	-- sprite3:setScale(1)
	-- sprite3:setPosition3D(cc.V3(-2500,-500,30))
	-- sprite3:setRotation3D(cc.V3(90,0,90))
	-- currentLayer:addChild(sprite3,1,5)
	
	-- local sprite4 = cc.Sprite3D:create("minigame/maolianNEW.c3b")
	-- sprite4:setScale(5)
	-- sprite4:setPosition3D(cc.V3(-2700,-500,30))
	-- sprite4:setRotation3D(cc.V3(90,0,90))
	-- currentLayer:addChild(sprite4,1,5)

	-- LEFT
	local sprite5 = cc.Sprite3D:create("minigame/maolianRedoUv.c3b")
	sprite5:setScale(10)
	sprite5:setPosition3D(cc.V3(G.activearea.left,G.activearea.bottom,100))
	sprite5:setRotation3D(cc.V3(90,0,0))
	sprite5:setVisible(false)
	currentLayer:addChild(sprite5,1,30)
	
	-- BOTTOM
	local sprite6 = cc.Sprite3D:create("minigame/maolianRedoUv.c3b")
	sprite6:setScale(10)
	sprite6:setPosition3D(cc.V3(G.activearea.left,G.activearea.bottom,100))
	sprite6:setRotation3D(cc.V3(90,0,90))
	sprite6:setVisible(false)
	currentLayer:addChild(sprite6,1,30)
	
	-- RIGHT
	local sprite7 = cc.Sprite3D:create("minigame/maolianRedoUv.c3b")
	sprite7:setScale(10)
	sprite7:setPosition3D(cc.V3(G.activearea.right,G.activearea.top,100))
	sprite7:setRotation3D(cc.V3(270,0,0))
	sprite7:setVisible(false)
	currentLayer:addChild(sprite7,1,30)
	
	-- TOP
	local sprite8 = cc.Sprite3D:create("minigame/maolianRedoUv.c3b")
	sprite8:setScale(10)
	sprite8:setPosition3D(cc.V3(G.activearea.right,G.activearea.top,100))
	sprite8:setRotation3D(cc.V3(270,0,90))
	sprite8:setVisible(false)
	currentLayer:addChild(sprite8,1,30)
	
	uiLayer.label = cc.Label:createWithTTF("Hello World","chooseRole/actor_param.ttf", 20)
	--label:setPosition(cc.p(size.width/2,size.height - label:getContentSize().height))
	uiLayer.label:setPosition(100, 500)
	uiLayer.label:setColor(cc.V3(255,0,0))
	uiLayer:addChild(uiLayer.label,1000)
	uiLayer.label:setVisible(false)
	
    --这句控制了各种角色的创建，包括英雄，怪物，道具等等
    gameMaster = require("GameMaster").create()
    
	bloodbarLayer = require("BloodbarUI").create()
    bloodbarLayer:setGlobalZOrder(3000)--确保UI盖在最上面
	bloodbarLayer:init()
	scene:addChild(bloodbarLayer)
	
	initArrowCircle(bloodbarLayer)
	
    setCamera()
    --这里每一帧都执行gamecontroller
    gameControllerScheduleID = scheduler:scheduleScriptFunc(gameController, 0, false)

    --逻辑对象层(骑士，法师，弓箭手)通过发送消息的方式来和UI层交互。
    --掉血函数
    MessageDispatchCenter:registerMessage(MessageDispatchCenter.MessageType.BLOOD_MINUS, bloodMinus)
    --怒气改变函数
    MessageDispatchCenter:registerMessage(MessageDispatchCenter.MessageType.ANGRY_CHANGE, angryChange)
    --当收到对应消息的时候，设置特写镜头
    MessageDispatchCenter:registerMessage(MessageDispatchCenter.MessageType.SPECIAL_PERSPECTIVE,specialPerspective)

    --开始游戏的时候显示说明的PopUp
    showStartPopup(uiLayer)
    
    return scene
end

return BattleScene
