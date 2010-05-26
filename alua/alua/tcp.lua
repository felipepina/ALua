-----------------------------------------------------------------------------
-- TCP
--
-- Module to manage TCP connections
--
-- version: 1.1 2010/05/15
-----------------------------------------------------------------------------

module("alua.tcp", package.seeall)

local raw     = require("rawsend")
local socket  = require("socket")
local marshal = require("alua.marshal")
-- local ccr     = require("ccr")
-- local event   = require("alua.event")

-----------------------------------------------------------------------------
-- Aliases
-----------------------------------------------------------------------------
local dump      = marshal.dump
local load      = marshal.load
local format    = string.format
local concat    = table.concat

-----------------------------------------------------------------------------
-- Module variables
-----------------------------------------------------------------------------
-- Sockets list
local socks = {}

-- Incoming sockets list
local servers = {}

-----------------------------------------------------------------------------
-- Auxiliary functions
-----------------------------------------------------------------------------

-- TODO Documentar
-----------------------------------------------------------------------------
-- 
-----------------------------------------------------------------------------
local function accept(srv)
    local s, err = srv:accept()
    if err then return end
    s:setoption("tcp-nodelay", true)
    socks[s] = servers[srv]
end

-----------------------------------------------------------------------------
-- End auxiliary functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Exported functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Recieves data through a socket
--
-- @param sock The socket
--
-- @ return The data received
-----------------------------------------------------------------------------
function receive(sock)
    local size, err, tmp = sock:receive("*l")
    if err then
        return nil, err
    end
    size = tonumber(size)
    local str
    local data = {""}
    while size > 0 do
        str, err, tmp = sock:receive(size)
        if not str and err ~= "timeout" then
            str = concat(data, "")
            return nil, err, str
        end
        data[#data+1] = str
        size = size - #str
    end
    return concat(data, "")
end

-----------------------------------------------------------------------------
-- Sends data to a process
--
-- @param name The process id
-- @param msg The message
--
-- @return True
-----------------------------------------------------------------------------
function rawsend(name, msg)
    --msg = dump(msg) .. string.rep(" ", 4096)
    msg = dump(msg)
    raw.send(name, tostring(#msg) .. "\n" .. msg)
    -- TODO Verificar esse retorno sempre true
    return true
end

-----------------------------------------------------------------------------
-- Sends data through a socket
--
-- @param sock The socket
-- @param msg The data
--
-- @return true in case of success and false and a error message in case of
--              failure
-----------------------------------------------------------------------------
function send(sock, msg)
    --msg = dump(msg) .. string.rep(" ", 4096)
    msg = dump(msg)
    local n, err = sock:send(tostring(#msg) .. "\n" .. msg)
    if err then
        return false, err
    end
    return true
end

-----------------------------------------------------------------------------
-- Closes the socket
--
-- @param The socket
-----------------------------------------------------------------------------
function close(s)
    socks[s] = nil
    servers[s] = nil
    s:close()
end

-----------------------------------------------------------------------------
-- Closes all sockets
-----------------------------------------------------------------------------
function closeall()
    for s, h in pairs(socks) do
        close(s)
    end
end

-----------------------------------------------------------------------------
-- Creates a incoming socket and registers a handler to it
--
-- @param ip The ip
-- @param port The port
-- @param handler The handler
--
-- @return The socket created
-----------------------------------------------------------------------------
function listen(ip, port, handler)
    local srv, err = socket.bind(ip, port)
    if err then return nil, err end
    srv:setoption('reuseaddr', true)
    srv:setoption("tcp-nodelay", true)
    socks[srv] = accept
    servers[srv] = handler
    return srv
end

-----------------------------------------------------------------------------
-- Connect to a remote socket and register a hendler to it
--
-- @param ip The ip
-- @param port The port
-- @param handler The handler
--
-- @return The socket
-----------------------------------------------------------------------------
function connect(ip, port, handler)
    local s, err = socket.connect(ip, port)
    if err then return nil, err end
    s:setoption("tcp-nodelay", true)
    socks[s] = handler
    return s
end

-----------------------------------------------------------------------------
-- Process the tcp events
--
-- @param block true if the process blocks until data is avaliable, false
--              otherwise
--
-- @return true if events were processed
-----------------------------------------------------------------------------
function process(block)
    local timeout
    if block then
        timeout = 0.03
    else
        timeout = 0
    end
    local rsocks = {}
    for s in pairs(socks) do
        rsocks[#rsocks+1] = s
    end
    rsocks = socket.select(rsocks, nil, timeout)
    local nonblock = #rsocks > 0
    for _, s in ipairs(rsocks) do
        local h = socks[s]
        if h then
            h(s)
        end
    end
    return nonblock
end

-----------------------------------------------------------------------------
-- End exported functions
-----------------------------------------------------------------------------
