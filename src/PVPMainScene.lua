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

    --添加 创建房间的按钮
    self:addCreateRoomBtn(layer)

    return layer
end


function PVPMainScene:addCreateRoomBtn(layer)
    --step1: 添加 创建房间的按钮
    local isTouchButtonCreateRoom = false
    local button_callback_createroom = function(sender, eventType)
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

return PVPMainScene