
--define fsp FspClient module
FspClient = {}

local socket = require("socket") --如果不行换这个试试 require('socket.core');

FspClient.m_server_ip = "119.29.25.185" --127.0.0.1
FspClient.m_server_port = 3009

FspClient.m_client_sock = nil

FspClient.m_send_thread = nil
FspClient.m_recv_thread = nil
FspClient.m_is_running = false

--return 1 if success, return nil, error_msg if fail, the same as luasocket.connect()
function FspClient.Connect()
    --设置同步的服务器
    local server_ip = FspClient.m_server_ip
    local server_port = FspClient.m_server_port

    FspClient.m_client_sock = socket:tcp()
    FspClient.m_client_sock:settimeout(0.05)

    e, msg = FspClient.m_client_sock:connect(server_ip, server_port)
    if e == 1 then
        FspClient.m_client_sock:setoption('tcp-nodelay', true)
        cclog('TRAEC: Success! FSP socket connect!')
    else
        cclog('ERROR: Fail FSP socket!' .. msg)
        return e, msg
    end

    FspClient.m_is_running = true

    --create send thread
    FspClient.m_send_thread = coroutine.create(FspClient.SendThread);
    coroutine.resume(FspClient.m_send_thread);

    --create recv thread
    FspClient.m_recv_thread = coroutine.create(FspClient.RecvThread);
    coroutine.resume(FspClient.m_recv_thread);

    return 1 -- success
end

function FspClient.SendThread()
    if FspClient.m_is_running then
        print "send thread"
    end

    while FspClient.m_is_running then
        FspClient.m_client_sock:settimeout(0.1)

        to_send = "BUG\n" --FspCodec.GetFrameFromSendQueue()

        sn, se = FspClient.m_client_sock:send(to_send)
        if se ~= nil then
            cclog("ERROR: In send thread " .. se)
            return
        else
            cclog("TRACE: In send thread Succeed!")
        end
    end
end

function FspClient.RecvThread()
    if FspClient.m_is_running then
        print "recv thread"
        return
    end

    while FspClient.m_is_running then
        FspClient.m_client_sock:settimeout(0.1) --stop block infinitely
        back, err, partial = FspClient.m_client_sock:receive("*l") --按行读取
        if err ~= "closed" then
            if back then
                cclog("TRACE: In recv thread, I have received msg: " .. back)
                
            end --end if back
        else
            cclog("ERROR: In recv thread, fsp socket is closed!")
            fsp_socket = nil --if tcp is dis-connect
        end --end if err

        --BUG: when yield, then write to recv queue

    end --end while
end

function FspClient.GameLogicGetFrame()
    --BUG: call FspCodec.GetFrameFromRecvQueue

end

function FspClient.GetSocket()
    return FspClient.m_client_sock
end

return FspClient
