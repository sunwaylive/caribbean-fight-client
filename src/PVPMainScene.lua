--导入socket库
local socket = require("socket") --如果不行换这个试试 require('socket.core');

client_socket = nil --本客户端和服务器通信的tcp链接
local label1
local label2
local str = "0"
local num = 0

local PVPMainScene  = class("PVPMainScene",function ()
                            return cc.Scene:create()
                            end)

--constructor init member variable
function PVPMainScene:ctor()
    --get win size
    self.size = cc.Director:getInstance():getVisibleSize()
	self.label = nil
end

function PVPMainScene.create()
    local scene = PVPMainScene.new()
    local layer = scene:createLayer()
    scene:addChild(layer)
    
    return scene
end

local function tcpListener(dt)
	local r = client_socket:receive('*l')
	-- io.output("out.txt")
	-- if r~= nil then
		-- io.write(r)
	-- else
		-- io.write("nil\n")
	-- end
	-- io.output():close()
	if r==nil then
		--str = str + "nil"
		--label1:setString("nil")
		return
	else
		str = str.."x"..r
		label1:setString(str)
		--label1:setString(r)
	end
end

local function update(dt)
	label2:setString(str..num)
end

function PVPMainScene:createLayer()
    --create layer
    local layer = cc.Layer:create()
	self:addLabel(layer)
    --连接服务器
    self:connectToServer()
    
    --创建UI元素
    self:addBackBtn(layer)
    self:addCreateRoomBtn(layer)
    self:addJoinRoomBtn(layer)
    self:addStartGameBtn(layer)
    --TODO: 这边会导致界面阻塞
	--listener = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tcpListener, 0, false)
	--scheduler = cc.Director:getInstance():getScheduler():scheduleScriptFunc(update, 0, false)
    return layer
end

--pvp establish tcp connect
function PVPMainScene:connectToServer()
    local server_ip = "112.74.199.45"
    local server_port = 8383
    client_socket = socket.tcp()
    --client_socket:settimeout(0)
    
    --In case of error, the method returns nil followed by a string describing the error. In case of success, the method returns 1.
    if client_socket:connect(server_ip, server_port) == 1 then
        cclog('socket connect!')
		self.label:setString("Yooooo!!")
	else
		self.label:setString("Nooooo!!")
    end
end

--pvp list room
function PVPMainScene:listRoom()
    
end

--PVP create room
function PVPMainScene:createRoom()
	self.label:setString("createRoom"..num)
	num = num + 1
	print(num)
	--label1:setString("createRoom")
	--label1:setString(str)
    local r, e = client_socket:send("createRoom 2\n") --第一个返回值是发送的字节数的意思, 第二个返回值是错误码，如果成功则返回nil
    --cclog(r)
	print(r,e)
	if e~= nil then
		self.label:setString(e)
	end
	print("OK")
end

--PVP join room
function PVPMainScene:joinRoom()

end

function PVPMainScene:startGame()
    --local scene = require("PVPBattleScene")
    --cc.Director:getInstance():replaceScene(scene.create())
    if client_socket ~= nil then
        sn, se = client_socket:send("STARTGAME\n")
        if se ~= nil then
            cclog("ERROR: In startGame() in PVPMainScene.lua, I can't send! " .. se)
        end
        
        r, re = client_socket:receive("*l")
        if re ~= nil then
            cclog("ERROR: In startGame() in PVPMainScene.lua, I can't receive! " .. re)
            return
        end
        
        cclog("I have received msg from server: " .. r)
        --这个时候只会有一个回包出现，就是响应开始游戏的回包
        local scene = require("PVPBattleScene")
        cc.Director:getInstance():replaceScene(scene.create(r))
    end
end

--below is for create UI elements
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
    effectSpriteBack:setPosition(0 + 100 ,self.size.height * 0.85)
    layer:addChild(effectSpriteBack,5)
end

function PVPMainScene:addCreateRoomBtn(layer)
    --step1: 添加 创建房间的按钮
    local isTouchButtonCreateRoom = false
    local button_callback_createroom = function(sender, eventType)
        --确保这个按钮只被点击了一次
        if isTouchButtonCreateRoom == false then
            --isTouchButtonCreateRoom = true
            if eventType == ccui.TouchEventType.began then
                ccexp.AudioEngine:play2d(BGM_RES.MAINMENUSTART, false, 1)
                ccexp.AudioEngine:stop(AUDIO_ID.MAINMENUBGM)
                cclog("create room btn is clicked")
                self:createRoom()--创建PVP房间
            end
        end
    end

    local btnCreateRoom = ccui.Button:create("start.png","","",ccui.TextureResType.plistType)
    btnCreateRoom:setPosition(100 + btnCreateRoom:getContentSize().width + 100, self.size.height * 0.85)
    --用这种方式添加按钮响应函数
    btnCreateRoom:addTouchEventListener(button_callback_createroom)
    layer:addChild(btnCreateRoom,4)

    local effectSpriteCreateRoom = cc.EffectSprite:create("mainmenuscene/start.png")
    effectSpriteCreateRoom:setPosition(100 + btnCreateRoom:getContentSize().width + 100, self.size.height * 0.85)
    layer:addChild(effectSpriteCreateRoom,5)
end

function PVPMainScene:addJoinRoomBtn(layer)
    --step1: 添加 加入房间的按钮
    local isTouchButtonJoinRoom = false
    local button_callback_joinroom = function(sender, eventType)
        --确保这个按钮只被点击了一次
        if isTouchButtonJoinRoom == false then
            isTouchButtonJoinRoom = true
            if eventType == ccui.TouchEventType.began then
                ccexp.AudioEngine:play2d(BGM_RES.MAINMENUSTART, false, 1)
                ccexp.AudioEngine:stop(AUDIO_ID.MAINMENUBGM)
                cclog("join room btn is clicked")
                self:joinRoom()--加入PVP房间
            end
        end
    end

    local btnJoinRoom = ccui.Button:create("start.png","","",ccui.TextureResType.plistType)
    btnJoinRoom:setPosition(100 + 2 * (btnJoinRoom:getContentSize().width + 100 ),self.size.height * 0.85)
    --用这种方式添加按钮响应函数
    btnJoinRoom:addTouchEventListener(button_callback_joinroom)
    layer:addChild(btnJoinRoom,4)

    local effectSpriteJoinRoom = cc.EffectSprite:create("mainmenuscene/start.png")
    effectSpriteJoinRoom:setPosition(100 + 2 * (btnJoinRoom:getContentSize().width + 100 ),self.size.height * 0.85)
    layer:addChild(effectSpriteJoinRoom,5)
end

function PVPMainScene:addStartGameBtn(layer)
    local isTouchButtonStartGame = false
    local button_callback_startgame = function(sender, eventType)
        if isTouchButtonStartGame == false then
            isTouchButtonStartGame = true
            if eventType == ccui.TouchEventType.began then
                ccexp.AudioEngine:play2d(BGM_RES.MAINMENUSTART, false, 1)
                ccexp.AudioEngine:stop(AUDIO_ID.MAINMENUBGM)
                cclog("start game btn is clicked")
                self:startGame()
            end
        end
    end

    local btnStartGame = ccui.Button:create("start.png", "", "", ccui.TextureResType.plistType)
    btnStartGame:setPosition(100 + 3 * (btnStartGame:getContentSize().width + 100 ),self.size.height * 0.85)
    btnStartGame:addTouchEventListener(button_callback_startgame)
    layer:addChild(btnStartGame, 5)
end

--用于显示调试信息
function PVPMainScene:addLabel(layer)
    self.label = cc.Label:createWithTTF("Hello World","chooseRole/actor_param.ttf", 20)
    self.label:setPosition(self.size.width*0.5,self.size.height*0.5)
	self.label:setColor(cc.V3(255,0,0))
	--self.label:setVisible(false)
    self:addChild(self.label,1)
	
	label1 = cc.Label:createWithTTF("Hello World","chooseRole/actor_param.ttf", 20)
    label1:setPosition(self.size.width*0.5,self.size.height*0.4)
	label1:setColor(cc.V3(255,0,0))
	self:addChild(label1,1)
	label1:setString("hello")
	
	label2 = cc.Label:createWithTTF("Hello World","chooseRole/actor_param.ttf", 20)
    label2:setPosition(self.size.width*0.5,self.size.height*0.2)
	label2:setColor(cc.V3(255,0,0))
	self:addChild(label2,1)
	label2:setString("hello")
end

return PVPMainScene