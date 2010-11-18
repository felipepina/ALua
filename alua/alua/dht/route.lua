-----------------------------------------------------------------------------
-- DHT
--
-- Module to route messages through the DHT network
--
-- version: 1.2 2010/09/15
-----------------------------------------------------------------------------

module("alua.dht.route", package.seeall)

local dht       = require("alua.dht")
local event     = require("alua.event")
local network   = require("alua.network")
local tcp       = require("alua.tcp")
local uuid      = require("uuid")


-----------------------------------------------------------------------------
-- Local aliases
-----------------------------------------------------------------------------
local setcb             = event.setcb
local getcb             = event.getcb
local setctx            = event.setctx
local getctx            = event.getctx
local delctx            = event.delctx
-- local DHT_STATUS_OK     = dht.DHT_STATUS_OK
-- local DHT_STATUS_ERROR  = dht.DHT_STATUS_ERROR


-----------------------------------------------------------------------------
-- Modules variables
-----------------------------------------------------------------------------
-- DEBUG
local debug = false

-- local local_node_id = nil

-- Routing information
local successor = nil
local suc_sck = nil
local predecessor = nil
local pre_sck = nil
local finger = {}

-- Internal DHT events
local DHT_JOIN_REQUEST                = "dht-join-request"
local DHT_JOIN_REPLY                  = "dht-join-reply"
local DHT_UPDATE_ROUTING_TABLE        = "dht-update-routing-table"
local DHT_UPDATE_ROUTING_TABLE_REPLY  = "dht-update-routing-table-reply"
local DHT_ROUTE                       = "dht-route"

local DHT_GET_NODES                   = "dht-get-nodes"
-- TODO DEBUG retirar este tipo de evento
local DHT_PRINT_NEIGHBOR              = "dht-print-neighbor"


-----------------------------------------------------------------------------
-- Auxiliary functions
-----------------------------------------------------------------------------
local function debug_msg(...)
    if debug then
        print(...)
    end
end
-----------------------------------------------------------------------------
-- End auxiliary functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Events handlers
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Join request event handler
-- Message definition:
--      type    DHT_JOIN_REQUEST
-----------------------------------------------------------------------------
local function join_request(msg)
    debug_msg("join_request:begin", "node: " .. dht.local_node_id)

    local ip, port = string.match(msg.dst, "^(%d+%.%d+%.%d+%.%d+):(%d+)")
    local new_node_sck, err = tcp.connect(ip, port)

    if err then
        print("ERROR: cannot conect to " .. msg.dst)
    end

    -- Context to be retrived when the neighborhood updates theirs routing tables
    local ctx = {
        value   = 0,
        new_pre = msg.dst
    }
    function ctx.dec()
        ctx.value = ctx.value - 1
    end

    if msg.cb then
        ctx.cb = msg.cb
    end

    local context = setctx(ctx)

    -- This node is already in a network
    if successor and predecessor then
       ctx.value = 2
       -- Envia para o seu predecesor msg para que este atualize sua tabela de roteamento
       local old_pre_msg = {
           type    = DHT_UPDATE_ROUTING_TABLE,
           src     = dht.local_node_id,
           dst     = predecessor,
           suc     = msg.dst,
           ctx     = context
       }
       tcp.send(pre_sck, old_pre_msg)
       debug_msg("join_request:update_pre", "node: " .. dht.local_node_id, "pre: " .. predecessor)

       -- Envia msg para n iniciar seu sucessor como m
       local new_node_msg = {
           type    = DHT_UPDATE_ROUTING_TABLE,
           src     = dht.local_node_id,
           dst     = msg.dst,
           pre     = predecessor,
           suc     = dht.local_node_id,
           ctx     = context
       }
       tcp.send(new_node_sck, new_node_msg)
       debug_msg("join_request:update_new_node", "node: " .. dht.local_node_id, "new_node: " .. msg.dst)
    else -- This node is alone (no network)
        ctx.value = 1
        ctx.bootstrap = true
        -- Envia msg para n iniciar seu sucessor como m
        local new_node_msg = {
            type    = DHT_UPDATE_ROUTING_TABLE,
            src     = dht.local_node_id,
            dst     = msg.dst,
            pre     = dht.local_node_id,
            suc     = dht.local_node_id,
            ctx     = context
        }
        tcp.send(new_node_sck, new_node_msg)
        debug_msg("join_request:bootstrap", "node: " .. dht.local_node_id, "new_node: " .. msg.dst)
    end

    tcp.close(new_node_sck)
    debug_msg("join_request:end", "node: " .. dht.local_node_id)
end -- function join_request


-----------------------------------------------------------------------------
-- Join reply event handler
-- Message definition:
--      type    DHT_JOIN_REPLY
-----------------------------------------------------------------------------
local function join_reply(msg)
    debug_msg("join_reply:begin", "node: " .. dht.local_node_id)
    debug_msg("join_reply:msg.cb", "node: " .. dht.local_node_id, "cb: " .. msg.cb)

    if msg.cb then
        local cb = getcb(msg.cb)
        if msg.error then
            cb({
                src     = msg.src,
                status  = dht.DHT_STATUS_ERROR,
                error   = msg.error
            })
        else
            cb({
                src     = msg.src,
                status  = dht.DHT_STATUS_OK
            })
        end
    end

    debug_msg("node: " .. dht.local_node_id, "pre: " .. predecessor)
    debug_msg("node: " .. dht.local_node_id, "suc: " .. successor)
end -- function join_reply


-----------------------------------------------------------------------------
-- Join reply event handler
-- Message definition:
--      type    DHT_UPDATE_ROUTING_TABLE
-----------------------------------------------------------------------------
local function update_routing_table(msg)
    debug_msg("update_routing_table:begin", "node " .. dht.local_node_id)

    -- New predecessor
    if msg.pre then
        -- Opens a socket with the new predecessor
        local ip, port = string.match(msg.pre, "^(%d+%.%d+%.%d+%.%d+):(%d+)")
        local new_pre_sck, err = tcp.connect(ip, port)

        if err then
            print("ERROR: cannot conect to " .. msg.pre)
        end

        -- Closes the socket to the old predecessor if it exists
        if predecessor then
            tcp.close(pre_sck)
        end

        predecessor = msg.pre
        pre_sck = new_pre_sck

        debug_msg("update_routing_table:pre", "node " .. dht.local_node_id, "pre " .. predecessor)
    end

    -- New successor
    if msg.suc then
        -- Opens a socket with the new successor
        local ip, port = string.match(msg.suc, "^(%d+%.%d+%.%d+%.%d+):(%d+)")
        local new_suc_sck, err = tcp.connect(ip, port)

        if err then
            print("ERROR: cannot conect to " .. msg.suc)
        end

        -- Closes the socket to the old successor if it exists
        if successor then
            tcp.close(suc_sck)
        end

        successor = msg.suc
        suc_sck = new_suc_sck

        debug_msg("update_routing_table:suc", "node " .. dht.local_node_id, "suc " .. successor)
    end

    -- Sends a reply to the node which request the update
    local reply = {
        type = DHT_UPDATE_ROUTING_TABLE_REPLY,
        src = dht.local_node_id,
        dst = msg.src,
        ctx = msg.ctx
    }

    debug_msg("update_routing_table:reply", "node " .. dht.local_node_id)

    for k,v in pairs(reply) do
        debug_msg("update_routing_table:reply", "node " .. dht.local_node_id, k,v)
    end

    local ip, port = string.match(msg.src, "^(%d+%.%d+%.%d+%.%d+):(%d+)")
    local reply_sck, err = tcp.connect(ip, port)

    if err then
        print("ERROR: cannot conect to " .. msg.src)
    end
    -- route_msg(msg.src, reply)
    tcp.send(reply_sck, reply)

    tcp.close(reply_sck)

    debug_msg("update_routing_table:end", "node " .. dht.local_node_id)
end -- function update_routing_table


-----------------------------------------------------------------------------
-- Join reply event handler
-- Message definition:
--      type    DHT_UPDATE_ROUTING_TABLE_REPLY
-----------------------------------------------------------------------------
local function update_routing_table_reply(msg)
    debug_msg("update_routing_table_reply:begin", "node " .. dht.local_node_id)

    for k,v in pairs(msg) do
        debug_msg("update_routing_table_reply:msg", k, v)
    end

    -- Retrieve the context
    local ctx = getctx(msg.ctx)

    debug_msg("update_routing_table_reply:count", "node " .. dht.local_node_id, "count: " .. ctx.value)

    -- TODO Verificar como colocar isto em um único if
    -- Decrements the replies counter
    if ctx.value > 0 then
        ctx.dec()
    end

    -- Whe the last reply arrives update this node routing table
    if ctx.value == 0 then
        if predecessor then
            tcp.close(pre_sck)
        end

        predecessor = ctx.new_pre

        -- Opens a socket to the new predecessor
        local ip, port = string.match(predecessor, "^(%d+%.%d+%.%d+%.%d+):(%d+)")
        local new_pre_sck, err = tcp.connect(ip, port)

        if err then
            print("ERROR: cannot conect to " .. predecessor)
        end

        pre_sck = new_pre_sck

        -- If this node is the only one in the network successor and predecessor are the same (the new node)
        if ctx.bootstrap then
            successor = predecessor
            suc_sck = pre_sck
        end

        -- Reply to the new node
        reply = {
            type    = DHT_JOIN_REPLY,
            src     = dht.local_node_id,
            dst     = predecessor
        }

        if ctx.cb then
            reply.cb = ctx.cb
        end

        network.routemsg(reply.dst, reply)

        debug_msg("update_routing_table_reply:update", "node " .. dht.local_node_id, "pre: " .. predecessor)
    end

    debug_msg("update_routing_table_reply:end", "node " .. dht.local_node_id)
end -- function update_routing_table_reply


-----------------------------------------------------------------------------
-- Route message event handler
-- Message definition:
--      type    DHT_ROUTE
-----------------------------------------------------------------------------
local function route(tmp)
    -- TODO Colocar algum tipo de retentativa por outro caminho
    -- TODO Quando uma msg parte do ultimo no do circulo ela esta dando a volta completa para chegar no seu
    -- sucessor
    debug_msg("route:begin", "node: " .. dht.local_node_id)

    local msg = tmp.message

    -- print("BEGIN:DHT.ROUTE")
    -- print(dht.local_node_id)
    -- for k,v in pairs(msg) do
    --     print(k,v)
    -- end
    -- print("END:DHT.ROUTE")

    -- Calculates the hash the destination and the local node
    local dst_hash = uuid.hash(tmp.dst)
    local lcl_hash = uuid.hash(dht.local_node_id)
    local pre_hash = nil
    local suc_hash = nil
    if predecessor then
        pre_hash = uuid.hash(predecessor)
    end
    if successor then
        suc_hash = uuid.hash(successor)
    end

    -- TODO Workaround
    msg.sock = nil
    tmp.sock = nil

    -- Bootstrap. There's no network
    if not successor and not predecessor then
        debug_msg("route:bootstrat", "node: " .. dht.local_node_id)
        event.process(msg)
        debug_msg("route:bootstrat:end", "node: " .. dht.local_node_id)
        return
    end

    -- The destination is this node
    if dst_hash == lcl_hash then
        -- TODO process the msg
        debug_msg("route:equal", "node: " .. dht.local_node_id, "dst: ".. msg.dst)
        event.process(msg)
    -- The destination is after this node
    elseif dst_hash > lcl_hash then
        -- This node is the nearest node to the destination. The destination is the greatest node in the network.
        if (suc_hash > lcl_hash) and (pre_hash > lcl_hash) and (dst_hash > pre_hash) then
            debug_msg("route:near", "node: " .. dht.local_node_id, "dst: ".. msg.dst)
            event.process(msg)
        else
            debug_msg("route:greater", "node: " .. dht.local_node_id, "dst: ".. msg.dst, "suc: " .. successor)
            tcp.send(suc_sck, tmp)
        end                
        
    -- The destination is before this node or this node is the nearest node
    else
        -- This node is the nearest node to the destination. The sucessor node is greater than the destination
        if dst_hash > pre_hash then
            debug_msg("route:near_between", "node: " .. dht.local_node_id, "dst: ".. msg.dst)
            event.process(msg)
        -- This node is the nearest node to the destination. The destination is the least node in the network.
        elseif (suc_hash > lcl_hash) and (pre_hash > lcl_hash) then
            debug_msg("route:near", "node: " .. dht.local_node_id, "dst: ".. msg.dst)
            event.process(msg)
        -- The destination is before this node
        else
            debug_msg("route:lesser", "node: " .. dht.local_node_id, "dst: ".. msg.dst, "pre: " .. predecessor)
            tcp.send(pre_sck, tmp)
        end
    end
    debug_msg("route:end", "node: " .. dht.local_node_id)
end -- function route


-----------------------------------------------------------------------------
-- Route message event handler
-- Message definition:
--      type    DHT_GET_NODES
-----------------------------------------------------------------------------
function get_nodes_request(request)
    local nodes = request.nodes

    if not nodes[dht.local_node_id] then
        request.nodes[dht.local_node_id] = true
        request.dst = successor
        network.routemsg(request.dst, request)
    else
        -- TODO Enviar somente os identificadores do nós
        local cb = getcb(request.cb)
        cb({
            src     = dht.local_node_id,
            status  = dht.DHT_STATUS_OK,
            nodes   = request.nodes
        })
    end
end


-- TODO DEBUG Retirar esta função
function print_neighbor(request)
    local nodes = request.nodes

    if not nodes[dht.local_node_id] then
        print(predecessor .. " -> " .. dht.local_node_id .. " -> " .. successor)
        request.nodes[dht.local_node_id] = true
        request.dst = successor
        network.routemsg(reqiest.dst, request)
    end
end

-- Registers the handlers
event.register(DHT_JOIN_REQUEST, join_request)
event.register(DHT_JOIN_REPLY, join_reply)
event.register(DHT_UPDATE_ROUTING_TABLE, update_routing_table)
event.register(DHT_UPDATE_ROUTING_TABLE_REPLY, update_routing_table_reply)
event.register(DHT_ROUTE, route)

event.register(DHT_GET_NODES, get_nodes_request)
event.register(DHT_PRINT_NEIGHBOR, print_neighbor)
-----------------------------------------------------------------------------
-- End events handlers
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Exported functions
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Initiates the DHT layer
--
-- @param nodeid
-----------------------------------------------------------------------------
function init(nodeid)
    dht.local_node_id = nodeid
end -- function init


-----------------------------------------------------------------------------
-- Join the same P2P network that the especifeied node belongs.
--
-- @param remote_node
-- 
-----------------------------------------------------------------------------
-- TODO Talvez colocar uma função de callback opcional
function join(remote_node, cb)
    -- Cria uma conexão tcp com o nó node, enviar msg de erro se coneção não
    -- puder ser estabelecida
    debug_msg("join:begin", "node: " .. dht.local_node_id, "know_node: " .. remote_node)

    -- Opens a socket to the network's know node
    local ip, port = string.match(remote_node, "^(%d+%.%d+%.%d+%.%d+):(%d+)")
    local sock, err = tcp.connect(ip, port)

    if err then
        print("ERROR: cannot conect to " .. remote_node)
    end

    -- Join message
    local msg = {
        type    = DHT_JOIN_REQUEST,
        -- TODO Tirar esta dependencia do identificador do alua. Melhor colocar o id
        -- como um parametro
        dst     = dht.local_node_id,
        src     = dht.local_node_id
    }

    if callback then
        msg.cb = setcb(callback)
    end

    -- Pack the join message in a route message
    pack_msg = {
        type    = DHT_ROUTE,
        dst     = msg.dst,
        message = msg
    }

    -- Sends the route message to the know node
    tcp.send(sock, pack_msg)

    tcp.close(sock)
    debug_msg("join:end", "node: " .. dht.local_node_id)
end -- function join


-----------------------------------------------------------------------------
-- Leave the P2P network.
-----------------------------------------------------------------------------
function leave()
    -- TODO Implementar
    -- 1. Nó saindo da rede envia mensagem ao seu sucessor
    -- 2. Eles trocam informações para atualizar dados das rotas
end -- function leave


-----------------------------------------------------------------------------
-- Send the message to the destination
--
-- @param dst the destination
-- @param msg the message
-----------------------------------------------------------------------------
function routemsg(dst, msg)
    debug_msg("route_msg:begin", "node: " .. dht.local_node_id, "dst: ".. msg.dst)

    new_msg = {
        type    = DHT_ROUTE,
        dst     = dst,
        message = msg
    }

    event.process(new_msg)

    debug_msg("route_msg:end", "node: " .. dht.local_node_id)
    
    return true
end -- function routemsg


-----------------------------------------------------------------------------
-- Rebuilds the DHT network
--
-----------------------------------------------------------------------------
function rebuild()
    -- TODO rebuild the network
end -- function rebuild


-----------------------------------------------------------------------------
-- Send the message to the destination
--
-- @param callback callback function
-- @returns
-----------------------------------------------------------------------------
function get_nodes(callback)
    local request = {
        type    = DHT_GET_NODES,
        dst     = dht.local_node_id,
        nodes   = {},
        cb      = setcb(callback)
    }

    return network.routemsg(request.dst, request)
end
-----------------------------------------------------------------------------
-- End exported functions
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- End alua.dht.route
-----------------------------------------------------------------------------
