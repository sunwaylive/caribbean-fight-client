require "Helper"
require "GlobalVariables"

isShowingNewbie = false

--declare a class extends scene
local MainMenuScene = class("MainMenuScene",function()
    return cc.Scene:create()
end
)

--constructor init member variable
function MainMenuScene:ctor()
    --get win size
    self.size = cc.Director:getInstance():getVisibleSize()
    self._isBloodLabelShowing = false
    math.randomseed(os.time())
    ccexp.AudioEngine:stopAll()
    AUDIO_ID.MAINMENUBGM = ccexp.AudioEngine:play2d(BGM_RES.MAINMENUBGM, true,1)
end

function MainMenuScene.create()
    local scene = MainMenuScene.new()
    --add layer
    local layer = scene:createLayer()
    scene:addChild(layer)
    
    return scene
end

--crate a main layer
function MainMenuScene:createLayer()
    local mainLayer = cc.Layer:create()
    cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_AUTO)
    --add bg
    self:addBg(mainLayer)
    
    --add cloud
    self:addCloud(mainLayer)
    
    --add logo
    --self:addLogo(mainLayer)
    
    --add pointlight
    self:addPointLight(mainLayer)
    
    --add button
    self:addButton(mainLayer)
        
    --when replease scene unschedule schedule
    local function onExit(event)
        if "exit" == event then
            --cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.logoSchedule)
            cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self.scheduleCloudMove)
        end
    end
    mainLayer:registerScriptHandler(onExit)
    
    return mainLayer
end

--现在不加这个了
function MainMenuScene:addLogo(layer)
    --add logo
    local logo = cc.EffectSprite:create("mainmenuscene/logo.png")
    self._logoSize = logo:getContentSize()
    logo:setPosition(self.size.width*0.53,self.size.height*0.55)
    logo:setScale(0.1)
    self._logo = logo
    layer:addChild(logo,4)
    
    local action = cc.EaseElasticOut:create(cc.ScaleTo:create(2,1.1))
    
    logo:runAction(action)
    
    --logo shake
    local time = 0
    --logo animation
    local function logoShake()
        --rand_n = range * math.sin(math.rad(time*speed+offset))
        local rand_x = 0.1*math.sin(math.rad(time*0.5+4356))
        local rand_y = 0.1*math.sin(math.rad(time*0.37+5436)) 
        local rand_z = 0.1*math.sin(math.rad(time*0.2+54325))
        logo:setRotation3D({x=math.deg(rand_x),y=math.deg(rand_y),z=math.deg(rand_z)})
        time = time+1
    end
    self.logoSchedule = cc.Director:getInstance():getScheduler():scheduleScriptFunc(logoShake,0,false)
end

function MainMenuScene:getLightSprite()
    self._lightSprite = cc.Sprite:createWithSpriteFrameName("light.png")
    self._lightSprite:setBlendFunc(gl.ONE,gl.ONE_MINUS_SRC_ALPHA)
    self._lightSprite:setScale(1.2)
    
    self._lightSprite:setPosition3D(cc.vec3(self.size.width*0.5,self.size.height*0.5,0))
    local light_size = self._lightSprite:getContentSize()
    local rotate_top = cc.RotateBy:create(0.05,50)
    local rotate_bottom = cc.RotateBy:create(0.05,-50)
    local origin_degree = 20
    local sprite_scale = 0
    local opacity = 100
    local scale_action = cc.ScaleTo:create(0.07,0.7)
    
    local swing_l1 = cc.Sprite:createWithSpriteFrameName("swing_l1.png")
    swing_l1:setScale(sprite_scale)
    swing_l1:setAnchorPoint(cc.p(1,0))
    swing_l1:setPosition(light_size.width/2,light_size.height/2)
    swing_l1:setRotation(-origin_degree)
    swing_l1:setOpacity(opacity)
    swing_l1:setBlendFunc(gl.ONE , gl.ONE)
    self._lightSprite:addChild(swing_l1,5)
    
    local swing_l2 = cc.Sprite:createWithSpriteFrameName("swing_l2.png")
    swing_l2:setAnchorPoint(cc.p(1,1))
    swing_l2:setScale(sprite_scale)
    swing_l2:setPosition(light_size.width/2,light_size.height/2)
    swing_l2:setRotation(origin_degree)
    swing_l2:setOpacity(opacity)
    self._lightSprite:addChild(swing_l2,5)
    
    local swing_r1 = cc.Sprite:createWithSpriteFrameName("swing_r1.png")
    swing_r1:setAnchorPoint(cc.p(0,0))
    swing_r1:setScale(sprite_scale)
    swing_r1:setPosition(light_size.width/2,light_size.height/2)
    swing_r1:setRotation(origin_degree)
    swing_r1:setOpacity(opacity)
    swing_r1:setBlendFunc(gl.ONE , gl.ONE)
    self._lightSprite:addChild(swing_r1,5)
    
    local swing_r2 = cc.Sprite:createWithSpriteFrameName("swing_r2.png")
    swing_r2:setAnchorPoint(cc.p(0,1))
    swing_r2:setScale(sprite_scale)
    swing_r2:setPosition(light_size.width/2,light_size.height/2)
    swing_r2:setRotation(-origin_degree)
    swing_r2:setOpacity(opacity)
    self._lightSprite:addChild(swing_r2,5)
    
    --runaction
    local sequence_l1 = cc.Sequence:create(rotate_top,rotate_top:reverse())
    local sequence_r1 = cc.Sequence:create(rotate_top:reverse():clone(),rotate_top:clone())
    local sequence_l2 = cc.Sequence:create(rotate_bottom,rotate_bottom:reverse())
    local sequence_r2 = cc.Sequence:create(rotate_bottom:reverse():clone(),rotate_bottom:clone())
    swing_l1:runAction(cc.RepeatForever:create(cc.Spawn:create(sequence_l1,scale_action)))
    swing_r1:runAction(cc.RepeatForever:create(cc.Spawn:create(sequence_r1,scale_action)))
    swing_l2:runAction(cc.RepeatForever:create(cc.Spawn:create(sequence_l2,scale_action)))
    swing_r2:runAction(cc.RepeatForever:create(cc.Spawn:create(sequence_r2,scale_action)))
end

--add pointlight
function MainMenuScene:addPointLight(layer)
    --add pointlight
    self._pointLight = cc.PointLight:create(cc.vec3(0,0,-100),cc.c3b(255,255,255),10000)
    self._pointLight:setCameraMask(1)
    self._pointLight:setEnabled(true)

    --add lightsprite
    self:getLightSprite()
    self._lightSprite:addChild(self._pointLight)
    self:addChild(self._lightSprite,10)
    self._lightSprite:setPositionZ(100)
    
    --action
    local function getBezierAction()
        local bezierConfig1 = {
            cc.p(self.size.width*0.9,self.size.height*0.4),
            cc.p(self.size.width*0.9,self.size.height*0.8),
            cc.p(self.size.width*0.5,self.size.height*0.8)
        }
        local bezierConfig2 = {
            cc.p(self.size.width*0.1,self.size.height*0.8),
            cc.p(self.size.width*0.1,self.size.height*0.4),
            cc.p(self.size.width*0.5,self.size.height*0.4)
        }
        local bezier1 = cc.BezierTo:create(5,bezierConfig1)
        local bezier2 = cc.BezierTo:create(5,bezierConfig2)
        local bezier = cc.Sequence:create(bezier1,bezier2)

        return bezier
    end
    self._lightSprite:runAction(cc.RepeatForever:create(getBezierAction()))
    
    --touch eventlistener
    local function onTouchBegin(touch,event)
        self._lightSprite:stopAllActions()
        
        local location = touch:getLocation()
        self._prePosition = location

        local function movePoint(dt)
            local lightSpritePos = getPosTable(self._lightSprite)
            local point = cc.pLerp(lightSpritePos,self._prePosition,dt*2)
            self._lightSprite:setPosition(point)
            local z = math.sin(math.rad(math.random(0,2*math.pi)))*100+100
            --self._lightSprite:setPositionZ(z)
        end
        self._scheduleMove = cc.Director:getInstance():getScheduler():scheduleScriptFunc(movePoint,0,false)
        
        return true
    end
    local function onTouchMoved(touch,event)
        --again set prePosition
        local location = touch:getLocation()
        self._prePosition = location
        
        self._angle =cc.pToAngleSelf(cc.pSub(location,getPosTable(self._lightSprite)))
    end
    local function onTouchEnded(touch,event)
        --unschedule and stop action
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self._scheduleMove)
        self._lightSprite:stopAllActions()
        --self._lightSprite:setPositionZ(100)
        self._lightSprite:runAction(cc.RepeatForever:create(getBezierAction()))      
    end
    
    --add event listener
    local touchEventListener = cc.EventListenerTouchOneByOne:create()
    touchEventListener:registerScriptHandler(onTouchBegin,cc.Handler.EVENT_TOUCH_BEGAN)
    touchEventListener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED)
    touchEventListener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED)
    layer:getEventDispatcher():addEventListenerWithSceneGraphPriority(touchEventListener,layer)
end

--add pve and pvp button to start game
function MainMenuScene:addButton(layer)
    --step1: 设置PVE start 的按钮
    local isTouchButtonPVE = false
    --可以设置按钮的响应函数
    local button_callback_pve = function(sender,eventType)
        if isTouchButtonPVE == false then
            isTouchButtonPVE = true
            if eventType == ccui.TouchEventType.began then
                ccexp.AudioEngine:play2d(BGM_RES.MAINMENUSTART, false,1)
                ccexp.AudioEngine:stop(AUDIO_ID.MAINMENUBGM)
                -- --替换场景
            	-- cc.Director:getInstance():replaceScene(require("ChooseRoleScene").create())
				--replace scene， 跳转之前清空对象
                package.loaded["BattleScene"]=nil
                package.loaded["Manager"]=nil
                package.loaded["Helper"]=nil
                package.loaded["MessageDispatchCenter"]=nil
                package.loaded["BattleFieldUI"]=nil
                --进入战斗场景
                local scene = require("BattleScene")
                cc.Director:getInstance():replaceScene(scene.create())
            end
        end
    end

    --local buttonPVE = ccui.Button:create("pve_start.png","","",ccui.TextureResType.plistType)
    local buttonPVE = ccui.Button:create("mainmenuscene/pve_start_2.png")
    buttonPVE:setPosition(self.size.width*0.5 - 200,self.size.height*0.15 - 5)
    buttonPVE:setScale(1.0)
    --用这种方式添加按钮响应函数
    buttonPVE:addTouchEventListener(button_callback_pve)
    layer:addChild(buttonPVE,4)

    --step2: 设置PVP start的按钮
    local isTouchButtonPVP = false
    local button_callback_pvp = function(sender, eventType)
        if isTouchButtonPVP == false then
            isTouchButtonPVP = true
            if eventType == ccui.TouchEventType.began then
                ccexp.AudioEngine:play2d(BGM_RES.MAINMENUSTART, false, 1)
                ccexp.AudioEngine:stop(AUDIO_ID.MAINMENUBGM)
                --替换场景,这里需要进入PVP的场景
                cc.Director:getInstance():replaceScene(require("PVPMainScene").create())
            end
        end
    end

    --local buttonPVP = ccui.Button:create("pvp_start.png","","",ccui.TextureResType.plistType)
    local buttonPVP = ccui.Button:create("mainmenuscene/pvp_start_2.png")
    buttonPVP:setScale(1.0)
    buttonPVP:setPosition(self.size.width*0.5 + 200 ,self.size.height*0.15 - 5)
    --用这种方式添加按钮响应函数
    buttonPVP:addTouchEventListener(button_callback_pvp)
    layer:addChild(buttonPVP,4)
	
	--step3: 退出按钮
	local isTouchButtonClose = false
    local button_callback_close = function(sender, eventType)
        if isTouchButtonClose == false then
            isTouchButtonClose = true
            if eventType == ccui.TouchEventType.began then
                ccexp.AudioEngine:play2d(BGM_RES.MAINMENUSTART, false, 1)
                ccexp.AudioEngine:stop(AUDIO_ID.MAINMENUBGM)
                -- 退出
                cc.Director:getInstance():endToLua()
            end
        end
    end

    --local buttonClose = ccui.Button:create("close.png","","",ccui.TextureResType.plistType)
    local buttonClose = ccui.Button:create("mainmenuscene/close.png")
    buttonClose:setPosition(self.size.width - 100 ,self.size.height-70)
    buttonClose:setScale(0.4)
    --用这种方式添加按钮响应函数
    buttonClose:addTouchEventListener(button_callback_close)
    layer:addChild(buttonClose,4)

    --step3: 新手指引
    local isTouchButtonNewbie = false
    local button_callback_newbie = function(sender, eventType)
        if isTouchButtonNewbie == false then
            --isTouchButtonNewbie = true
            if eventType == ccui.TouchEventType.began then
                ccexp.AudioEngine:play2d(BGM_RES.MAINMENUSTART, false, 1)
                --ccexp.AudioEngine:stop(AUDIO_ID.MAINMENUBGM)
                -- 弹出新手指引
                if not isShowingNewbie then
                    isShowingNewbie = true
                    self:showNewbiePopup()
                else
                    --do nothing
                end
            end
        end
    end

    --local buttonClose = ccui.Button:create("close.png","","",ccui.TextureResType.plistType)
    local buttonNewbie = ccui.Button:create("mainmenuscene/newbie_pic.png")
    buttonNewbie:setPosition(self.size.width * 0.5 ,self.size.height * 0.5)
    buttonNewbie:setScale(0.6)
    --用这种方式添加按钮响应函数
    buttonNewbie:addTouchEventListener(button_callback_newbie)
    layer:addChild(buttonNewbie,4)
end

function MainMenuScene:showNewbiePopup()
    --color layer
    local layer = cc.LayerColor:create(cc.c4b(10,10,10,150))
    layer:ignoreAnchorPointForPosition(false)
    layer:setPosition3D(cc.V3(G.winSize.width*0.5,G.winSize.height*0.5,0))
    
    --add newbie_1
    local newbie_1 = cc.Sprite:createWithSpriteFrameName("newbie_1.jpg")
    newbie_1:setPosition3D(cc.V3(G.winSize.width*0.5,G.winSize.height*0.5,3))
    newbie_1:setScale(0.1)
    newbie_1:setGlobalZOrder(UIZorder)
    layer:addChild(newbie_1,3)
    
    --add newbie_2
    local newbie_2 = cc.Sprite:createWithSpriteFrameName("newbie_2.png")
    newbie_2:setPosition3D(cc.V3(G.winSize.width*0.5,G.winSize.height*0.5,3))
    newbie_2:setScale(0.1)
    newbie_2:setGlobalZOrder(UIZorder)
    layer:addChild(newbie_2,2)
    
    --add newbie_3
    local newbie_3 = cc.Sprite:createWithSpriteFrameName("newbie_3.png")
    newbie_3:setPosition3D(cc.V3(G.winSize.width*0.5,G.winSize.height*0.5,3))
    newbie_3:setScale(0.1)
    newbie_3:setGlobalZOrder(UIZorder)
    layer:addChild(newbie_3,1)
    
    --run action
    local touchCnt = 0
    local action_1 = cc.EaseElasticOut:create(cc.ScaleTo:create(1.5,0.8))
    newbie_1:runAction(action_1)
    
    --touch event
    local function onTouchBegan(touch, event)
        return true
    end
    
    local function onTouchEnded(touch,event)
        touchCnt = touchCnt + 1        
        cclog("touchCnt: " .. touchCnt)
        if touchCnt == 1 then
            cclog("1")
            newbie_1:stopAllActions()
            newbie_1:setVisible(false)
            layer:removeChild(newbie_1)
            local action_2 = cc.EaseElasticOut:create(cc.ScaleTo:create(1.5,0.8))
            newbie_2:runAction(action_2)
        elseif touchCnt == 2 then
            cclog("2")
            newbie_2:stopAllActions()
            newbie_2:setVisible(false)
            layer:removeChild(newbie_2)
            local action_3 = cc.EaseElasticOut:create(cc.ScaleTo:create(1.5,0.8))
            newbie_3:runAction(action_3)
        elseif touchCnt == 3 then
            cclog("3")
            newbie_3:stopAllActions()
            newbie_3:setVisible(false)
            layer:removeChild(newbie_3)
            layer:setVisible(false)
            self:removeChild(layer)
            isShowingNewbie = false
        end
    end
    
    local listener = cc.EventListenerTouchOneByOne:create() --单点触摸事件
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchEnded,cc.Handler.EVENT_TOUCH_ENDED )
    local eventDispatcher = layer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener,layer)
    
    self:addChild(layer)
end


-- cloud action
function MainMenuScene:addCloud(layer)
    --cloud
    local cloud0 = cc.Sprite:create("mainmenuscene/cloud1.png")--cc.Sprite:createWithSpriteFrameName("cloud1.png")
    local cloud1 = cc.Sprite:create("mainmenuscene/cloud1.png")--cc.Sprite:createWithSpriteFrameName("cloud1.png")
    local cloud3 = cc.Sprite:create("mainmenuscene/cloud2.png")--cc.Sprite:createWithSpriteFrameName("cloud2.png")
    
    --setScale
    local scale = 2
    cloud0:setScale(scale)
    cloud1:setScale(scale)
    cloud3:setScale(scale)
    
    --setPosition
    cloud0:setPosition(self.size.width*1.1,self.size.height*0.9)
    cloud1:setPosition(self.size.width*0.38,self.size.height*0.6)
    cloud3:setPosition(self.size.width*0.95,self.size.height*0.5)
    
    --add to layer
    layer:addChild(cloud0,2)
    layer:addChild(cloud1,2)
    layer:addChild(cloud3,2)
    local clouds = {cloud0,cloud1,cloud3}
    
    --move cloud
    local function cloud_move()
        --set cloud move speed
        local offset = {-0.5,-1.0,-1.2}
        for i,v in pairs(clouds) do
            local point = v:getPositionX()+offset[i]
            if(point<-v:getContentSize().width*scale/2) then
                point = self.size.width+v:getContentSize().width*scale/2
            end
            v:setPositionX(point)
        end
    end
    self.scheduleCloudMove = cc.Director:getInstance():getScheduler():scheduleScriptFunc(cloud_move,1/60,false)
end

--bg
function MainMenuScene:addBg(layer)
    --background
    local bg_back = cc.Sprite:create("mainmenuscene/bg.png")
    bg_back:setPosition(self.size.width/2,self.size.height/2)
    layer:addChild(bg_back,1)
end

return MainMenuScene