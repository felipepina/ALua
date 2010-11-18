-----------------------------------------------------------------------------
-- Route
--
-- Module to route messages in the ALua network
--
-- version: 1.2 2010/09/15
-----------------------------------------------------------------------------

module("alua.network", package.seeall)

local alua      = require("alua")
local event     = require("alua.event")
local task      = require("alua.task")
local mbox      = require("alua.mbox")
local tcp       = require("alua.tcp")
local dht       = require("alua.dht")
local marshal   = require("alua.marshal")
local raw       = require("rawsend")

-----------------------------------------------------------------------------
-- Global variables
-----------------------------------------------------------------------------
local nodeid_pattern = "^(%d+%.%d+%.%d+%.%d+:%d+/%d+)"
local daemonid_pattern = "^(%d+%.%d+%.%d+%.%d+:%d+)"

local count = 0
prefix = nil
connecting = false

-- TODO Colocar metodos de acesso a lista de processo
processes = {}

-- Internal events
local ALUA_AUTH         = "alua-auth"
local ALUA_AUTH_REPLY   = "alua-auth-reply"
local ALUA_ROUTE        = "alua-route"
local ALUA_ROUTE_REPLY  = "alua-route-reply"

-----------------------------------------------------------------------------
-- Auxiliary functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Gets the next hop connection in the route to a destination
--
-- @param dst The destination to find the route.
--            In the format <ip>:<port>/<id>/<seq_id>
-- @return The next hop connection (socket)
-----------------------------------------------------------------------------
-- local function nexthop(dst)
--     -- Looks in the process list for a direct conection
--     local conn = network.processes[dst]
--
--     if not conn then
--         -- Looks in the daemons list for a direct connection
--         conn = daemons[dst]
--         if not conn then
--             -- there isn't a direct conection to the dst
--             -- thus the next hop is the corresponding daemon
--             dst = string.match(dst, "^(%d+%.%d+%.%d+%.%d+:%d+)") .. "/0"
--             conn = daemons[dst]
--         end
--     end
--     return conn
-- end -- function nexthop

-----------------------------------------------------------------------------
-- Generates the next sequencial to a process
--
-- @return the sequencial generated
-----------------------------------------------------------------------------
local function nextid()
    count = count + 1
    return count
end -- function nextid

-----------------------------------------------------------------------------
-- Listens and process messages received in a socket
--
-- @param sock The socket
-----------------------------------------------------------------------------
local function listen(sock)
    -- Receive through TCP
    local str, err = tcp.receive(sock)
    if err then
        local idx = processes[sock]
        if idx then
            processes[idx] = nil
            processes[sock] = nil
        -- else
        --     idx = daemons[sock]
        --     if idx then
        --         daemons[idx] = nil
        --         daemons[sock] = nil
        --     end
        end
        tcp.close(sock)
        return true  -- stop activate the socket
    end
    local succ, msg = marshal.load(str)
    -- Put the sender's socket
    msg.sock = sock
    -- Process the message (event)
    event.process(msg)
end

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
--              (seted by the listen function)
-----------------------------------------------------------------------------
local function auth(msg)
    -- Creates a new id to the requester process
    local id = prefix .. "/" .. tostring(nextid())

    -- Puts the process in the processes list
    processes[id]       = msg.sock
    processes[msg.sock] = id

    -- Registers the pair (process id, socket)
    raw.setfd(id, msg.sock:getfd());
    -- TODO A resposta é sempre OK mesmo? Não pode ocorrer algum erro?
    local tb = {
        type        = ALUA_AUTH_REPLY,
        status      = alua.ALUA_STATUS_OK,
        id          = id,
        daemonid    = alua.id,
        cb          = msg.cb,
    }

    -- Sends through a shared socket
    tcp.rawsend(id, tb)
end -- function auth

-----------------------------------------------------------------------------
-- "Connection request reply" event handler
-- Message definition:
--      type        = "auth-reply"
--      status      ALUA_STATUS_OK or ALUA_STATUS_ERROR
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
        local cb = event.getcb(msg.cb)
        if cb then
            cb({status=alua.ALUA_STATUS_OK, id=msg.id, daemonid=msg.daemonid})
        end
    end
end -- function auth_reply

-----------------------------------------------------------------------------
-- Route message event handler
-- Message definition:
--      type    ALUA_ROUTE
--      message the message to route
-----------------------------------------------------------------------------
local function route(tmp)
    local msg = tmp.message
    -- Sees if the message is to itself
    if msg.dst == alua.id then
        -- Put the sender's socket
        -- TODO COMENTADO
        -- msg.sock = tmp.sock
        -- Process the message (event)
        event.process(msg)
    else -- Route the message

        -- print("BEGIN:ALUA.ROUTE")
        -- print(alua.id)
        -- for k,v in pairs(tmp) do
        --     print(k,v)
        -- end
        -- print("----")
        -- for k,v in pairs(msg) do
        --     print(k,v)
        -- end
        -- print("END:ALUA.ROUTE")

        local succ, e = routemsg(msg.dst, msg)
        -- If the message has a status, it is a reply: discart it.
        if e and msg.cb and not msg.status then
            local tb = {
                type    = ALUA_ROUTE_REPLY,
                src     = alua.id,
                dst     = msg.src,
                status  = alua.ALUA_STATUS_ERROR,
                error   = e,
                cb      = msg.cb,
            }
            routemsg(msg.src, tb)
        end
    end
end -- function route

-----------------------------------------------------------------------------
-- Route message reply event handler
-- Will be dispatched when no route could be found
-- Message definition:
--      type    ALUA_ROUTE_REPLY
--      status  ALUA_STATUS_OK or ALUA_STATUS_ERROR
--      error   the error message
--      scr     the last hop reached
--      dst     the sender's id
--      cb      the sender's callback
-----------------------------------------------------------------------------
local function route_reply(msg)
    local cb = getcb(msg.cb)
    -- Use the most general fields in the message
    cb({status=msg.status, error=msg.error})
end -- function route_reply


-- Registers the handlers
event.register(ALUA_AUTH,           auth)
event.register(ALUA_AUTH_REPLY,     auth_reply)
event.register(ALUA_ROUTE,          route)
event.register(ALUA_ROUTE_REPLY,    route_reply)

-----------------------------------------------------------------------------
-- End event handles
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Exported functions
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
    local tb = {
        type = ALUA_AUTH
        }

    if cb then
        tb.cb = event.setcb(cb)
    end

    tcp.send(sock, tb)

    return true
end -- function connect

-----------------------------------------------------------------------------
-- Create a new daemon
--
-- @param ip the daemon ip
-- @param port the daemon port
-- @param initf daemon's initial function to execute
-----------------------------------------------------------------------------
function create(ip, port, initf)
    server, err = assert(tcp.listen(ip, port, listen))
    prefix = string.format("%s:%d", ip, port)
    alua.id = prefix .. "/0"
    alua.router = alua.id
    alua.daemonid = alua.id
    alua.isdaemon = true
    alua.isrouter = true
    mbox.register(alua.id)
    if initf then
        task.schedule(initf)
    end
    dht.init(alua.id)
end -- function create

-----------------------------------------------------------------------------
-- Create a network of deamons
--
-- @param list the list of daemons to connect
-- @param cb the callback function
--
-- @return true if the message was sent
--         false and the error message if there's a error
-----------------------------------------------------------------------------
function link(node, cb)
    -- if alua.id then
    --     local tb = {
    --         type    = ALUA_LINK_START,
    --         list    = list,
    --         src     = alua.id,
    --         dst     = alua.daemonid,
    --     }
    --     if cb then
    --         tb.cb   = setcb(cb)
    --     end
    --     return routemsg(tb.dst, tb)
    -- end
    -- return false, "not connected"
    -- TODO Verificar se o processo que recebeu a solicitacão é um deamon
    -- se for envia para a camada DHT
    -- se não encaminha a menssagem para o daemon
    
    if alua.isdaemon then
        return dht.join(node, cb)
    else
        return false, "not a deamon"
    end
end -- function link

-----------------------------------------------------------------------------
-- Routes a messagem to its destination
--
-- @param dst The destination. In the format <ip>:<port>/<id>/<seq_id>
-- @msg The message
--
-- @return True when the message was routed to the destination
--         False and the error message when there's a error
-----------------------------------------------------------------------------
function routemsg(dst, msg)
    -- The destination is itself? If so put in the task queue
    if dst == alua.id then
        task.schedule(event.process, msg)
        return true
    else
        -- The destination is in same ALua process?
        -- If true, sends through the intra-process queue (CCR)
        local proc = string.match(dst, nodeid_pattern)
        if proc == string.match(alua.id, nodeid_pattern) then
            return mbox.send(dst, msg)
        else
            -- Routes the message: send to router or daemon
            msg = {
                type    = ALUA_ROUTE,
                message = msg
            }
            if alua.isdaemon then -- Send to router
                local dst_daemon = string.match(dst, daemonid_pattern)

                -- Verifies if the destination is a node
                if dst_daemon then
                    dst_daemon = dst_daemon .. "/0"
                else
                    dst_daemon = dst
                end

                -- If the dst is in the same daemon
                if dst_daemon == alua.daemonid then
                    -- TODO Verificar se existe a conexao (socket) com o proc
                    return tcp.send(processes[proc], msg)
                -- Else route the msg throught the DHT network
                else
                    if not proc then
                        msg = msg.message
                    end
                    msg.dst = dst
                    return dht.routemsg(dst_daemon, msg)
                end
            else -- Send to daemon
                return tcp.rawsend(alua.daemonid, msg)
            end
        end
    end
end -- function routemsg

-----------------------------------------------------------------------------
-- End exported functions
-----------------------------------------------------------------------------