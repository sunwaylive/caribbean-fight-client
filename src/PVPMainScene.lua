local PVPMainScene  = class("PVPMainScene",function ()
return cc.Scene:create()
end)

function PVPMainScene.create()
    local scene = PVPMainScene.new()
    cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_AUTO)
    local layer = scene:createLayer()
    scene:addChild(layer)
    AUDIO_ID.CHOOSEROLESCENEBGM = ccexp.AudioEngine:play2d(BGM_RES.CHOOSEROLESCENEBGM, true,1)
    return scene
end

function PVPMainScene:createLayer()
    --create layer
    self.layer = cc.Layer:create()

    return self.layer
end

return PVPMainScene