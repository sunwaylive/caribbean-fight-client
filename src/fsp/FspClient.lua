
--define fsp FspClient module
FspClient = {}

local socket = require("socket") --如果不行换这个试试 require('socket.core');
local FspCodec = require("FspCodec")

FspClient.m_server_ip = "119.29.25.185" --127.0.0.1
FspClient.m_server_port = 3009

FspClient.m_client_sock = nil

FspClient.m_is_running = false

--return 1 if success, return nil, error_msg if fail, the same as luasocket.connect()
function FspClient.Connect()
    --设置同步的服务器
    local server_ip = FspClient.m_server_ip
    local server_port = FspClient.m_server_port

    FspClient.m_client_sock = socket:tcp()
    FspClient.m_client_sock:settimeout(-1)

    e, msg = FspClient.m_client_sock:connect(server_ip, server_port)
    if e == 1 then
        FspClient.m_client_sock:setoption('tcp-nodelay', true)
        cclog('TRAEC: Success! FSP socket connect!')
    else
        cclog('ERROR: Fail FSP socket! ' .. msg)
        return e, msg
    end

    FspClient.m_is_running = true
    return 1 -- success
end

--recv from server, put data into queue
function FspClient.RecvFrameFromServer()
    FspClient.m_client_sock:settimeout(0.05)
    while true do
        r, e = fsp_socket:receive("*l")
        if e == "timeout" then
            return -- get all the packages
        elseif e ~= nil then
            cclog("ERROR: In RecvFrameFromServer() in FspClient, I can't receive! " .. e)
            return
        end

        --handle received data r --BUG
        local new_frame = r
        FspCodec.WriteToRecvQueue(new_frame)
    end
end

--*******************************************************
--send the data in the send queue to server
function FspClient.SendFrameToServer()
    local_frame_list = FspCodec.GetFrameFromSendQueue()
    if local_frame == nil or #local_frame <= 0 then
        return
    end

    to_send = ""
    for i = 1, #local_frame_list do
        to_send = to_send .. local_frame_list[i]
    end
    sn, se = fsp_socket:send(to_send)
    if se ~= nil then
        cclog("ERROR: In SendFrameToServer() in FspCodec.lua, I can't send! " .. se)
        return
    else
        cclog("TRACE: Send local frame to server")
    end
end

function FspClient.GetSocket()
    return FspClient.m_client_sock
end

return FspClient
