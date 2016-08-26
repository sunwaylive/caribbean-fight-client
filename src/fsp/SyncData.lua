--How to declare Lua Classes, see: lua-users.org/wiki/SimpleLuaClasses
--

--define SyncData class
SyncData = {}
SyncData.__index = SyncData

function SyncData:new(obj)
    obj = obj or {}
    setmetatable(obj, self)

    obj.m_frame_id = 0
    obj.m_cmd_list = {}

    return obj
end


--define SyncCmd class
SyncCmd = {}
SyncCmd.__index = SyncCmd

function SyncCmd:new(obj)
    obj = obj or {}
    setmetatable(obj, self)

    obj.m_vkey = 0
    obj.arg = {}

    return obj
end



