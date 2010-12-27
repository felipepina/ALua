-----------------------------------------------------------------------------
-- ALua
--
-- version: 1.1 2010/05/30
-----------------------------------------------------------------------------

module("alua.message", package.seeall)

local alua      = require("alua")
local event     = require("alua.event")
local network   = require("alua.network")
local marshal   = require("alua.marshal")
local util      = require("alua.util")

-----------------------------------------------------------------------------
-- Local aliases
-----------------------------------------------------------------------------
local isTable = util.isTable
local copyTable = util.copyTable

-----------------------------------------------------------------------------
-- Module variables
-----------------------------------------------------------------------------

-- Internal events
local ALUA_EXECUTE              = "alua-execute"
local ALUA_EXECUTE_REPLY        = "alua-execute-reply"
local ALUA_RECEIVE_DATA         = "alua-receive-data"
local ALUA_RECEIVE_DATA_REPLY   = "alua-receive-data-reply"
local ALUA_DISPATCHER           = "alua-dispatcher"
local ALUA_DISPATCHER_REPLY     = "alua-dispatcher-reply"

-----------------------------------------------------------------------------
-- Auxiliary functions
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Executes a string
--
-- @param str The code to execute
--
-- @return True if the code was executed
--         False and the error message if there's a error
-----------------------------------------------------------------------------
local function dostring(str)
    local f, succ, errmsg
    f, errmsg = loadstring(str)
    if f then
        succ, errmsg = pcall(f)
    end
    return succ, errmsg
end -- function dostring


-----------------------------------------------------------------------------
-- Event handlers
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Execute event handler
-- Message definition:
--      type    ALUA_EXECUTE
--      src     the sender ip
--      dst     the destination id
--      chunk   the code to execute in the destination
--      cb      the sender callback
-----------------------------------------------------------------------------
-- local function execute(msg)
function execute(msg)
    local succ, e = dostring(msg.chunk)
    if msg.cb then
        local tb = {
            type        = ALUA_EXECUTE_REPLY,
            src         = alua.id,
            dst         = msg.src,
            cb          = msg.cb,
        }
        if succ then
            tb.status   = alua.ALUA_STATUS_OK
        else
            tb.error    = e
            tb.status   = alua.ALUA_STATUS_ERROR
        end
        network.routemsg(tb.dst, tb)
    end
end -- function execute


-----------------------------------------------------------------------------
-- Execute reply event handler
-- Message definition:
--      type    ALUA_EXECUTE_REPLY
--      status  ALUA_STATUS_OK or ALUA_STATUS_ERROR
--      error   error message if status = ALUA_STATUS_ERROR
--      src     the destinatio id
--      dst     the sender id
--      cb      the sender callback
-----------------------------------------------------------------------------
local function execute_reply(msg)
    local cb = event.getcb(msg.cb)
    if msg.error then
        cb({src=msg.src, status=alua.ALUA_STATUS_ERROR, error=msg.error})
    else
        cb({src=msg.src, status=alua.ALUA_STATUS_OK})
    end
end -- function execute_reply


-----------------------------------------------------------------------------
-- "Receive data" event handler
-- Message definition:
--      type    ALUA_RECEIVE_DATA
--      src     the sender ip
--      dst     the destination id
--      data    the data
--      cb      the sender callback
-----------------------------------------------------------------------------
local function receive_data(msg)
    local succ = nil
    -- TODO tratar erro na decodificacao
    local data, error = marshal.decode(msg.data)

    -- Call the event handle if it exists and the data was decoded
    if not error then
        if data_handler then
            data_handler(data)
            succ = true
        else
            succ = false
            error = "no handle registered in the destination"
        end
    end

    if msg.cb then
        local tb = {
            type        = ALUA_RECEIVE_DATA_REPLY,
            src         = alua.id,
            dst         = msg.src,
            cb          = msg.cb
        }

        -- Checks for error
        if error then
            tb.error    = error
            tb.status   = alua.ALUA_STATUS_ERROR
        else
            tb.status   = alua.ALUA_STATUS_OK
        end

        network.routemsg(tb.dst, tb)
    end
end -- function receive_data


-----------------------------------------------------------------------------
-- "Receive data reply" event handler
-- Message definition:
--      type    ALUA_RECEIVE_DATA_REPLY
--      status  ALUA_STATUS_OK or ALUA_STATUS_ERROR
--      error   error message if status = ALUA_STATUS_ERROR
--      src     the destinatio id
--      dst     the sender id
--      cb      the sender callback
-----------------------------------------------------------------------------
local function receive_data_reply(msg)
    local cb = event.getcb(msg.cb)
    if msg.error then
        cb({src=msg.src, status=alua.ALUA_STATUS_ERROR, error=msg.error})
    else
        cb({src=msg.src, status=alua.ALUA_STATUS_OK})
    end
end -- function receive_data_reply

-----------------------------------------------------------------------------
-- Dispatch event handler
-- Message definition:
--      type    ALUA_DISPATCHER
--      usrtype event's user type
--      scr     the sender's id
--      dst     the destination
--      data    the data
--      cb      the sender's callback
-----------------------------------------------------------------------------
local function dispatcher(msg)
    -- Original sender and sender's callback function
    local sender, sendercb = msg.src, msg.cb

    local function dispatchercb(status, error)
        local reply = {
            type    = ALUA_DISPATCHER_REPLY,
            status  = status,
            error   = error,
            src     = alua.id,
            dst     = sender,
            cb      = sendercb
        }

        network.routemsg(reply.dst, reply)
    end -- function dispatchercb

    -- Build the user event message
    local usermsg = {
        type        = msg.usrtype,
        src         = msg.src,
        dst         = msg.dst,
        data        = marshal.decode(msg.data)
    }
    if msg.cb then
        usermsg.cb  = dispatchercb
    end

    -- process the message
    event.process(usermsg)
end -- function dispatcher


-----------------------------------------------------------------------------
-- Dispatch reply event handler
-- Message definition:
--      type    ALUA_DISPATCHER_REPLY
--      status  ALUA_STATUS_OK or ALUA_STATUS_ERROR
--      error   error message if status = ALUA_STATUS_ERROR
--      scr     the dispatch destination's id
--      dst     the dispatch event sender's id
--      cb      the dispatch evetn sender's callback
-----------------------------------------------------------------------------
local function dispatcher_reply(msg)
    local cb = event.getcb(msg.cb)
    if msg.error then
        cb({src=msg.src, status=alua.ALUA_STATUS_ERROR, error=msg.error})
    else
        cb({src=msg.src, status=alua.ALUA_STATUS_OK})
    end
end -- function dispatcher_reply
-----------------------------------------------------------------------------
-- End event handles
-----------------------------------------------------------------------------



-----------------------------------------------------------------------------
-- Registered events
-----------------------------------------------------------------------------
event.register(ALUA_EXECUTE,            execute)
event.register(ALUA_EXECUTE_REPLY,      execute_reply)
event.register(ALUA_RECEIVE_DATA,       receive_data)
event.register(ALUA_RECEIVE_DATA_REPLY, receive_data_reply)
event.register(ALUA_DISPATCHER,         dispatcher)
event.register(ALUA_DISPATCHER_REPLY,   dispatcher_reply)
-----------------------------------------------------------------------------
-- End registered events
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Exported functions
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Send a message to execute in the destination
--
-- @param dst the message destination
-- @param str the code to execute
-- @param cb the callback function
--
-- @return true if the message was sent
--         false and the error message if there's a error
-----------------------------------------------------------------------------
function send(dst, str, cb)
    if alua.id then
        local msg = {
            type    = ALUA_EXECUTE,
            src     = alua.id,
            dst     = dst,
            chunk   = str
        }
        if cb then
            if #dst == 1 then
                msg.cb  = event.setcb(cb)
            else
                msg.cb  = event.setpcb(cb, #dst)
            end
        end
        
        return network.routemsg(dst, msg)
    end
    return false, "not connected"
end -- function send


-----------------------------------------------------------------------------
-- Send data to the destination
--
-- @param dst the message destination
-- @param data the data
-- @param cb the callback function
--
-- @return true if the message was sent
--         false and the error message if there's a error
-----------------------------------------------------------------------------
function send_data(dst, data, cb)
    if alua.id then
        local encoded_data, error = marshal.encode(data)

        if error then
            return false, error
        end

        local msg = {
            type    = ALUA_RECEIVE_DATA,
            src     = alua.id,
            dst     = dst,
            data    = encoded_data
        }
        -- TODO Quando é informado uma cb e uma lista de destinatarios somente na primeira resposta a cb é executada
        -- nas outras a cb já foi retirada da lista de cb pendentes
        if cb then
            if #dst == 1 then
                msg.cb  = event.setcb(cb)
            else
                msg.cb  = event.setpcb(cb)
            end
        end

        return network.routemsg(dst, msg)
    end
    return false, "not connected"
end -- function send_data


-----------------------------------------------------------------------------
-- Register a receive data event handler
--
-- @param handler the event handler
-----------------------------------------------------------------------------
function reg_data_handler(handler)
    data_handler = handler
end -- function register_listener

-----------------------------------------------------------------------------
-- Sends a event to a process
--
-- @param dst the process id
-- @param event_type the event's type
-- @param data the data to be send
-- @param cb the callback function
--
-- @return true if the message was sent
--         false and the error message if there's a error
-----------------------------------------------------------------------------
function send_event(dst, event_type, data, cb)
    if alua.id then
        local encoded_data, error = marshal.encode(data)

        if error then
            return false, error
        end

        local msg = {
            type    = ALUA_DISPATCHER,
            usrtype = event_type,
            src     = alua.id,
            dst     = dst,
            data    = encoded_data
        }
        if cb then
            msg.cb  = event.setcb(cb)
        end

        return network.routemsg(dst, msg)
    end
    return false, "not connected"
end -- function send_event


