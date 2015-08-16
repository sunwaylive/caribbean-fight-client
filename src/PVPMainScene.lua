require("Helper")

local fontPath = "chooseRole/actor_param.ttf"
--导入socket库
local socket = require("socket") --如果不行换这个试试 require('socket.core');

client_socket = nil --本客户端和服务器通信的tcp链接
local label1
local label2
local roomList = List.new()
local roomMenu
local str = "0"
LINE_SPACE = 80
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
    layer = scene:createLayer()
    scene:addChild(layer)

    return scene
end

local function tcpListener(dt)
	local r = client_socket:receive('*l')
	if r==nil then
		return
	else
		label1:setString(r)
		local i = string.find(r,'@')
		if i == nil then 
			return 
		end
		local rType = string.sub(r,1,i-1)
		local rContent = string.sub(r,i+1,-1)
		label2:setString(rType)
		if rType == "createRoom" then
			if rContent == "OK" then
			
			end
		elseif rType == "listRoom" then
			rooms = rContent
			List.removeAll(roomList)
			while(1)
			do
				local j = string.find(rooms,' ')
				local k = string.find(rooms,'|')
				local roomID = string.sub(rooms,1,j-1)
				local playerNum = string.sub(rooms,j+1,k-1)
				--把房间存入列表
				List.pushlast(roomList,{roomID=roomID, playerNum=playerNum})
				--如果后面没有其他房间了
				if k == string.len(rooms) then
					break
				end
				rooms = string.sub(rooms,k+1,-1)
			end
			PVPMainScene:addRoomLabel(PVPMainScene,roomList)
		elseif rType == "joinRoom" then
		
		elseif rType == "startGame" then
		
		end
	end
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
    
	List.pushlast(roomList,{roomID=1002,playerNum=2})
	List.pushlast(roomList,{roomID=1003,playerNum=3})
	List.pushlast(roomList,{roomID=1004,playerNum=5})
	self:addRoomLabel(layer, roomList)
	--listener = cc.Director:getInstance():getScheduler():scheduleScriptFunc(tcpListener, 0, false)
    return layer
end

function PVPMainScene:addRoomLabel(layer, list)
	local function menuCallback(tag)
        print(tag)
        local Idx = tag - 10000
        local roomID = roomList[Idx].roomID
		self:joinRoom(roomID)
    end
	
	local index
	local menu = cc.Menu:create()
	for index=list.first, list.last do
		-- label、menuItem、menu的坐标都能影响最终的菜单位置
		local label = cc.Label:createWithTTF("RoomID:"..list[index].roomID..string.rep(" ",10).."PlayerNum:"..list[index].playerNum,fontPath, 40)
		label:setColor(cc.V3(255,0,0))
		label:setAnchorPoint(cc.p(0.5,0.5))
		local menuItem = cc.MenuItemLabel:create(label)
		menuItem:setPosition(cc.p(self.size.width/2,self.size.height*0.7-index*LINE_SPACE))
		menuItem:registerScriptTapHandler(menuCallback)
		menu:addChild(menuItem, index+10000, index+10000)
	end
	menu:setPosition(0,0)
	menu:setContentSize(cc.size(self.size.width, List.getSize(list)*LINE_SPACE))
	layer:addChild(menu)
	
	-- handling touch events
    local function onTouchBegan(touch, event)
        BeginPos = touch:getLocation()
        -- CCTOUCHBEGAN event must return true
        return true
    end

    local function onTouchMoved(touch, event)
        local location = touch:getLocation()
        local nMoveY = location.y - BeginPos.y
        local curPosx, curPosy = menu:getPosition()
        local nextPosy = curPosy + nMoveY
        local winSize = cc.Director:getInstance():getWinSize()
        if nextPosy < 0 then
            menu:setPosition(0, 0)
            return
        end
		
		if (List.getSize(roomList) + 1) * LINE_SPACE - winSize.height < 0 then
			return
		end

        if nextPosy > ((List.getSize(roomList) + 1) * LINE_SPACE - winSize.height) then
            menu:setPosition(0, ((List.getSize(roomList) + 1) * LINE_SPACE - winSize.height))
            return
        end

        menu:setPosition(curPosx, nextPosy)
        BeginPos = {x = location.x, y = location.y}
        CurPos = {x = curPosx, y = nextPosy}
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
end

--pvp establish tcp connect
function PVPMainScene:connectToServer()
    local server_ip = "112.74.199.45"
    local server_port =  8383--8383--2348
    client_socket = socket.tcp()
    --client_socket:settimeout(5)
    
    --In case of error, the method returns nil followed by a string describing the error. In case of success, the method returns 1.
    if client_socket:connect(server_ip, server_port) == 1 then
        cclog('socket connect!')
		self.label:setString("Yooooo!!")
	else
		self.label:setString("Nooooo!!")
    end
end

--pvp list room
function PVPMainScene:listRoom(roomList)
	self.label:setString("listRoom")
	local r, e = client_socket:send("listRoom\n")
	print(r,e)
	if e~= nil then
		label1:setString(e)
	end
end

--PVP create room
function PVPMainScene:createRoom()
	self.label:setString("createRoom")
    local r, e = client_socket:send("createRoom 2\n") --第一个返回值是发送的字节数的意思, 第二个返回值是错误码，如果成功则返回nil
    --cclog(r)
	print(r,e)
	if e~= nil then
		label1:setString(e)
	end
	print("OK")
end

--PVP join room
function PVPMainScene:joinRoom(roomID)
	self.label:setString("joinRoom")
	local r, e = client_socket:send("joinRoom "..roomID.."\n")
	print(r,e)
	if e~= nil then
		label1:setString(e)
	end
end

function PVPMainScene:startGame()
	-- self.label:setString("startGame")
	-- local r, e = client_socket:send("startGame "..roomID.."\n")
	-- print(r,e)
	-- if e~= nil then
		-- label1:setString(e)
	-- end
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
				--清空房间列表
				List.removeAll(roomList)
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
                --self:joinRoom(roomID)--加入PVP房间
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
    self.label = cc.Label:createWithTTF("Hello World",fontPath, 20)
    self.label:setPosition(self.size.width*0.5,self.size.height*0.5)
	self.label:setColor(cc.V3(255,0,0))
	--self.label:setVisible(false)
    self:addChild(self.label,1)
	
	label1 = cc.Label:createWithTTF("Hello World",fontPath, 20)
    label1:setPosition(self.size.width*0.5,self.size.height*0.4)
	label1:setColor(cc.V3(255,0,0))
	print(label1:getPosition())
	self:addChild(label1,1)
	--label1:setVisible(false)
	label1:setString("hello")
	
	label2 = cc.Label:createWithTTF("Hello World",fontPath, 20)
    label2:setPosition(self.size.width*0.5,self.size.height*0.2)
	label2:setColor(cc.V3(255,0,0))
	self:addChild(label2,1)
	--label2:setVisible(false)
	label2:setString("hello")
end

return PVPMainScene