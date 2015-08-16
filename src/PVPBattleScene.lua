require "Helper"
require "Manager"
require "MessageDispatchCenter"
require "BloodbarUI"
require "PVPMainScene"

bloodbarLayer = nil
currentLayer = nil
uiLayer = nil
pvpGameMaster = nil
circle = nil
arrow = nil
t = nil
isGameStart = false


local specialCamera = {valid = false, position = cc.p(0,0)}
local size = cc.Director:getInstance():getWinSize()
local scheduler = cc.Director:getInstance():getScheduler()
local cameraOffset =  cc.V3(0 * 0.5, -800 * 0.5, 300 * 0.5)
local cameraOffsetMin = {x=-300, y=-400}
local cameraOffsetMax = {x=300, y=400}

local totalTime = 0.0
local receiveDataFrq = 0.2


--TODO:对接受到的数据，分类处理
local function handleMessage(msg)
    if msg == nil then return end
    
    local msg_token = mysplit(msg, '#')
    if msg_token == nil then return end
    --for i, v in ipairs(msg_token) do
    --cclog("value is: " .. v)
    --end
end

--包括： 所有玩家的位置 和 朝向； 玩家目前的状态(攻击， walk)
local function onReceiveData()
    if client_socket == nil then return end
    
    back, err, partial = client_socket:receive("*l")
    if err ~= "closed" then
        if back then
            handleMessage(back) --核心处理消息的函数
        end
    else
        cclog("TCP Connection is closed!")
        client_socket = nil --if tcp is dis-connect
        return
    end
end


local function onSendData()
   if client_socket ~= nil then
       msg = "StartGame\n"
       
       --r, e = client_socket:send(msg)
       if r == nil then
           cclog("ERROR: I can't send data to Server: " .. e)
       else
            --cclog("sent successfully!")
       end
   else
        cclog("Error: Tcp socket is dis-connect!")
   end   
   --TODO:打包当前玩家的数据，发送给服务器，然后由服务器转发
   --client_socket:send()
end


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
        local temp = cc.V3(focusPoint.x + cameraOffset.x, cameraOffset.y + focusPoint.y - size.height * 3 / 4)
        local position = cc.V3(temp.x, temp.y, size.height / 2 - 100 + 700)
        camera:setPosition3D(position)
        camera:lookAt(cc.V3(position.x, focusPoint.y + 500, 50.0), cc.V3(0.0, 0.0, 1.0)) --TODO: 要调整相机的视角，可以修改cameraOffset！！！
        --cclog("\ncalf %f %f %f \ncalf %f %f 50.000000", position.x, position.y, position.z, focusPoint.x, focusPoint.y)            
    end
end

--不需要在这里接受服务器端的数据，这里只负责更具玩家的朝向计算下一个位置
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
        if sprite ~= nil and sprite:getStateType() == EnumStateType.ATTACKING then
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

--设置主场景中的地图和背景
local function createBackground()
    --local spriteBg = cc.Sprite3D:create("model/scene/changing.c3b")
    local spriteBg = cc.Sprite3D:create("model/scene/BackGround.c3t")

    currentLayer:addChild(spriteBg)
    spriteBg:setScale(2000) --要放很大，不然看不见
    spriteBg:setPosition3D(cc.V3(-2300,-1000,0))
    spriteBg:setRotation3D(cc.V3(90,0,0)) --添加了地图的旋转
    spriteBg:setGlobalZOrder(-10)

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
--TODO:这里应该从服务器拿到数据，更新客户端，其他玩家的状态
local function gameController(dt)
    --设置时间间隔，每隔一定的时间接受从服务器过来的数据，更新其它玩家的状态;并向服务器发送自己的状态
    totalTime = totalTime + dt
    if totalTime > receiveDataFrq then
        --onReceiveData()
        --onSendData()
        totalTime = totalTime - receiveDataFrq
    end
    
    pvpGameMaster:update(dt)--负责刷怪、刷新对话框、提示等等
    
    moveHero(dt) --监听角色控制的移动,这个必须要放到collisionDetect(dt)前面，来保证角色移动之后，能检测是否出界
    
    collisionDetect(dt)--碰撞检测：由Manager.lua 来维护
    BloodbarUpdate(dt)
    ArrowUpdate(dt)
    solveAttacks(dt)--伤害计算：由attackCommand来维护
    moveCamera(dt)--移动相机
    -- local count = 000000
    -- for i, val in pairs(t) do
    -- count = count + 1
    -- end
    -- print(count)
end

--初始化UI层
local function initUILayer()
    --创建战场层, uiLayer就是BattleFieldUI的一个实例
    uiLayer = require("PVPBattleFieldUI").create()

    uiLayer:setPositionZ(-1 * cc.Director:getInstance():getZEye()/4)--getZEye获取到近平面的距离
    uiLayer:setScale(0.25)--设置UI的大小
    uiLayer:ignoreAnchorPointForPosition(false)
    uiLayer:setGlobalZOrder(3000)--确保UI盖在最上面
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
	layer.circle:setGlobalZOrder(1)
	layer.circle:setVisible(false)
	layer:addChild(layer.circle)
	
	layer.arrow = cc.Sprite:createWithSpriteFrameName("arrow.png")
    layer.arrow:setScale(2.2)
	layer.arrow:setOpacity(255*0.7)
	layer.arrow:setAnchorPoint(0.05,0.5)
	layer.arrow:setGlobalZOrder(1)
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
local PVPBattleScene = class("PVPBattleScene",function()
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
function PVPBattleScene:enableTouch()
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
        elseif self:UIcontainsPoint(touch:getLocation()) == "ATTACKRANGE" then
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

		--松开手时，如果技能箭头可见，则说明应该释放技能
		if uiLayer.AttackRange:isVisible() then
			for val = HeroManager.first, HeroManager.last do
                local sprite = HeroManager[val]
				--将角色转向调为箭头方向
				local touchPoint = cc.p(touch:getLocation().x, touch:getLocation().y)
				local heroMoveDir = cc.pNormalize(cc.p(touchPoint.x - uiLayer.AttackBtn:getPositionX(), touchPoint.y - uiLayer.AttackBtn:getPositionY()))
				sprite._heroMoveDir = heroMoveDir
				sprite._curFacing = heroMoveDir
				sprite._heroMoveSpeed = 0
				--攻击
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
	
        if message == "ATTACKBTN" then
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
				--print("stop walking")
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
function PVPBattleScene:enableKeyboard()
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
function PVPBattleScene:UIcontainsPoint(position)
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
    local rectAttackBtn = uiLayer.AttackBtn:getBoundingBox()
    local rectAttackRange = uiLayer.AttackRange:getBoundingBox() --新加的技能范围
	
    if cc.rectContainsPoint(rectJoystick, position) then
        message = MessageDispatchCenter.MessageType.JOYSTICK
    elseif cc.rectContainsPoint(rectAttackBtn, position) then --到这了都是对的
        message = MessageDispatchCenter.MessageType.ATTACKBTN
    elseif cc.rectContainsPoint(rectAttackRange, position) then --如果技能范围显示出来
		if uiLayer.AttackRange:isVisible() then
			message = MessageDispatchCenter.MessageType.ATTACKRANGE
		else
			message = nil
		end
	end
    
    return message 
end

--创建场景
function PVPBattleScene.create(sg_msg)
    local scene = PVPBattleScene:new()
    
	t = {}
	setmetatable(t, {__mode = "k"})
    
    --wei add, heros and monsters are both on currentLayer
    currentLayer = cc.Layer:create()
    currentLayer:setCascadeColorEnabled(true) --自节点能够随着父节点的颜色改变而改变
    scene:addChild(currentLayer)

    cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_RG_B565)

    --监听触摸事件，这个可以仿照MainMenuScene:addButton 中使用另外一种更加高效的方式去实现
    scene:enableTouch()
    --监听键盘事件
    scene:enableKeyboard()
    
    --创建场景
    createBackground()
    
    initUILayer()
	--initBloodbarLayer()
	
	local sprite = cc.Sprite3D:create("minigame/mao.c3b")
	sprite:setScale(3)
	sprite:setPosition3D(cc.V3(-2000,-500,30))
	sprite:setRotation3D(cc.V3(90,0,0))
	currentLayer:addChild(sprite,1,5)
	
	local sprite2 = cc.Sprite3D:create("minigame/maolianNEW.c3b")
	sprite2:setScale(3)
	sprite2:setPosition3D(cc.V3(-2200,-500,30))
	sprite2:setRotation3D(cc.V3(90,0,90))
	currentLayer:addChild(sprite2,1,5)
    
    pvpGameMaster = require("PVPGameMaster").create(sg_msg)
    
	bloodbarLayer = require("BloodbarUI").create()
    bloodbarLayer:setGlobalZOrder(2000)--确保UI盖在最上面
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

    return scene
end

return PVPBattleScene
