--define fsp FspCodec module
--FspCodec is used to maintain send queue, receive queue

FspCodec = {}

FspCodec.m_recv_frame_queue = {}
FspCodec.m_recv_frame_queue_tmp = {}
FspCodec.m_is_using_recv_queue = false

FspCodec.m_send_frame_queue = {}
FspCodec.m_send_frame_queue_tmp = {}
FspCodec.m_is_using_send_queue = false

--***************** send frame queue operation ***********
--
function FspCodec.GetFrameFromSendQueue()
    if #FspCodec.m_send_frame_queue > 0 then
        --clear tmp queue
        FspCodec.ClearTable(FspCodec.m_send_frame_queue_tmp)
        --copy data tom tmp queue
        FspCodec.CopyTable(FspCodec.m_send_frame_queue, FspCodec.m_send_frame_queue_tmp)
        --clear send queue for new coming data
        FspCodec.ClearTable(FspCodec.m_send_frame_queue)
        
        return FspCodec.m_send_frame_queue_tmp
    else
        return {}
    end
end

function FspCodec.WriteToSendQueue(new_frame)
    if new_frame ~= nil then
        table.insert(FspCodec.m_send_frame_queue, new_frame)
    end
end

--***************** recv frame queue operation ***********
--recv queue data -> game logic
function FspCodec.GetFrameFromRecvQueue()
    if #FspCodec.m_recv_frame_queue > 0 then
        --clear tmp queue
        FspCodec.ClearTable(FspCodec.m_recv_frame_queue_tmp)

        --copy data to tmp queue
        FspCodec.CopyTable(FspCodec.m_recv_frame_queue, FspCodec.m_recv_frame_queue_tmp)
        
        --clear recv queue for new coming data
        FspCodec.ClearTable(FspCodec.m_recv_frame_queue)
        
        return FspCodec.m_recv_frame_queue_tmp
    else
        return {}
    end
end

--FspClient data -> recv queue
function FspCodec.WriteToRecvQueue(new_frame)
    table.insert(FspCodec.m_recv_frame_queue, new_frame)
end

--util function
function FspCodec.ClearTable(t)
    for k in pairs(t) do
        t[k] = nil
    end
end

function FspCodec.CopyTable(src, dst)
    dst = dst or {}
    for k, v in pairs(t) do dst[k] = v end
    setmetatable(dst, getmetatable(t))
end

return FspCodec