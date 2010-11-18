-----------------------------------------------------------------------------
-- ALua
--
-- version: 1.1 2010/05/30
-----------------------------------------------------------------------------

module("alua", package.seeall)

local raw       = require("rawsend")
local event     = require("alua.event")
local marshal   = require("alua.marshal")
local tcp       = require("alua.tcp")
local task      = require("alua.task")
local mbox      = require("alua.mbox")
local thread    = require("alua.thread")
local core      = require("alua.core")
local network   = require("alua.network")
local dht       = require("alua.dht")
local group     = require("alua.group")
local timer     = require("alua.timer")

-----------------------------------------------------------------------------
-- Local aliases
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Global variables
-----------------------------------------------------------------------------
alua.id         = nil
alua.router     = nil
alua.daemonid   = nil
alua.isdaemon   = false
alua.isrouter   = false

-- Message status
ALUA_STATUS_OK      = "ok"
ALUA_STATUS_ERROR   = "error"

-----------------------------------------------------------------------------
-- Module variables
-----------------------------------------------------------------------------
local sock          = nil
local server        = nil
local terminate     = false
local data_handler  = nil

-- Internal ALua events
local ALUA_FORK                 = "alua-fork"
local ALUA_FORK_REPLY           = "alua-fork-reply"
local ALUA_FORK_CODE            = "alua-fork-code"
local ALUA_FORK_CODE_REPLY      = "alua-fork-code-reply"
local ALUA_EXECUTE              = "alua-execute"
local ALUA_EXECUTE_REPLY        = "alua-execute-reply"
local ALUA_RECEIVE_DATA         = "alua-receive-data"
local ALUA_RECEIVE_DATA_REPLY   = "alua-receive-data-reply"
local ALUA_DISPATCHER           = "alua-dispatcher"
local ALUA_DISPATCHER_REPLY     = "alua-dispatcher-reply"

-----------------------------------------------------------------------------
-- Exported low-level functions
-----------------------------------------------------------------------------
-- Process' network functions
connect     = network.connect
create      = network.create
link        = network.link

-- Thead's pool management
inc_threads = thread.inc_threads
dec_threads = thread.dec_threads

-- Event handlers management
reg_event   = event.register
unreg_event = event.unregister

tostring    = marshal.dump

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
-- Creates a new ALua process (through a new event)
--
-- @param dst The new ALua process deamon
-- @param chunck The initial process code
-- @param cd The callback function that the new Lua process will call
--
-- @return True when the message (or event) was routed
--         False and the error message when threre is no route to the
--         destination
-----------------------------------------------------------------------------
local function newprocess(dst, chunk, cb)
    -- Checks if the process is conected to a daemon
    if alua.id then
        -- Creates the "create a new ALua process" event
        local tb = {
            type    = ALUA_FORK,
            src     = alua.id,
            dst     = dst,
            chunk   = chunk,
        }
        -- Sets the callback if it exists
        if cb then
            tb.cb = event.setcb(cb)
        end
        -- Route the message
        return network.routemsg(tb.dst, tb)
    end
    return false, "not connected"
end -- function newprocess
-----------------------------------------------------------------------------
-- End auxiliary functions
-----------------------------------------------------------------------------

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
local function execute(msg)
    local succ, e = dostring(msg.chunk)
    if msg.cb then
        local tb = {
            type        = ALUA_EXECUTE_REPLY,
            src         = alua.id,
            dst         = msg.src,
            cb          = msg.cb,
        }
        if succ then
            tb.status   = ALUA_STATUS_OK
        else
            tb.error    = e
            tb.status   = ALUA_STATUS_ERROR
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
        cb({src=msg.src, status=ALUA_STATUS_ERROR, error=msg.error})
    else
        cb({src=msg.src, status=ALUA_STATUS_OK})
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
            tb.status   = ALUA_STATUS_ERROR
        else
            tb.status   = ALUA_STATUS_OK
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
        cb({src=msg.src, status=ALUA_STATUS_ERROR, error=msg.error})
    else
        cb({src=msg.src, status=ALUA_STATUS_OK})
    end
end -- function receive_data_reply


-----------------------------------------------------------------------------
-- "Create a new ALua process" event handler
-- Message definition:
--      type    ALUA_FORK
--      src     the requester id
--      dst     the destination daemon id
--      chunk   the initial's new process code
-----------------------------------------------------------------------------
local function fork(msg)
    local chunk = msg.chunk

    -- The original process
    -- original caller of 'newprocess'
    local srcfrk, cbfrk = msg.src, msg.cb

    -- The new process will call this callback
    local function callback(m)
        local tb = {
            type    = ALUA_FORK_CODE_REPLY,
            src     = alua.id,
            dst     = m.src,    -- new process
            chunk   = chunk,
            status  = ALUA_STATUS_OK,
            srcfrk  = srcfrk,   -- original process
            cbfrk   = cbfrk,    -- original process callback
        }
        network.routemsg(tb.dst, tb)
    end -- callback function

    -- Daemon callback
    local daemoncb = event.setcb(callback)
    -- Daemon ip and port
    local dip, dport = string.match(alua.id, "^(%d+%.%d+%.%d+%.%d+):(%d+)")

    -- Creates a new process and starts the lauch function
    core.execute("lua", "-l", "alua", "-e",
                string.format("alua.launch(%q, %s, %d)", dip, dport, daemoncb))
end -- function fork


-----------------------------------------------------------------------------
-- "Create a new ALua process reply" event handler
-- Message definition:
--      type    ALUA_FORK_REPLY
--      status  ALUA_STATUS_OK or ALUA_STATUS_ERROR
--      src     the new process id
--      dst     the requester id
--      cb      requester callback
-----------------------------------------------------------------------------
local function fork_reply(msg)
    local cb = event.getcb(msg.cb)
    cb({status=msg.status, id=msg.src})
end -- function fork_reply


-----------------------------------------------------------------------------
-- "Fork code" event handler
-- Message definition:
--      type    ALUA_FORK_CODE
--      src     the new process id
--      dst     the daemon id
--      cb      the new process callback
-----------------------------------------------------------------------------
local function fork_code(msg)
    local cb = event.getcb(msg.cb)
    cb(msg)
end -- function fork_code


-----------------------------------------------------------------------------
-- "Fork code reply" event handler
-- Message definition:
--      type    ALUA_FORK_CODE_REPLY
--      status  ALUA_STATUS_OK or ALUA_STATUS_ERROR
--      src     the daemon id
--      dst     new process id
--      chunk   the initial new process code
--      srcfrk  the requeter id
--      cbfrk   the requester callback
-----------------------------------------------------------------------------
local function fork_code_reply(msg)
    -- TODO Antes de enviar a resposta verificar se o código inicial executou com sucesso. Provavelmente a chamada de execute no final terá que ser modifica. Talvez chamar o dostring daqui mesmo. (ISSUE #2)
    if msg.cbfrk then
        local tb = {
            type    = ALUA_FORK_REPLY,
            src     = alua.id,
            dst     = msg.srcfrk,
            status  = ALUA_STATUS_OK,
            cb      = msg.cbfrk,
        }
        network.routemsg(tb.dst, tb)
    end
    execute(msg)
end -- function fork_code_reply


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
        cb({src=msg.src, status=ALUA_STATUS_ERROR, error=msg.error})
    else
        cb({src=msg.src, status=ALUA_STATUS_OK})
    end
end -- function dispatcher_reply
-----------------------------------------------------------------------------
-- End event handles
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Registered events
-----------------------------------------------------------------------------
event.register(ALUA_FORK,               fork)
event.register(ALUA_FORK_REPLY,         fork_reply)
event.register(ALUA_FORK_CODE,          fork_code)
event.register(ALUA_FORK_CODE_REPLY,    fork_code_reply)

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
-- API functions
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
            msg.cb  = event.setcb(cb)
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
        if cb then
            msg.cb  = event.setcb(cb)
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
-- Lauch a process and conect it to a daemon
--
-- @param ip the daemon ip
-- @param port the daemon port
-- @param code the initial code to execute
-- @param cb the callback function
-----------------------------------------------------------------------------
function launch(ip, port, cb)
    -- begin function
    local function conncb(r)
        if r.status == ALUA_STATUS_OK then
            local tb = {
                type    = ALUA_FORK_CODE,
                src     = alua.id,
                dst     = alua.daemonid,
                cb      = cb,
            }
            network.routemsg(tb.dst, tb)
        else
            io.stderr:write(string.format("*** %s\n", r.error))
        end
    end
    -- end function

    local succ, e = connect(ip, port, conncb)
    if not succ then
        io.stderr:write(string.format("*** %s\n", e))
        return
    end

    network.connecting = true

    return loop()
end -- function launch


-----------------------------------------------------------------------------
-- Function to cicle one time through the event loop. Used to integrate the
-- event loop of this process with a bigger event loop
-----------------------------------------------------------------------------
function step()
    local nonblock = task.process()
    nonblock = nonblock or mbox.process()
    if alua.isrouter or network.connecting then
        nonblock = nonblock or tcp.process()
    end
    return nonblock
end -- function step


-----------------------------------------------------------------------------
-- The process event loop
-----------------------------------------------------------------------------
function loop()
    if alua.isrouter or network.connecting then
        while not terminate do
            local nonblock = task.process()
            nonblock = nonblock or mbox.process()
            tcp.process(not nonblock)
        end
    else
        while not terminate do
            task.process()
            mbox.process(not task.hasdata)
        end
    end
end -- function loop


-----------------------------------------------------------------------------
-- Create a new Lua process
--
-- @param code the initial code to execute
-- @param luap true if the new process is a Lua process
--             fasle if the new process is a ALua process
-- @param cb the callback function
--
-- @return true if the request was sent
--         false and the error message if there's a error
-----------------------------------------------------------------------------
function spawn(code, luap, cb)
    if luap then
        return thread.create(code, cb)
    else
        return newprocess(alua.daemonid, code, cb)
    end
end -- function spawn


-----------------------------------------------------------------------------
-- Terminate the event loop and quit the process
-----------------------------------------------------------------------------
function quit()
    terminate = true
end -- function quit


-----------------------------------------------------------------------------
-- Get the daemons list
--
-- @return the daemons list
-----------------------------------------------------------------------------
function getdaemons()
    local daemonlist = {}
    if alua.id == alua.daemonid then
        local function callback(reply)
            if reply.status == dht.DHT_STATUS_OK then
                for k,v in pairs(reply.nodes) do
                    print(k,v)
                end
                return reply.nodes
            else
                return nil
            end
        end
        -- TODO Pensar melhor em como isto será retornado ao chamador
        -- Talvez deixa a aplicação externa informar a callback
        dht.get_nodes(callback)

    else
        return nil, "not allowed"
    end
end -- function getdaemons


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


-----------------------------------------------------------------------------
-- Stores a pair (key, value)
--
-- @param key the key
-- @param value the value
-- @param callback the callback function
--
-- @return 
-----------------------------------------------------------------------------
function dht_insert(key, value, callback)
    -- TODO Serializar nesse ponto o valor e assim já fazer a verificação se é possível
    dht.insert_pair(alua.id, key, value, callback)
end -- function dht_insert


-----------------------------------------------------------------------------
-- Delete a pair (key, value)
--
-- @param key the pair's key
-- @param callback the callback function
--
-- @return 
-----------------------------------------------------------------------------
function dht_delete(key, callback)
    dht.delete_pair(alua.id, key, callback)
end -- function dht_delete


-----------------------------------------------------------------------------
-- Lookup for a pair (key, value)
--
-- @param key the lookup key
-- @param callback the callback function
--
-- @return 
-----------------------------------------------------------------------------
function dht_lookup(key, callback)
    return dht.lookup(alua.id, key, callback)
end -- function dht_lookup


-----------------------------------------------------------------------------
-- Creates a group of processes
--
-- @param groupname the group's name
-- @param callback the callback function
--
-- @return 
-----------------------------------------------------------------------------
function group_create(groupname, callback)
    return group.group_create(alua.id, groupname, callback)
end -- function group_create


-----------------------------------------------------------------------------
-- Deletes a group
--
-- @param groupname the group's name
-- @param callback the callback function
--
-- @return 
-----------------------------------------------------------------------------
function group_delete(groupname, callback)
    return group.group_delete(alua.id, groupname, callback)
end -- function group_delete


-----------------------------------------------------------------------------
-- Joins a group
--
-- @param groupname the group's name
-- @param callback the callback function
--
-- @return 
-----------------------------------------------------------------------------
function group_join(groupname, callback)
    return group.group_join(alua.id, groupname, callback)
end -- function group_join


-----------------------------------------------------------------------------
-- Leaves a group
--
-- @param groupname the group's name
-- @param callback the callback function
--
-- @return 
-----------------------------------------------------------------------------
function group_leave(groupname, callback)
    return group.group_leave(alua.id, groupname, callback)
end -- function group_leave
-----------------------------------------------------------------------------
-- End API functions
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- End alua
-----------------------------------------------------------------------------


-- TODO DEBUG
function print_neighbor()
    local request = {
        type = dht.DHT_PRINT_NEIGHBOR,
        dst = alua.daemonid,
        nodes = {}
    }
    network.routemsg(alua.daemonid, request)
end
