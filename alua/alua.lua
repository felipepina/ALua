-----------------------------------------------------------------------------
-- ALua
--
-- version: 1.1 2010/05/15
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

-----------------------------------------------------------------------------
-- Local aliases
-----------------------------------------------------------------------------
local load      = marshal.load
local process   = event.process
local receive   = tcp.receive
local match     = string.match
local format    = string.format
local newthread = thread.create

-----------------------------------------------------------------------------
-- Global variables
-----------------------------------------------------------------------------
local sock
local server
local prefix
local connecting
local count = 0

-- Daemons list
local daemons = {}
-- TODO separar a list de daemons em duas
-- uma referenciando sockets e outra referenciando daemonid

-- Process list (only on main Lua process)
local processes = {}


-- Callback list
local callbacks = {}
-- Callback list
local contexts = {}
-- Pending callbacks list
local pending = {}

local terminate = false
local receive_handler

-- Internal ALua events
ALUA_AUTH               = "alua-auth"
ALUA_AUTH_REPLY         = "alua-auth-reply"
ALUA_FORK               = "alua-fork"
ALUA_FORK_REPLY         = "alua-fork-reply"
ALUA_CODE               = "alua-fork-code"
ALUA_CODE_REPLY         = "alua-fork-code-reply"
ALUA_EXECUTE            = "alua-execute"
ALUA_EXECUTE_REPLY      = "alua-execute-reply"
ALUA_RECEIVE_DATA       = "alua-receive-data"
ALUA_RECEIVE_DATA_REPLY = "alua-receive-data-reply"
ALUA_LINK_START         = "alua-link-start"
ALUA_LINK_REPLY         = "alua-link-start-reply"
ALUA_LINK_DAEMON        = "alua-link-daemon"
ALUA_LINK_REPLY         = "alua-link-daemon-reply"
ALUA_BONJOUR            = "alua-bonjour"
ALUA_ROUTE              = "alua-route"

-----------------------------------------------------------------------------
-- Exported low-level functions
-----------------------------------------------------------------------------
inc_threads = thread.inc_threads
dec_threads = thread.dec_threads
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
end

local function nextid()
    count = count + 1
    return count
end -- function dostring

-----------------------------------------------------------------------------
-- Sets the callback function within a context
--
-- @param cb The callback
-- @param ctx The context
--
-- @return The callback id
-----------------------------------------------------------------------------
local function setcb(cb, ctx)
    local idx = #pending + 1
    pending[idx] = true
    contexts[idx] = ctx
    callbacks[idx] = cb
    return idx
end -- function setcb

-----------------------------------------------------------------------------
-- Gets the callback function
--
-- @param idx The callback id
--
-- @return The callback function and the context
-----------------------------------------------------------------------------
local function getcb(idx)
    local cb = callbacks[idx]
    local ctx = contexts[idx]
    pending[idx] = nil
    contexts[idx] = nil
    callbacks[idx] = nil
    return cb, ctx
end -- function getcb

-- TODO Completar documentação
-----------------------------------------------------------------------------
-- Listens and process messages received in a socket
--
-- @param sock The socket
-----------------------------------------------------------------------------
local function listen(sock)
    -- Receive through TCP
    local str, err = receive(sock)
    if err then
        local idx = processes[sock]
        if idx then
            processes[idx] = nil
            processes[sock] = nil
        else
            idx = daemons[sock]
            if idx then
                daemons[idx] = nil
                daemons[sock] = nil
            end
        end
        tcp.close(sock)
        return true  -- stop activate the socket
    end
    local succ, msg = load(str)
    msg.sock = sock
    -- Process the message (event)
    process(msg)
end

-----------------------------------------------------------------------------
-- Gets the next hop id in the route to a destination
--
-- @param dst The destination to find a route
--            In the format <ip>:<port>/<id>/<seq_id>
-- @return The next hop id. In the format <ip>:<port>/<id>/<seq_id>
-----------------------------------------------------------------------------
local function nexthopid(dst)
    -- Looks in the process list for a direct conection
    if processes[dst] then
        return dst
    end

    -- Looks in the daemons list for a direct connection
    if daemons[dst] then
        return dst
    end
    
    -- there isn't a direct conection to the dst
    -- thus the next hop is the corresponding daemon
    dst = match(dst, "^(%d+%.%d+%.%d+%.%d+:%d+)") .. "/0"
    return dst
end -- function nexthopid

-----------------------------------------------------------------------------
-- Gets the next hop connection in the route to a destination
--
-- @param dst The destination to find the route.
--            In the format <ip>:<port>/<id>/<seq_id>
-- @return The next hop connection (socket)
-----------------------------------------------------------------------------
local function nexthop(dst)
    local conn = processes[dst]
    -- Looks in the process list for a direct conection
    if not conn then
        conn = daemons[dst]
        -- Looks in the daemons list for a direct connection
        if not conn then
            -- there isn't a direct conection to the dst
            -- thus the next hop is the corresponding daemon
            dst = match(dst, "^(%d+%.%d+%.%d+%.%d+:%d+)") .. "/0"
            conn = daemons[dst]
        end
    end
    return conn
end -- function nexthop

-----------------------------------------------------------------------------
-- Routes a messagem to its destination
--
-- @param dst The destination. In the format <ip>:<port>/<id>/<seq_id>
-- @msg The message
--
-- @return True when the message was routed to the destination
--         False and the error message when there's a error
-----------------------------------------------------------------------------
local function routemsg(dst, msg)
    -- The destination is itself? If so put in the task queue
    if dst == alua.id then
        task.schedule(process, msg)
        return true
    else
        -- The destination is in same ALua process?
        -- If true, sends through the intra-process queue (CCR)
        local proc = match(dst, "^(%d+%.%d+%.%d+%.%d+:%d+/%d+)")
        -- TODO 
        print("proc", proc)
        if proc == match(alua.id, "^(%d+%.%d+%.%d+%.%d+:%d+/%d+)") then
            return mbox.send(dst, msg)
        else
            -- Routes the message: send to router or daemon
            msg = {type = "route", message = msg}
            if alua.isdaemon then -- Send to router
                local conn = nexthop(proc)
                -- TODO Retitar linha abaixo
                --local conn = nexthopid(proc)
                if not conn then
                    return false, "unknown destination"
                else
                    -- TODO 
                    print("tcp.send", alua.id, conn, tostring(msg))
                    return tcp.send(conn, msg)
                    --return tcp.rawsend(conn, msg)
                end
            else -- Send to daemon
                -- TODO 
                print("tcp.rawsend", alua.id, alua.daemonid, tostring(msg))
                return tcp.rawsend(alua.daemonid, msg)
            end
        -- TODO Retirar linhas abaixo
        --elseif alua.isrouter then
        --    return tcp.send(sock, msg)
        --else
        --    return mbox.send(alua.router, msg)
        --end
        end
    end
end -- function routemsg

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
            type    = "fork",
            src     = alua.id,
            dst     = dst,
            chunk   = chunk,
        }
        -- Sets the callback if it exists
        if cb then
            tb.cb = setcb(cb)
        end
        -- Route the message
        return routemsg(tb.dst, tb)
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
-- "Connection request" event handler
-- Message definition:
--      type    = "auth"
--      cb      the requester's callback function id
--      sock    the socket where the messagem arrived
--              (puts by the listen function)
-----------------------------------------------------------------------------
local function auth(msg)
    -- Creates a new id to the requester process
    local id = prefix .. "/" .. tostring(nextid())
    
    -- Puts the process in the processes list
    processes[id] = msg.sock
    processes[msg.sock] = id

    -- Registers the pair (process id, socket)
    raw.setfd(id, msg.sock:getfd());
    local tb = {
        type = "auth-reply",
        status = "ok",
        id = id,
        daemonid = alua.id,
        cb = msg.cb,
    }
    -- TODO Não pode ocorrer algum erro? Verificar

    -- Sends through a shared socket
    tcp.rawsend(id, tb)
    --tcp.send(msg.sock, tb)
end

-----------------------------------------------------------------------------
-- "Connection request reply" event handler
-- Message definition:
--      type        = "auth-reply"
--      status      "ok" or "error"
--      id          the created id of the process
--      daemonid    the daemon id
--      cb          the requester's callback function id
-----------------------------------------------------------------------------
local function auth_reply(msg)
    connecting = nil
    alua.id = msg.id
    alua.router = msg.id
    alua.daemonid = msg.daemonid
    
    -- Register the pair (daemon id, socket) 
    raw.setfd(alua.daemonid, msg.sock:getfd())
    alua.isrouter = true
    mbox.register(alua.id)

    -- Invoke the callback if there's one
    if msg.cb then
        local cb = getcb(msg.cb)
        if cb then
            cb({status="ok", id=msg.id, daemonid=msg.daemonid})
        end
    end
end

-----------------------------------------------------------------------------
-- Execute event handler
-- Message definition:
--      type    = "execute"
--      src     the sender ip
--      dst     the destination id
--      chunk   the code to execute in the destination
--      cb      the sender callback
-----------------------------------------------------------------------------
local function execute(msg)
    -- TODO 
    if not msg.chunk then
        print("\n\n")
        print("execute", alua.id, msg.type, msg.src, msg.dst, msg.cb)
        print("\n\n")
    end
    local succ, e = dostring(msg.chunk)
    if msg.cb then
        local tb = {
            type = 'execute-reply',
            src = alua.id,
            dst = msg.src,
            cb = msg.cb,
        }
        if succ then
            tb.status = "ok"
        else
            tb.error = e
            tb.status = "error"
        end
        routemsg(tb.dst, tb)
    end
end

-----------------------------------------------------------------------------
-- Execute reply event handler
-- Message definition:
--      type    = 'execute-reply'
--      status  "ok" or "error"
--      error   error message if status = "error"
--      src     the destinatio id
--      dst     the sender id
--      cb      the sender callback
-----------------------------------------------------------------------------
local function execute_reply(msg)
    local cb = getcb(msg.cb)
    if msg.error then
        cb({src=msg.src, status="error", error=msg.error})
    else
        cb({src=msg.src, status="ok"})
    end
end

-----------------------------------------------------------------------------
-- "Receive data" event handler
-- Message definition:
--      type    = "receive-data"
--      src     the sender ip
--      dst     the destination id
--      data    the data
--      cb      the sender callback
-----------------------------------------------------------------------------
local function receive_data(msg)
    data = marshal.decode(msg.data)
    
    -- Call the event handle if it exists
    if receive_callback then
        receive_callback(data)
        succ = true
    else
        succ = false
    end

    if msg.cb then
        local tb = {
            type = 'receive-data-reply',
            src = alua.id,
            dst = msg.src,
            cb = msg.cb,
        }

        -- If not return a error to the sender
        if succ then
            tb.status = "ok"
        else
            tb.error = "no handle registered in the destination"
            tb.status = "error"
        end

        routemsg(tb.dst, tb)
    end
end

-----------------------------------------------------------------------------
-- "Receive data reply" event handler
-- Message definition:
--      type    = 'receive-data-reply'
--      status  "ok" or "error"
--      error   error message if status = "error"
--      src     the destinatio id
--      dst     the sender id
--      cb      the sender callback
-----------------------------------------------------------------------------
local function receive_data_reply(msg)
    local cb = getcb(msg.cb)
    if msg.error then
        cb({src=msg.src, status="error", error=msg.error})
    else
        cb({src=msg.src, status="ok"})
    end
end

-----------------------------------------------------------------------------
-- "Create a new ALua process" event handler
-- Message definition:
--      type    = "fork"
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
            type    = "fork-code-reply",
            src     = alua.id,
            dst     = m.src,    -- new process
            chunk   = chunk,
            status  = "ok",
            srcfrk  = srcfrk,   -- original process
            cbfrk   = cbfrk,    -- original process callback
        }
        routemsg(tb.dst, tb)
    end -- callback function
    
    -- Daemon callback
    local daemoncb = setcb(callback)
    -- Daemon ip and port
    local dip, dport = match(alua.id, "^(%d+%.%d+%.%d+%.%d+):(%d+)")

    -- Creates a new process and starts the lauch function
    core.execute("lua", "-l", "alua", "-e", 
                format("alua.launch(%q, %s, %d)", dip, dport, daemoncb))
end

-----------------------------------------------------------------------------
-- "Create a new ALua process reply" event handler
-- Message definition:
--      type    = "fork-reply"
--      status  "ok" or "error"
--      src     the new process id
--      dst     the requester id
--      cb      requester callback
-----------------------------------------------------------------------------
local function fork_reply(msg)
    local cb = getcb(msg.cb)
    cb({status=msg.status, id=msg.src})
end

-----------------------------------------------------------------------------
-- "Fork code" event handler
-- Message definition:
--      type    = "fork-code"
--      src     the new process id
--      dst     the daemon id
--      cb      the new process callback
-----------------------------------------------------------------------------
local function fork_code(msg)
    local cb = getcb(msg.cb)
    cb(msg)
end

-----------------------------------------------------------------------------
-- "Fork code reply" event handler
-- Message definition:
--      type    = "fork-code-reply"
--      status  "ok" or "error"
--      src     the daemon id
--      dst     new process id
--      chunk   the initial new process code 
--      srcfrk  the requeter id
--      cbfrk   the requester callback
-----------------------------------------------------------------------------
local function fork_code_reply(msg)
    -- TODO Antes de enviar a resposta verificar se o codigo inicial executou com sucesso
    if msg.cbfrk then
        local tb = {
            type = "fork-reply",
            src = alua.id,
            dst = msg.srcfrk,
            status = "ok",
            cb = msg.cbfrk,
        }
        routemsg(tb.dst, tb)
    end
    execute(msg)
end

-----------------------------------------------------------------------------
-- "Link daemons start" event handler
-- Message definition:
--      type    = "link-start"
--      list    the daemons list
--      src     the requesterís id
--      dst     the daemon id
-----------------------------------------------------------------------------
local function link_start(msg)
    for _, d in ipairs(msg.list) do
        -- Only try to connect to new daemons
        if d ~= alua.id and not daemons[d] then
            local ip, port = match(d, "^(%d+%.%d+%.%d+%.%d+):(%d+)")
            -- Try to connect to the deamon
            local sock, err = tcp.connect(ip, tonumber(port), listen)
             if err then -- If couldn't connect
                local tb = {
                    type = "link-start-reply",
                    status = "error",
                    error = format("%q could not connect to daemon %q", alua.id, d),
                    src = alua.id,
                    dst = msg.src,
                    cb = msg.cb,
                }
                routemsg(tb.dst, tb)
                return
            else -- If connected
                -- Puts the deamon on the local list
                daemons[d] = sock
                daemons[sock] = d
                local tb = {
                    type = "bonjour",
                    mode = "daemon",
                    src = alua.id,
                    dst = d
                }
                -- Send a bounjour event to the new deamon
                -- The bonjour event creates a link between the tow daemons
                tcp.send(sock, tb)
            end
        end
    end

    local callback
    -- Checks if the sender have a callback
    if msg.cb then
        local c, l, dst = msg.cb, msg.list, msg.src
        local resp, count, err = true, #l - 1, nil
        
        callback = function (m)
            if resp then
                resp = (m.status == "ok")
                if not resp then
                    err =  m.error
                end
            end
            -- TODO Nao precisa verificar se o contador está em zero pois essa callback é chamada apenas uma vez
            -- count = count - 1
            -- if count == 0 then
                local tb = {
                    type = "link-start-reply",
                    src = alua.id,
                    dst = dst,
                    cb = c,
                }
                if resp then
                    tb.status = "ok"
                    tb.daemons = l
                else
                    tb.status = "error"
                    tb.error = err
                end
            routemsg(tb.dst, tb)
            -- end
        end -- function callback
    end

    -- Next daemon on the list
    local next
    for _, d in ipairs(msg.list) do
        if d ~= alua.id then
            next = d
            break
        end
    end
    
    -- Sends to the next daemon a link-daemon event
    local tb = {
        type    = "link-daemon",
        list    = msg.list,             -- original daemons list
        done    = {[alua.id] = true},   -- indicates the current daemon is in the network
        src     = alua.id,
        dst     = next,                 -- next daemon id
    }
    if callback then
        tb.cb = setcb(callback)
    end
    
    routemsg(tb.dst, tb)
end -- function link-start

-----------------------------------------------------------------------------
-- "Link daemons start reply" event handler
-- Message definition:
--      type    = "link-start-reply"
--      status  "ok" or "error"
--      error   error message if status = "error"
--      src     the first daemon id
--      dst     the requester id
--      cb      the requester callback
--      daemons the deamons list
-----------------------------------------------------------------------------
local function link_reply(msg)
    local cb = getcb(msg.cb)
    cb({status=msg.status, error=msg.error, daemons=msg.daemons})
end

-----------------------------------------------------------------------------
-- "Link daemons" event handler
-- Message definition:
--      type    = "link-daemon"
--      list    the daemons list
--      done    the connected daemons list
--      src     the current daemon id
--      dst     the next daemon id
--      cb      the currente daemon callback
-----------------------------------------------------------------------------
local function link_daemon(msg)
    for _, d in ipairs(msg.list) do
        -- Only try to connect to new daemons
        if d ~= alua.id and not daemons[d] then
            local ip, port = match(d, "^(%d+%.%d+%.%d+%.%d+):(%d+)")
            -- Try to connect to deamon
            local sock, err = tcp.connect(ip, tonumber(port), listen)
            if err then -- If couldn't connect
                if msg.cb then
                    local tb = {
                        type="link-daemon-reply",
                        status = "error",
                        error = format("%q could not connect to daemon %q", alua.id, d),
                        src = alua.id,
                        dst = msg.src,
                        cb = msg.cb,
                    }
                    routemsg(tb.dst, tb)
                end
                return
            else -- If connected
                -- Puts the deamon on the local list
                daemons[d] = sock
                daemons[sock] = d
                local tb = {
                    type = "bonjour",
                    mode = "daemon",
                    src = alua.id,
                    dst = d,
                }
                -- Send a bonjour event to the deamon
                tcp.send(sock, tb)
            end
        end
    end

    -- Updates its state in the done list
    msg.done[alua.id] = true
    local count = #msg.list
    for k, v in pairs(msg.done) do
        count = count - 1
    end
    -- Sees if the list is done
    if count == 0 then
        -- If it's done and the requester has a callback send the reply to the previous daemon
        if msg.cb then
            local tb = {
                type = "link-daemon-reply",
                status = "ok",
                src = alua.id,
                dst = msg.src,
                cb = msg.cb,
            }
            routemsg(tb.dst, tb)
        end
        return
    end

    -- If it isn't done, register a callback and find the next daemon
    local callback
    if msg.cb then
        local c, dst = msg.cb, msg.src

        callback = function (m)
            local tb = {
                    type = "link-daemon-reply",
                    status = m.status,
                    error = m.error,
                    src = alua.id,
                    dst = dst,
                    cb = c,
                }
            routemsg(tb.dst, tb)
        end -- function callback

    end

    local next
    for _, d in ipairs(msg.list) do
        if not msg.done[d] then
            next = d
            break
        end
    end
    local tb = {
        type = "link-daemon",
        list = msg.list,
        done = msg.done,
        src = alua.id,
        dst = next,
    }
    if callback then
        tb.cb = setcb(callback)
    end
    routemsg(tb.dst, tb)
end

-----------------------------------------------------------------------------
-- "Link daemons" event handler
-- Message definition:
--      type    "bonjour"
--      mode    "daemon"
--      src     sender daemon id
--      dst     destination daemon id
-----------------------------------------------------------------------------
local function bonjour(msg)
    -- Update the local daemons list
    daemons[msg.sock]   = msg.src
    daemons[msg.src]    = msg.sock
    
    -- Register the pair (daemon id, socket)
    raw.setfd(msg.src, msg.sock:getfd())
end

-----------------------------------------------------------------------------
-- Route message event handler
-- Message definition:
--      type    = "route"
--      message the message to route
-----------------------------------------------------------------------------
local function route(tmp)
    local msg = tmp.message
    -- Sees if the message is to itself
    if msg.dst == alua.id then
        msg.sock = tmp.sock
        -- Process the message (event)
        process(msg)
    else -- Route the message
        local succ, e = routemsg(msg.dst, msg)
        -- If the message has a status, it is a reply: discart it.
        if e and msg.cb and not msg.status then
            local tb = {
                -- TODO Corrigir o envio do retorno quando nao ha rota para o destino
                -- o tipo da mensagem deve ser outro dai cria-se um novo tratador
                -- type = msg.type .. "-reply",
                type = msg.type,
                src = alua.id,
                dst = msg.src,
                status = "error",
                error = e,
                cb = msg.cb,
            }
            -- TODO 
            print("route", "error", alua.id, tostring(tb))
            routemsg(msg.src, tb)
        end
    end
end

-----------------------------------------------------------------------------
-- End event handles
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Registered events
-----------------------------------------------------------------------------
event.register("auth",                  auth)
event.register("auth-reply",            auth_reply)

event.register("fork",                  fork)
event.register("fork-reply",            fork_reply)
event.register("fork-code",             fork_code)
event.register("fork-code-reply",       fork_code_reply)

event.register("execute",               execute)
event.register("execute-reply",         execute_reply)

event.register("receive-data",          receive_data)
event.register("receive-data-reply",    receive_data_reply)

event.register("link-start",            link_start)
event.register("link-start-reply",      link_reply)
event.register("link-daemon",           link_daemon)
event.register("link-daemon-reply",     link_reply)
event.register("bonjour",               bonjour)

event.register("route",                 route)
-----------------------------------------------------------------------------
-- End registered events
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- API functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
--  Connect to a daemon
--
-- @param ip The daemon ip
-- @param port The daemo port
-- @param cb The callback function
--
-- @return true if the connect event was sent to the  daemon
--         false and the error message if ther's a error
-----------------------------------------------------------------------------
function connect(ip, port, cb)
    if alua.id then
        return false, "already connected"
    elseif connecting then
        return false, "waiting reply"
    end
    local err
    sock, err = tcp.connect(ip, port, listen)
    if err then
        return false, err
    end
    connecting = true
    local tb = {type="auth"}
    if cb then
        tb.cb = setcb(cb)
    end
    tcp.send(sock, tb)

    -- TODO Alterar para retornar erro ou sucesso pela callback
    return true
end

-----------------------------------------------------------------------------
-- Create a new daemon
--
-- @param ip the daemon ip
-- @param port the daemon port
-----------------------------------------------------------------------------
function create(ip, port)
    server, err = assert(tcp.listen(ip, port, listen))
    prefix = format("%s:%d", ip, port)
    alua.id = prefix .. "/0"
    alua.router = alua.id
    alua.daemonid = alua.id
    alua.isdaemon = true
    alua.isrouter = true
    mbox.register(alua.id)
end

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
            type = "execute",
            src = alua.id,
            dst = dst,
            chunk = str
        }
        if cb then
            msg.cb = setcb(cb)
        end
        return routemsg(dst, msg)
    end
    return false, "not connected"
end

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
        local msg = {
            type = "receive-data",
            src = alua.id,
            dst = dst,
            data = marshal.encode(data)
        }
        if cb then
            msg.cb = setcb(cb)
        end

        return routemsg(dst, msg)
    end
    return false, "not connected"
end

-----------------------------------------------------------------------------
-- Register a receive data event handler
--
-- @param handler the event handler
-----------------------------------------------------------------------------
function register_listener(handler)
    receive_handler = handler
end

-----------------------------------------------------------------------------
-- Create a network of deamons
--
-- @param list the list of daemons to connect
-- @param cb the callback function
--
-- @return true if the message was sent
--         false and the error message if there's a error
-----------------------------------------------------------------------------
function link(list, cb)
    if alua.id then
        local tb = {
            type = "link-start",
            list = list,
            src = alua.id,
            dst = alua.daemonid,
        }
        if cb then
            tb.cb = setcb(cb)
        end
        return routemsg(tb.dst, tb)
    end
    return false, "not connected"
end

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
        if r.status == "ok" then
            local tb = {
                type = "fork-code",
                src = alua.id,
                dst = alua.daemonid,
                cb = cb,
            }
            routemsg(tb.dst, tb)
        else
            io.stderr:write(format("*** %s\n", r.error))
        end
    end
    -- end function

    local succ, e = connect(ip, port, conncb)
    if not succ then
        io.stderr:write(format("*** %s\n", e))
        return
    end

    connecting = true

    return loop()
end

-----------------------------------------------------------------------------
-- ??
-----------------------------------------------------------------------------
function step()
    local nonblock = task.process()
    nonblock = nonblock or mbox.process()
    if alua.isrouter or connecting then
        nonblock = nonblock or tcp.process()
    end
    return nonblock
end

-----------------------------------------------------------------------------
-- The process event loop
-----------------------------------------------------------------------------
function loop()
    if alua.isrouter or connecting then
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
end

-----------------------------------------------------------------------------
-- Create a new Lua process
--
-- @param code the initial code to execute
-- @param luap true if the new process is a Lua process
--             fasle if the new process is a ALua process
-- @param cb the callback function
-----------------------------------------------------------------------------
function spawn(code, luap, cb)
    if luap then
        -- TODO Retornar via evento?
        newthread(code, cb)
    else
        newprocess(alua.daemonid, code, cb)
    end
end

-----------------------------------------------------------------------------
-- Inicialize the process.
--
-- @param tb a table with the folowing fields:
--        addr the daemon ip
--        port the daemon port
--        cb the callback function
--        If the table = nil creates a stantalone process:
--        alua.id = "127.0.0.1:8888/0"
-----------------------------------------------------------------------------
function init(tb)
    if tb.addr then
        connect(tb.addr, tb.port, tb.cb)
    else
        prefix = format("%s:%d", "127.0.0.1", 8888)
        alua.id = prefix .. "/0"
        alua.router = alua.id
        alua.daemonid = alua.id
        mbox.register(alua.id)
        if tb.cb then
            task.schedule(tb.cb)
        end
    end
end

-----------------------------------------------------------------------------
-- Terminate the event loop and quit the process
-----------------------------------------------------------------------------
function quit()
    terminate = true
end

-----------------------------------------------------------------------------
-- Get the daemons list
--
-- @return the daemons list
-----------------------------------------------------------------------------
function get_daemon_it()
    return pairs(daemons)
end

-- function inc_threads(qtd)
--    return thread.inc_threads(qtd)
-- end
-- 
-- 
-- function dec_threads(qtd)
--    return thread.dec_threads(qtd) 
-- end

-----------------------------------------------------------------------------
-- End API functions
-----------------------------------------------------------------------------
