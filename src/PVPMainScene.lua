require("Helper")

local fontPath = "fonts/Font3.ttf"
--导入socket库
local socket = require("socket") --如果不行换这个试试 require('socket.core');

client_socket = nil --房间管理的socket， 本客户端和服务器通信的tcp链接
m_room_id = nil --加入房间之后的room id

local label1
local label2

local roomList = List.new()
local menu = nil
local str = "0"

LINE_SPACE = 60
local num = 0
local totalTime = 0.0
local receiveDataFrq = 0.005
local layer
local my_roomID = -1

local PVPMainScene  = class("PVPMainScene",function ()
                            return cc.Scene:create()
                            end)

--constructor init member variable
function PVPMainScene:ctor()
    --get win size
    self.size = cc.Director:getInstance():getVisibleSize()
	self.label = nil
end

--这个函数会收到很多的网络包
local function showRoomList(r)
    if r == nil then return end
    
    local i = string.find(r,'@')
    if i == nil then return end
    
    local rType = string.sub(r,1,i-1)
    local rContent = string.sub(r,i+1,-1)
    
    --label1:setString(r)
    --label2:setString(rType)
    if rType == "listRoom" then
        
        print("content: " .. rContent)
        rooms = rContent
        print("rooms: " .. rooms)
        
        List.removeAll(roomList)
        room_tbl = newSplit(rooms, '|') --先按照|分割出每个房间
        print(#room_tbl)
        if room_tbl == nil or #room_tbl <= 0 then return end
        
        for i, r in pairs(room_tbl) do
            room_info_tbl = newSplit(r, ' ') --然后对每一个房间，按照 " " 分割出房间号，房间最大人数，房间当前人数
            print("i: " .. i)
            
            if room_info_tbl == nil or #room_info_tbl <= 0  or #room_info_tbl > 3 then return end
            
            t_roomID = room_info_tbl[1]
            print(t_roomID)
            
            t_roomMaxPlayerNum = room_info_tbl[2]
            print(t_roomMaxPlayerNum)
            
            t_roomCurPlayerNum = room_info_tbl[3]
            print(t_roomCurPlayerNum)
            
            List.pushlast(roomList, {roomID = t_roomID, maxPlayerNum = t_roomMaxPlayerNum, curPlayerNum = t_roomCurPlayerNum})
        end
        PVPMainScene:addRoomLabel(layer ,roomList)
    end
end

local function listRoomListener(dt)
    if client_socket == nil then return end
    
    totalTime = totalTime + dt
    if totalTime > receiveDataFrq then
        client_socket:settimeout(0.1) --stop block infinitely
        back, err, partial = client_socket:receive("*l") --按行读取
        if err ~= "closed" then
            if back then
                --print(string.len(back))
                cclog("listen Room Listener I have received msg: " .. back)
                --TODO: 这里处理收到的房间信息，在界面上显示出来
                --如果不幸收到了 开始游戏的协议包
                if string.sub(back, 1, 1) == 's' then
                    local scene = require("PVPBattleScene")
                    cc.Director:getInstance():replaceScene(scene.create(back))
                else
                    showRoomList(back)
                end
            end
            else
            cclog("TCP Connection is closed!")
            client_socket = nil --if tcp is dis-connect
        end
        totalTime = totalTime - receiveDataFrq
    end
end

function PVPMainScene.create()
    local scene = PVPMainScene.new()
    layer = scene:createLayer()
    scene:addChild(layer)
    listRoomListenerID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(listRoomListener, 0, false)
    return scene
end


function PVPMainScene:createLayer()
    --create layer
    local layer = cc.Layer:create()
    
    --创建UI元素
    self:addBg(layer)
    self:addBackBtn(layer)
    self:addCreate1v1Btn(layer)
    self:addCreate2v2Btn(layer)
    self:addListRoomBtn(layer) --点击查询房间
    self:addStartGameBtn(layer)
    
    --显示调试信息
    --self:addLabel(layer)
    --连接服务器
    if client_socket == nil then
        self:connectToServer()
    end
    
    --每次一进入，就向服务器查询房间的信息
    --if client_socket ~= nil then self:listRoom() end
    
	--List.pushlast(roomList,{roomID=1002,maxPlayerNum = 2, curPlayerNum = 1})
	--self:addRoomLabel(layer, roomList)
    return layer
end

function PVPMainScene:addRoomLabel(layer, list)
    if layer == nil then return end
    
	local function menuCallback(tag)
        --如果已经在房间中了，则不能再加入其它房间
        if m_room_id ~= nil then
            cclog("你已经创建房间或者已经在房间中了，无法再加入新的房间！")
            return
        end
        
        local Idx = tag - 10000
        local roomID = roomList[Idx].roomID        
        print("roomID: " .. roomID)
        
        m_room_id = roomID
        self:joinRoom(roomID)
        cclog("after menu call back: " .. m_room_id)
    end
	
	local index
    local size = cc.Director:getInstance():getVisibleSize()
	if menu ~= nil then
		menu:removeAllChildren() --清空所有的menuitem
        menu = nil
	end
	menu = cc.Menu:create()
    
	local roomIndex = 0
	if my_roomID == -1 then	-- 表示我没有建立房间
		for index = list.last, list.first, -1 do
			-- label、menuItem、menu的坐标都能影响最终的菜单位置
			local label = cc.Label:createWithTTF("房间号: " .. list[index].roomID .. string.rep(" ",4) ..
												 "人数: " .. list[index].curPlayerNum .. "/" .. list[index].maxPlayerNum, fontPath, 40)
			--label:setColor(cc.V3(111,255,0))
			label:setAnchorPoint(cc.p(0.5,0.5))
			local menuItem = cc.MenuItemLabel:create(label)
			--menuItem:setPosition(cc.p(self.size.width/2, self.size.height*0.7-index * LINE_SPACE))
			menuItem:setPosition(cc.p(size.width * 0.5, size.height*0.8-roomIndex * LINE_SPACE))
			roomIndex = roomIndex + 1
			menuItem:registerScriptTapHandler(menuCallback)
			menu:addChild(menuItem, index+10000, index+10000)
		end
	else
		for index = list.last, list.first, -1 do
			if list[index].roomID == my_roomID then
				-- label、menuItem、menu的坐标都能影响最终的菜单位置
				local label = cc.Label:createWithTTF("房间号: " .. list[index].roomID .. string.rep(" ",4) ..
													 "人数: " .. list[index].curPlayerNum .. "/" .. list[index].maxPlayerNum, fontPath, 40)
				--label:setColor(cc.V3(111,255,0))
				label:setAnchorPoint(cc.p(0.5,0.5))
				local menuItem = cc.MenuItemLabel:create(label)
				--menuItem:setPosition(cc.p(self.size.width/2, self.size.height*0.7-index * LINE_SPACE))
				menuItem:setPosition(cc.p(size.width * 0.5, size.height*0.8-roomIndex * LINE_SPACE))
				menuItem:registerScriptTapHandler(menuCallback)
				menu:addChild(menuItem, index+10000, index+10000)
			end
		end
	end
	menu:setPosition(0,0)
	menu:setContentSize(cc.size(size.width, List.getSize(list)*LINE_SPACE))
	layer:addChild(menu, 4)
	
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
		
		if (List.getSize(roomList) + 1) * LINE_SPACE - winSize.height * 0.8 < 0 then
			return
		end

        if nextPosy > ((List.getSize(roomList) + 1) * LINE_SPACE - winSize.height * 0.8) then
            menu:setPosition(0, ((List.getSize(roomList) + 1) * LINE_SPACE - winSize.height * 0.8))
            return
        end

        menu:setPosition(curPosx, nextPosy)
        BeginPos = {x = location.x, y = location.y}
        CurPos = {x = curPosx, y = nextPosy}
    end

    local listener = cc.EventListenerTouchOneByOne:create()
    listener:registerScriptHandler(onTouchBegan,cc.Handler.EVENT_TOUCH_BEGAN )
    listener:registerScriptHandler(onTouchMoved,cc.Handler.EVENT_TOUCH_MOVED )
    local eventDispatcher = layer:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(listener, layer)
end

--pvp establish tcp connect
function PVPMainScene:connectToServer()
    local server_ip = "112.74.199.45"
    --[[
    local server_port =  2348 --8383--2348
    client_socket = socket.tcp()
    client_socket:settimeout(0.3)
    
    --In case of error, the method returns nil followed by a string describing the error. In case of success, the method returns 1.
    if client_socket:connect(server_ip, server_port) == 1 then
        cclog('Success! room management socket connect!')
		self.label:setString("Yooooo!!")
	else
        cclog('Fail! room management socket!')
		self.label:setString("Nooooo!!")
    end
     --]]
    
    --设置状态同步的服务器
    local state_server_port = 4455
    client_socket = socket:tcp()
    client_socket:settimeout(0.05)
        
    if client_socket:connect(server_ip, state_server_port) == 1 then
        client_socket:setoption('tcp-nodelay', true)
        cclog('Success! state socket connect!')
    else
        cclog('Fail! state socket!')
        return
    end
end

--pvp list room,只负责向服务器发送协议
function PVPMainScene:listRoom()
    cclog("send listRoom request!")
    
    if client_socket ~= nil then
        sn, se = client_socket:send("listRoom\n")
        if se ~= nil then
            cclog("SEND ERROR: In listRoom() in PVPMainScene.lua!" .. se)
            return
        end
        
        client_socket:settimeout(-1) --block infinitely
        r, re = client_socket:receive("*l")
        if re ~= nil then
            cclog("RECEIVE ERROR: In listRoom() in PVPMainScene.lua! " .. re)
            return
        end
        
        cclog("Success, in listRoom(), I have received msg from server: " .. r)
        showRoomList(r)
        --这个时候只会有一个创建房间的回包出现
        --TODO: 这里处理创建房间的回包
    end
end

--PVP create room
function PVPMainScene:createRoom(max_people)
    if client_socket ~= nil then
        sn, se = client_socket:send("createRoom" .. " " .. max_people .. "\n") --房间总人数
        if se ~= nil then
            cclog("SEND ERROR: In createRoom() in PVPMainScene.lua!" .. se)
            return
        else
            cclog("Send createRoom Successfully!")
        end
        
        client_socket:settimeout(-1) --block infinitely
        r, re = client_socket:receive("*l")
        if re ~= nil then
            cclog("REVEIVE ERROR: In createRoom() in PVPMainScene.lua! " .. re)
            return
        end
        
        --设置创建房间的人的m_room_id
        local i = string.find(r,'@')
        if i == nil then return end
        
        local t_roomID = string.sub(r,i+1,-1)
		my_roomID = t_roomID;
        m_room_id = tonumber(t_roomID)
        
        cclog("Sucess! In createRoom(), I have received msg from server: " .. r)
        --这个时候只会有一个创建房间的回包出现
        self:listRoom() --如果创建房间成功，则向服务器发送 listRoom的请求
    end
end

--PVP join room
function PVPMainScene:joinRoom(roomID)
    if roomID == nil then
        cclog("ERROR: in joinRoom(), nil roomID!")
        return
    end
    
    if client_socket ~= nil then
        sn, se = client_socket:send("joinRoom " .. roomID .. "\n")
        if se ~= nil then
            cclog("SEND ERROR: In joinRoom() in PVPMainScene.lua!" .. se)
            return
        else
            cclog("Success: join Room!")
        end
        
        client_socket:settimeout(-1) --block infinitely
        r, re = client_socket:receive("*l")
        if re ~= nil then
            cclog("REVEIVE ERROR: In joinRoom() in PVPMainScene.lua! " .. re)
            return
        end
        my_roomID = roomID
        cclog("Success! In joinRoom(), I have received msg from server: " .. r)
    end
end

--test
function PVPMainScene:joinRoomTest(roomID)
    if client_socket ~= nil then
        sn, se = client_socket:send("joinRoom "..roomID.."\n")
        if se ~= nil then
            cclog("SEND ERROR: In joinRoom() in PVPMainScene.lua!" .. se)
            return
        end
        
        client_socket:settimeout(-1) --block infinitely
        r, re = client_socket:receive("*l")
        if re ~= nil then
            cclog("REVEIVE ERROR: In joinRoom() in PVPMainScene.lua! " .. re)
            return
        end
        
        cclog("Success! In joinRoom(), I have received msg from server: " .. r)
        
        --为了测试
        if string.sub(r, 1, 1) == "s" then --如果是开始游戏
            --这个时候只会有一个回包出现，就是响应开始游戏的回包
            local scene = require("PVPBattleScene")
            cc.Director:getInstance():replaceScene(scene.create(r))
        end
    end
end


--开始游戏的时候，向状态同步的服务器发送请求
function PVPMainScene:startGame()
    if client_socket ~= nil then
        --这里取消监听listRoom消息
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(listRoomListenerID)
        
        if m_room_id == nil then
            cclog("请选择一个房间加入!")
            return
        end
        
        sn, se = client_socket:send("startGame " .. m_room_id .. "\n")
        if se ~= nil then
            cclog("ERROR: In startGame() in PVPMainScene.lua, I can't send! " .. se)
            return
        else
            cclog("Send start game!")
        end
        
        client_socket:settimeout(-1) --block infinitely
        r, e = client_socket:receive("*l")
        if e ~= nil then
            cclog("ERROR: In startGame() in PVPMainScene.lua, I can't receive! " .. e)
            return
        end
        
        print("in start game , I have received: " .. r)
        if string.sub(r, 1, 1) == "s" then --如果是开始游戏
            --这个时候只会有一个回包出现，就是响应开始游戏的回包
            local scene = require("PVPBattleScene")
            cc.Director:getInstance():replaceScene(scene.create(r))
        end
        
    else
        cclog("Can't connect to the server! client socket nil!")
    end
        --[[
        r, re = client_socket:receive("*l")
        if re ~= nil then
            cclog("ERROR: In startGame() in PVPMainScene.lua, I can't receive! " .. re)
            return
        end
        
        cclog("I have received msg from server: " .. r)
        --这个时候只会有一个回包出现，就是响应开始游戏的回包
        local scene = require("PVPBattleScene")
        cc.Director:getInstance():replaceScene(scene.create(r))--]]
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
				menu = nil
                cc.Director:getInstance():replaceScene(require("MainMenuScene").create())
            end
        end
    end

    local btnBack = ccui.Button:create("pvpmainscene/back.png")
    btnBack:setPosition(self.size.width * 0.15 ,self.size.height * 0.1)
    --用这种方式添加按钮响应函数
    btnBack:setScale(0.5)
    btnBack:addTouchEventListener(btn_callback_back)
    layer:addChild(btnBack,4)
end

function PVPMainScene:addCreate1v1Btn(layer)
    --step1: 添加 创建房间的按钮
    local isTouchButtonCreateRoom = false
    local button_callback_createroom = function(sender, eventType)
        --确保这个按钮只被点击了一次
        if isTouchButtonCreateRoom == false then
            isTouchButtonCreateRoom = true
            if eventType == ccui.TouchEventType.began then
                ccexp.AudioEngine:play2d(BGM_RES.MAINMENUSTART, false, 1)
                ccexp.AudioEngine:stop(AUDIO_ID.MAINMENUBGM)
                cclog("create 1v1 room btn is clicked")
                self:createRoom(2)--创建PVP房间
            end
        end
    end

    local btnCreateRoom = ccui.Button:create("pvpmainscene/create1v1.png")
    --btnCreateRoom:setPosition(100 + btnCreateRoom:getContentSize().width + 100, self.size.height * 0.85)
    btnCreateRoom:setPosition(self.size.width * 0.15, self.size.height * 0.55)
    btnCreateRoom:setScale(0.6)
    --用这种方式添加按钮响应函数
    btnCreateRoom:addTouchEventListener(button_callback_createroom)
    layer:addChild(btnCreateRoom,4)
end

function PVPMainScene:addCreate2v2Btn(layer)
    --step1: 添加 创建房间的按钮
    local isTouchButtonCreateRoom = false
    local button_callback_createroom = function(sender, eventType)
    --确保这个按钮只被点击了一次
    if isTouchButtonCreateRoom == false then
        isTouchButtonCreateRoom = true
        if eventType == ccui.TouchEventType.began then
            ccexp.AudioEngine:play2d(BGM_RES.MAINMENUSTART, false, 1)
            ccexp.AudioEngine:stop(AUDIO_ID.MAINMENUBGM)
            cclog("create 2v2 room btn is clicked")
            self:createRoom(4)--创建PVP房间
        end
    end
    end

local btnCreateRoom = ccui.Button:create("pvpmainscene/create2v2.png")
--btnCreateRoom:setPosition(100 + btnCreateRoom:getContentSize().width + 100, self.size.height * 0.85)
btnCreateRoom:setPosition(self.size.width * 0.15, self.size.height * 0.4)
btnCreateRoom:setScale(0.6)
--用这种方式添加按钮响应函数
btnCreateRoom:addTouchEventListener(button_callback_createroom)
layer:addChild(btnCreateRoom,4)
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
                self:startGame(m_room_id)
            end
        end
    end

    local btnStartGame = ccui.Button:create("pvpmainscene/start.png")
    btnStartGame:setScale(0.5) -- 因为这个按钮和创建1v1/2v2按钮的分辨率不一致
    btnStartGame:setPosition(self.size.width * 0.85, self.size.height * 0.1)
    btnStartGame:addTouchEventListener(button_callback_startgame)
    layer:addChild(btnStartGame, 5)
end


function PVPMainScene:addListRoomBtn(layer)
    local isTouchButtonJoinRoom = false
    local button_callback_listroom = function(sender, eventType)
    if isTouchButtonJoinRoom == false then
        --isTouchButtonJoinRoom = true --可以点击多次
        if eventType == ccui.TouchEventType.began then
            ccexp.AudioEngine:play2d(BGM_RES.MAINMENUSTART, false, 1)
            ccexp.AudioEngine:stop(AUDIO_ID.MAINMENUBGM)
            cclog("list room btn is clicked")
            self:listRoom()
        end
    end
end

local btnListRoom = ccui.Button:create("pvpmainscene/list.png")
btnListRoom:setPosition(self.size.width * 0.15, self.size.height * 0.7)
btnListRoom:setScale(0.6)
--用这种方式添加按钮响应函数
btnListRoom:addTouchEventListener(button_callback_listroom)
layer:addChild(btnListRoom,4)
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

--bg
function PVPMainScene:addBg(layer)
    --TODO: background
    local bg_back = cc.Sprite:create("pvpmainscene/bg.png")
    bg_back:setPosition(self.size.width/2,self.size.height/2)
    layer:addChild(bg_back,1)
end

return PVPMainScene