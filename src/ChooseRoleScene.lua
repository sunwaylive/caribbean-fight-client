require "Actor"
require "Knight"
require "Archer"
require "Mage"

--tag 3hero:1~3
--tag bag:10 weapon:11 armour:12 helmet:13
--tag actorinfo:101 actortext:102

local ChooseRoleScene  = class("ChooseRoleScene",function ()
	return cc.Scene:create()
end)

local sortorder = {1,2,3} --hero's tag
local rtt = {{x=-90,y=-60,z=0},{x=-90,y=-70,z=0},{x=-90,y=-60,z=0}}
local visibleSize = cc.Director:getInstance():getVisibleSize()
local pos = {{x=visibleSize.width*0.14,y=visibleSize.height*0.35,z=-180},{x=visibleSize.width*0.34,y=visibleSize.height*0.25,z=-40},{x=visibleSize.width*0.5,y=visibleSize.height*0.35,z=-180}}
local weapon_item_pos = {x=832,y=280}
local armour_item_pos = {x=916,y=280}
local helmet_item_pos = {x=1000,y=280}
local isMoving = false
local direction = 0
local heroSize = cc.rect(155,120,465,420)


function ChooseRoleScene.create()
    local scene = ChooseRoleScene.new()
    cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_AUTO)    
    local layer = scene:createLayer()
    scene:addChild(layer)
    scene:initTouchDispatcher()
    AUDIO_ID.CHOOSEROLESCENEBGM = ccexp.AudioEngine:play2d(BGM_RES.CHOOSEROLESCENEBGM, true,1)
    return scene
end

function ChooseRoleScene:ctor()
    self.visibleSize = cc.Director:getInstance():getVisibleSize()
    self.origin = cc.Director:getInstance():getVisibleOrigin()
end

function ChooseRoleScene:addBag()
    local bag = cc.Sprite:createWithSpriteFrameName("cr_bag.png")
    bag:setTag(10)
    self._bag = bag
    self:switchTextWhenRotate()
    
    local bagSize = bag:getContentSize()
    weapon_item_pos = {x=bagSize.width*0.36,y=bagSize.height*0.4}
    armour_item_pos = {x=bagSize.width*0.54,y=bagSize.height*0.4}
    helmet_item_pos = {x=bagSize.width*0.72,y=bagSize.height*0.4}

    self._weaponItem = cc.Sprite:createWithSpriteFrameName("knight_w_1.png")
    self._weaponItem:setTag(11)
    self._weaponItem:setScale(1)
    self._weaponItem:setPosition(weapon_item_pos)
    bag:addChild(self._weaponItem,2)
    
    self._armourItem = cc.Sprite:createWithSpriteFrameName("knight_a_1.png")
    self._armourItem:setTag(12)
    self._armourItem:setScale(1)
    self._armourItem:setPosition(armour_item_pos)
    bag:addChild(self._armourItem,2)
    
    self._helmetItem = cc.Sprite:createWithSpriteFrameName("knight_h_1.png")
    self._helmetItem:setTag(13)
    self._helmetItem:setScale(1)
    self._helmetItem:setPosition(helmet_item_pos)
    bag:addChild(self._helmetItem,2)

    bag:setNormalizedPosition({x=0.75,y=0.5})
    bag:setScale(resolutionRate)
    
    self.layer:addChild(bag)
    
    return bag
end

--这个是三个英雄下面的按钮，点击进入游戏场景
function ChooseRoleScene:addButton()
    --button
    local touch_next = false
    --ReSkin 记录了装备穿戴情况
    local function touchEvent_next(sender,eventType)
        if touch_next == false then
            touch_next = true
            if eventType == ccui.TouchEventType.began then
                ReSkin.knight = {weapon = self.layer:getChildByTag(2):getWeaponID(),
                                 armour = self.layer:getChildByTag(2):getArmourID(),
                                 helmet = self.layer:getChildByTag(2):getHelmetID()}
                ReSkin.arhcer = {weapon = self.layer:getChildByTag(1):getWeaponID(),
                                 armour = self.layer:getChildByTag(1):getArmourID(),
                                 helmet = self.layer:getChildByTag(1):getHelmetID()}
                ReSkin.mage = {weapon = self.layer:getChildByTag(3):getWeaponID(),
                                 armour = self.layer:getChildByTag(3):getArmourID(),
                                 helmet = self.layer:getChildByTag(3):getHelmetID()}

                local playid = ccexp.AudioEngine:play2d(BGM_RES.MAINMENUSTART,false,1)
                --stop schedule
                cc.Director:getInstance():getScheduler():unscheduleScriptEntry(self._schedule_rotate)
                
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

    local next_Button = ccui.Button:create("button1.png","button2.png","",ccui.TextureResType.plistType)
    next_Button:setTouchEnabled(true)
    --设置button的位置
    next_Button:setNormalizedPosition({x=0.34,y=0.13})-- Node的位置像素会根据它的父节点的尺寸大小计算，即按比例
    next_Button:setScale(resolutionRate)
    
    next_Button:addTouchEventListener(touchEvent_next)        
    self.layer:addChild(next_Button)
end

function ChooseRoleScene:addHeros()
    local knight = Knight.create()
    knight:setTag(2)
    knight:setRotation3D(rtt[2])
    knight:setPosition3D(pos[2])
    knight:setAIEnabled(false)
    knight:setScale(1.3)
    self.layer:addChild(knight)

    local archer = Archer.create()
    archer:setTag(1)
    archer:setRotation3D(rtt[1])
    archer:setPosition3D(pos[1])
    archer:setAIEnabled(false)
    archer:setScale(1.3)
    archer:setVisible(false)--不显示射手
    self.layer:addChild(archer)

    local mage = Mage.create()
    mage:setTag(3)
    mage:setRotation3D(rtt[3])
    mage:setPosition3D(pos[3])
    mage:setAIEnabled(false)
    mage:setScale(1.3)
    mage:setVisible(false)--不显示法师
    self.layer:addChild(mage)
    
    --hero rotate, 旋转中间的英雄
    --setRotation3D，开启一个schedule每次旋转了0.5个弧度
    local rotate = 0.5
    local function hero_rotate()
        local rotation = self.layer:getChildByTag(sortorder[2]):getRotation3D()
        self.layer:getChildByTag(sortorder[2]):setRotation3D({x = rotation.x, y = rotation.y + rotate, z=0})
    end
    --设置调度器，每帧都执行
    self._schedule_rotate = cc.Director:getInstance():getScheduler():scheduleScriptFunc(hero_rotate,0,false)
end

function ChooseRoleScene:addBackground()
    -- Holder for background
    local node3d = cc.Sprite3D:create()

	local background = cc.Sprite:create("chooseRole/cr_bk.jpg")
    background:setAnchorPoint(0.5,0.5)
    background:setPosition(self.origin.x + self.visibleSize.width/2, self.origin.y + self.visibleSize.height/2)
    background:setPositionZ(-250)
    background:setScale(1.5)
    background:setGlobalZOrder(-1)
    node3d:addChild(background)
    self.layer:addChild(node3d)
end

function ChooseRoleScene:createLayer()
    
    --create layer
    self.layer = cc.Layer:create()
    
    --create Background
    self:addBackground()
           
    --create heros
    self:addHeros() 
    
    --create arrow
    self:addButton()    
    
    --create bag
    self:addBag()
    
    return self.layer
end

--分发触屏事件
function ChooseRoleScene:initTouchDispatcher()
    local isRotateavaliable = false
    local isWeaponItemavaliable = false
    local isArmourItemavaliable = false
    local isHelmetItemavaliable = false
    local touchbeginPt
    --初始化监听对象
    local listenner = cc.EventListenerTouchOneByOne:create()
    listenner:setSwallowTouches(true)
    --注册监听函数
    listenner:registerScriptHandler(function(touch, event)
        --获取点击的位置
        touchbeginPt = touch:getLocation()
        --如果点击到英雄，则旋转英雄
        if cc.rectContainsPoint(heroSize,touchbeginPt) then --rotate
            isRotateavaliable = true
            return true
        end
        --判断是否点到背包里面的装备
        touchbeginPt = self._bag:convertToNodeSpace(touchbeginPt) --需要将点击坐标转换到相对背包位置
                                    
        if cc.rectContainsPoint(self._weaponItem:getBoundingBox(), touchbeginPt) then --如果点到了weapon
            isWeaponItemavaliable = true
            --点到装备后，放大装备并且透明
            self._weaponItem:setScale(1.7)
            self._weaponItem:setOpacity(150)
                                    
        elseif cc.rectContainsPoint(self._armourItem:getBoundingBox(), touchbeginPt) then --如果点到了armour
            isArmourItemavaliable = true
            self._armourItem:setScale(1.7)
            self._armourItem:setOpacity(150)
        elseif cc.rectContainsPoint(self._helmetItem:getBoundingBox(), touchbeginPt) then --如果点到了helmet
            isHelmetItemavaliable = true
            self._helmetItem:setScale(1.7)
            self._helmetItem:setOpacity(150)
        end
        
        return true
    end,cc.Handler.EVENT_TOUCH_BEGAN)
    
    --处理鼠标按下移动的事件
    listenner:registerScriptHandler(function(touch, event)
                                    
        if isRotateavaliable == true and isMoving == false then --rotate
            local dist = touch:getLocation().x - touchbeginPt.x
            --如果滑动距离超过了50，就旋转英雄
            if dist>50 then
                --right
                self:rotate3Heroes(true)
                isRotateavaliable = false	
            elseif dist<-50 then
                --left
                self:rotate3Heroes(false)
                isRotateavaliable = false
            else
            end
        --如果是点击了装备，就是is***avaliable的话，就让装备随着鼠标一起移动
        elseif isWeaponItemavaliable then --weapon
            self._weaponItem:setPosition(self._bag:convertToNodeSpace(touch:getLocation()))
        elseif isArmourItemavaliable then --armour
            self._armourItem:setPosition(self._bag:convertToNodeSpace(touch:getLocation()))
        elseif isHelmetItemavaliable then --helmet
            self._helmetItem:setPosition(self._bag:convertToNodeSpace(touch:getLocation()))
        end
    end,cc.Handler.EVENT_TOUCH_MOVED )
    
    --松开手之后, 设置一些bool变量，替换装备等等
    listenner:registerScriptHandler(function(touch, event)
        if isRotateavaliable then --rotate
            isRotateavaliable = false
        elseif isWeaponItemavaliable then
            isWeaponItemavaliable = false
            self._weaponItem:setPosition(weapon_item_pos)
            self._weaponItem:setScale(1)
            self._weaponItem:setOpacity(255) --255 完全不透明
            --根据选中的武器，替换装备
            self.layer:getChildByTag(sortorder[2]):switchWeapon()
            self._weaponItem:setSpriteFrame(self:getWeaponTextureName())--得到另外一种武器纹理
        elseif isArmourItemavaliable then
            isArmourItemavaliable = false
            self._armourItem:setPosition(armour_item_pos)
            self._armourItem:setScale(1)
            self._armourItem:setOpacity(255)
            --替换护甲
            self.layer:getChildByTag(sortorder[2]):switchArmour()
            self._armourItem:setSpriteFrame(self:getArmourTextureName())
        elseif isHelmetItemavaliable then
            isHelmetItemavaliable = false
            self._helmetItem:setPosition(helmet_item_pos)
            self._helmetItem:setScale(1)
            self._helmetItem:setOpacity(255)
            --替换头盔
            self.layer:getChildByTag(sortorder[2]):switchHelmet()
            self._helmetItem:setSpriteFrame(self:getHelmetTextureName())
        end
    end,cc.Handler.EVENT_TOUCH_ENDED )
    
    --注册监听事件，在所在的层上面响应拖动事件
    local eventDispatcher = self.layer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listenner, self.layer)
end

--当鼠标拖动大于50的时候，旋转英雄
function ChooseRoleScene:rotate3Heroes(isRight)
    --stop hero rotate
    --从左向右依次为1 2 3
    if isRight then
        self.layer:getChildByTag(sortorder[2]):runAction(cc.RotateTo:create(0.1,rtt[3]))
    else
        self.layer:getChildByTag(sortorder[2]):runAction(cc.RotateTo:create(0.1,rtt[1]))
    end

    local rotatetime = 0.6
    if isRight then--如果是向右滑动
        local middle = self.layer:getChildByTag(sortorder[2])--2号是中间的hero， 移动到右边去
        
        middle:runAction(cc.Sequence:create(
            cc.CallFunc:create(function() isMoving = true end), 
            cc.Spawn:create(
                cc.EaseCircleActionInOut:create(cc.MoveTo:create(rotatetime,pos[3]))
            ),
            cc.CallFunc:create(function() 
                isMoving = false
                self:playAudioWhenRotate()
            end)))
        
        local left = self.layer:getChildByTag(sortorder[1])--1号是左边的hero， 移动到中间来
        left:runAction(cc.EaseCircleActionInOut:create(cc.MoveTo:create(rotatetime,pos[2])))
        
        local right = self.layer:getChildByTag(sortorder[3])--3号是右边的hero， 移动到左边去
        right:runAction(cc.EaseCircleActionInOut:create(cc.MoveTo:create(rotatetime,pos[1])))
        --移动后重新调整sortorder中的对象顺序
        local t = sortorder[3]
        sortorder[3]=sortorder[2]
        sortorder[2]=sortorder[1]
        sortorder[1]=t
    else
        local middle = self.layer:getChildByTag(sortorder[2])--2号是中间的hero， 移动到左边去
        --滑动动画
        middle:runAction(cc.Sequence:create(
            cc.CallFunc:create(function() 
                isMoving = true
            end), 
            cc.Spawn:create(
                cc.EaseCircleActionInOut:create(cc.MoveTo:create(rotatetime,pos[1]))
            ),
            cc.CallFunc:create(function()
                isMoving = false 
                self:playAudioWhenRotate()
            end)))
            
        local left = self.layer:getChildByTag(sortorder[1])--1号是左边的，移动到右边去
        left:runAction(cc.EaseCircleActionInOut:create(cc.MoveTo:create(rotatetime,pos[3])))
        
        local right = self.layer:getChildByTag(sortorder[3])--3号是右边的，移动到中间来
        right:runAction(cc.EaseCircleActionInOut:create(cc.MoveTo:create(rotatetime,pos[2])))
        --重新调整sortorder中英雄的顺序
        local t = sortorder[1]
        sortorder[1]=sortorder[2]
        sortorder[2]=sortorder[3]
        sortorder[3]=t
    end
    --移动的时候同时切换纹理和文字
    self:switchItemtextureWhenRotate()
    self:switchTextWhenRotate()
end

--得到另一种武器的纹理
function ChooseRoleScene:getWeaponTextureName()
    --获取中间位置的英雄
    local hero = self.layer:getChildByTag(sortorder[2])
    if hero._name == "Knight" then --warriors
        if hero:getWeaponID() == 0 then
            return "knight_w_1.png"
        elseif hero:getWeaponID() ==1 then
            return "knight_w_0.png"
        end
    elseif hero._name == "Archer" then --archer
        if hero:getWeaponID() == 0 then
            return "archer_w_1.png"
        elseif hero:getWeaponID() ==1 then
            return "archer_w_0.png"
        end
    elseif hero._name == "Mage" then --sorceress
        if hero:getWeaponID() == 0 then
            return "mage_w_1.png"
        elseif hero:getWeaponID() ==1 then
            return "mage_w_0.png"
        end
    end
end

--得到另一种护甲的纹理
function ChooseRoleScene:getArmourTextureName()
    local hero = self.layer:getChildByTag(sortorder[2])
    if hero._name == "Knight" then --warriors
        if hero:getArmourID() == 0 then
            return "knight_a_1.png"
        elseif hero:getArmourID() ==1 then
            return "knight_a_0.png"
        end
    elseif hero._name == "Archer" then --archer
        if hero:getArmourID() == 0 then
            return "archer_a_1.png"
        elseif hero:getArmourID() ==1 then
            return "archer_a_0.png"
        end
    elseif hero._name == "Mage" then --sorceress
        if hero:getArmourID() == 0 then
            return "mage_a_1.png"
        elseif hero:getArmourID() ==1 then
            return "mage_a_0.png"
        end
    end
end

--得到另一种头盔的纹理
function ChooseRoleScene:getHelmetTextureName()
    local hero = self.layer:getChildByTag(sortorder[2])
    if hero._name == "Knight" then --warriors
        if hero:getHelmetID() == 0 then
            return "knight_h_1.png"
        elseif hero:getHelmetID() ==1 then
            return "knight_h_0.png"
        end
    elseif hero._name == "Archer" then --archer
        if hero:getHelmetID() == 0 then
            return "archer_h_1.png"
        elseif hero:getHelmetID() ==1 then
            return "archer_h_0.png"
        end
    elseif hero._name == "Mage" then --sorceress
        if hero:getHelmetID() == 0 then
            return "mage_h_1.png"
        elseif hero:getHelmetID() ==1 then
            return "mage_h_0.png"
        end
    end
end

function ChooseRoleScene:switchItemtextureWhenRotate()
	local hero = self.layer:getChildByTag(sortorder[2])--获取中间的hero
	local xxx = sortorder[2]
	local weaponTexture
	local armourTexture
    local helmetTexture
	local type = hero:getRaceType();
	
    if hero._name == "Knight" then --warroir
	   if hero:getWeaponID() == 0 then
   	        weaponTexture = "knight_w_1.png"
   	   else
            weaponTexture = "knight_w_0.png"
	   end
       if hero:getArmourID() == 0 then
            armourTexture = "knight_a_1.png"
       else
            armourTexture = "knight_a_0.png"
       end
       if hero:getHelmetID() == 0 then
            helmetTexture = "knight_h_1.png"
       else
            helmetTexture = "knight_h_0.png"
       end
	end
	
    if hero._name == "Archer" then --archer
        if hero:getWeaponID() == 0 then
            weaponTexture = "archer_w_1.png"
        else
            weaponTexture = "archer_w_0.png"
        end
        if hero:getArmourID() == 0 then
            armourTexture = "archer_a_1.png"
        else
            armourTexture = "archer_a_0.png"
        end
        if hero:getHelmetID() == 0 then
            helmetTexture = "archer_h_1.png"
        else
            helmetTexture = "archer_h_0.png"
        end
    end
    
    if hero._name == "Mage" then --sorceress
        if hero:getWeaponID() == 0 then
            weaponTexture = "mage_w_1.png"
        else
            weaponTexture = "mage_w_0.png"
        end
        if hero:getArmourID() == 0 then
            armourTexture = "mage_a_1.png"
        else
            armourTexture = "mage_a_0.png"
        end
        if hero:getHelmetID() == 0 then
            helmetTexture = "mage_h_1.png"
        else
            helmetTexture = "mage_h_0.png"
        end
    end
    --用新的纹理去替换
	self._weaponItem:setSpriteFrame(weaponTexture)
    self._armourItem:setSpriteFrame(armourTexture)
    self._helmetItem:setSpriteFrame(helmetTexture)
end

--切换英雄信息展示，text
function ChooseRoleScene:switchTextWhenRotate()
    --get hero type
    local hero = self.layer:getChildByTag(sortorder[2])
    local type = hero:getRaceType()
    --get bag , bagSize and judge if has child
    local bag = self._bag
    local size = bag:getContentSize()
    local actor = bag:getChildByTag(101)
    
    if actor ~= nil then
        bag:removeChildByTag(101)
        bag:removeChildByTag(102)
    end
    
    --actor point
    local point = 0
    
    --label
    local ttfconfig = {outlineSize=0,fontSize=15,fontFilePath="chooseRole/actor_param.ttf"}
    local text = "LEVEL".."\n".."ATT".."\n".."HP".."\n".."DEF".."\n".."AGI".."\n".."CRT".."\n".."S.ATT"
    local attr = nil
    
    --set actor and label
    if hero._name == "Knight" then --warriors
        actor = cc.Sprite:createWithSpriteFrameName("knight.png")
        point = cc.p(size.width*0.395,size.height*0.9)
        --英雄属性展示
        attr = "23".."\n"..KnightValues._normalAttack.damage.."\n"..KnightValues._hp.."\n"..KnightValues._defense.."\n"..(KnightValues._AIFrequency*100).."\n"..KnightValues._specialAttack.damage.."\n"..KnightValues._specialAttack.damage
        
    elseif hero._name == "Archer" then --archer
        actor = cc.Sprite:createWithSpriteFrameName("archer.png")
        point = cc.p(size.width*0.4,size.height*0.905)
        attr = "23".."\n"..ArcherValues._normalAttack.damage.."\n"..ArcherValues._hp.."\n"..ArcherValues._defense.."\n"..(ArcherValues._AIFrequency*100).."\n"..ArcherValues._specialAttack.damage.."\n"..ArcherValues._specialAttack.damage
        
    elseif hero._name == "Mage" then --sorceress
        actor = cc.Sprite:createWithSpriteFrameName("mage.png")
        point = cc.p(size.width*0.38,size.height*0.9)
        attr = "23".."\n"..MageValues._normalAttack.damage.."\n"..MageValues._hp.."\n"..MageValues._defense.."\n"..(MageValues._AIFrequency*100).."\n"..MageValues._specialAttack.damage.."\n"..MageValues._specialAttack.damage
    end
    
    --add to bag
    actor:setPosition(point)
    --属性的名字，左边一列
    local text_label = cc.Label:createWithTTF(ttfconfig,text,cc.TEXT_ALIGNMENT_LEFT,400)
    text_label:setPosition(cc.p(size.width*0.45,size.height*0.68))
    text_label:enableShadow(cc.c4b(92,50,31,255),cc.size(1,-2),0)
    
    --就是那些数字， 右边一列
    local attr_label = cc.Label:createWithTTF(ttfconfig,attr,cc.TEXT_ALIGNMENT_RIGHT,400)
    attr_label:setPosition(cc.p(size.width*0.65,size.height*0.68))
    attr_label:enableShadow(cc.c4b(92,50,31,255),cc.size(1,-2),0)
    
    bag:addChild(actor,1,101)
    bag:addChild(text_label,1)
    bag:addChild(attr_label,1,102)
end

function ChooseRoleScene:playAudioWhenRotate()
	
    local hero = self.layer:getChildByTag(sortorder[2])
    local type = hero:getRaceType()
    if hero._name == "Knight" then
        ccexp.AudioEngine:play2d(WarriorProperty.kickit, false,1)
    elseif hero._name == "Archer" then
        ccexp.AudioEngine:play2d(Archerproperty.iwillfight, false,1)
    elseif hero._name == "Mage" then
        ccexp.AudioEngine:play2d(MageProperty.letstrade, false,1)
    end
end

return ChooseRoleScene