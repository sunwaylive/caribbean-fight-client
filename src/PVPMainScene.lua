local PVPMainScene  = class("PVPMainScene",function ()
return cc.Scene:create()
end)

--constructor init member variable
function PVPMainScene:ctor()
    --get win size
    self.size = cc.Director:getInstance():getVisibleSize()
end

function PVPMainScene.create()
    local scene = PVPMainScene.new()
    local layer = scene:createLayer()
    scene:addChild(layer)
    return scene
end

function PVPMainScene:createLayer()
    --create layer
    local layer = cc.Layer:create()

    --添加 创建房间,以及返回上一层的按钮
    self:addCreateRoomBtn(layer)
    self:addBackBtn(layer)

    return layer
end


function PVPMainScene:addCreateRoomBtn(layer)
    --step1: 添加 创建房间的按钮
    local isTouchButtonCreateRoom = false
    local button_callback_createroom = function(sender, eventType)
        --确保这个按钮只被点击了一次
        if isTouchButtonCreateRoom == false then
            isTouchButtonCreateRoom = true
            if eventType == ccui.TouchEventType.began then
                ccexp.AudioEngine:play2d(BGM_RES.MAINMENUSTART, false, 1)
                ccexp.AudioEngine:stop(AUDIO_ID.MAINMENUBGM)
                cclog("create room btn is clicked")

            end
        end
    end

    local btnCreateRoom = ccui.Button:create("start.png","","",ccui.TextureResType.plistType)
    btnCreateRoom:setPosition(self.size.width*0.5 + 100 ,self.size.height * 0.85)
    --用这种方式添加按钮响应函数
    btnCreateRoom:addTouchEventListener(button_callback_createroom)
    layer:addChild(btnCreateRoom,4)

    local effectSpriteCreateRoom = cc.EffectSprite:create("mainmenuscene/start.png")
    effectSpriteCreateRoom:setPosition(self.size.width*0.5 + 100,self.size.height* 0.85)
    layer:addChild(effectSpriteCreateRoom,5)
end

function PVPMainScene:addBackBtn(layer)
    local isTouchBtnBack = false
    local btn_callback_back = function(sender, eventType)
        if isTouchBtnBack == false then
            isTouchBtnBack = true
            if eventType == ccui.TouchEventType.began then
                ccexp.AudioEngine:play2d(BGM_RES.MAINMENUSTART, false, 1)
                ccexp.AudioEngine:stop(AUDIO_ID.MAINMENUBGM)
                cclog("back btn is pressed!")
                cc.Director:getInstance():replaceScene(require("MainMenuScene").create())
            end
        end
    end

    local btnBack = ccui.Button:create("start.png","","",ccui.TextureResType.plistType)
    btnBack:setPosition(0 + 100 ,self.size.height * 0.85)
    --用这种方式添加按钮响应函数
    btnBack:addTouchEventListener(btn_callback_back)
    layer:addChild(btnBack,4)

    local effectSpriteBack = cc.EffectSprite:create("mainmenuscene/start.png")
    effectSpriteBack:setPosition(0 + 100,self.size.height* 0.85)
    layer:addChild(effectSpriteBack,5)
end

return PVPMainScene