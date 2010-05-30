-----------------------------------------------------------------------------
-- Thread
--
-- Module to manage the tread pool and create new Lua process
--
-- version: 1.1 2010/05/30
-----------------------------------------------------------------------------

module ("alua.thread", package.seeall)

local ccr     = require("ccr")
local alua    = require("alua")
local event   = require("alua.event")
local uuid    = require("uuid")

-----------------------------------------------------------------------------
-- Modules variables
-----------------------------------------------------------------------------
local pending = {}
local callbacks = {}

-- Thread reply event name
ALUA_THREAD_REPLY = "alua-thread-reply"

-----------------------------------------------------------------------------
-- Auxiliary functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Creates a unique id
--
-- @return the unique id
-----------------------------------------------------------------------------
local function nextid()
    return uuid.create("siv", true)
end

-----------------------------------------------------------------------------
-- Sets a thread's callback
--
-- @param cb the callback
--
-- @return the callback id
-----------------------------------------------------------------------------
local function setcb(cb)
    local idx = #pending + 1
    pending[idx]    = true
    callbacks[idx]  = cb
    return idx
end

-----------------------------------------------------------------------------
-- Gets a thread's callback
--
-- @param idx the callback id
--
-- @return the callcack
-----------------------------------------------------------------------------
local function getcb(idx)
    local cb = callbacks[idx]
    pending[idx]    = nil
    callbacks[idx]  = nil
    return cb
end

-----------------------------------------------------------------------------
-- End auxiliary functions
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Events handlers
-----------------------------------------------------------------------------
local function reply(msg)
    local cb = getcb(msg.cb)
    local reply = {
        status  = alua.ALUA_STATUS_OK,
        id      = msg.src
    }
    cb(reply)
end

-- Registers the handlers to the thread-reply event
event.register(ALUA_THREAD_REPLY, reply)

-----------------------------------------------------------------------------
-- End events handlers
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Exported functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Creates a new Lua process
--
-- @param code the process initial code
-- @param cb the process callback
--
-- @return true if the process was created and false otherwise
-----------------------------------------------------------------------------
function create(code, cb)
    local pre = ""
    if cb then
        -- Send a reply from the new process to the sender
        local idx = setcb(cb)
        pre = string.format([[
            do
                local tb = {
                    type    = %q,
                    src     = alua.id,
                    dst     = %q,
                    cb      = %d,
                }
                alua.mbox.send(tb.dst, tb)
            end
            ]], ALUA_THREAD_REPLY, alua.id, idx)
    end

    return ccr.spawn(string.format([[
        require("alua")
        alua.id = "%s/%s"
        alua.daemonid = %q
        alua.router = %q
        alua.mbox.register(alua.id)
        -- Callback
        %s
        -- Code
        %s
        -- Loop
        alua.loop()
        ]], alua.router, nextid(), alua.daemonid, alua.router, pre, code))
end

-----------------------------------------------------------------------------
-- Increments the thread's pool
--
-- @param qtd the number of threads to create
--
-- @return the new thread's pool size or zero and a error message in case of
--         failure
-----------------------------------------------------------------------------
function inc_threads(qtd)
   return ccr.inc_workers(qtd)
end

-----------------------------------------------------------------------------
-- Decreases the thread's pool
--
-- @param qtd the number of threads to finalize
--
-- @return the new thread's pool size or zero and a error message in case of
--         failure
-----------------------------------------------------------------------------
function dec_threads(qtd)
   return ccr.dec_workers(qtd)
end

-----------------------------------------------------------------------------
-- End exported functions
-----------------------------------------------------------------------------
