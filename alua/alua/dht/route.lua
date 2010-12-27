-----------------------------------------------------------------------------
-- DHT
--
-- Module to route messages through the DHT network
-- Based on the Chord protocol
--
-- version: 1.2 2010/09/15
-----------------------------------------------------------------------------

module("alua.dht.route", package.seeall)

local dht       = require("alua.dht")
local event     = require("alua.event")
local network   = require("alua.network")
local tcp       = require("alua.tcp")
local uuid      = require("uuid")
local util      = require("alua.util")
local task      = require("alua.task")
local timer     = require("alua.timer")


local node          = require("alua.dht.node")
local list          = require("alua.dht.list")
local identifier    = require("alua.dht.identifier")
local finger        = require("alua.dht.finger")

-----------------------------------------------------------------------------
-- Local aliases
-----------------------------------------------------------------------------
local setcb     = event.setcb
local getcb     = event.getcb
local setctx    = event.setctx
local getctx    = event.getctx
local delctx    = event.delctx
-- local DHT_STATUS_OK     = dht.DHT_STATUS_OK
-- local DHT_STATUS_ERROR  = dht.DHT_STATUS_ERROR

local isTable = util.isTable
local copyTable = util.copyTable
local isNode = util.isNode
local get_parentid  = util.get_parentid
local get_daemonid  = util.get_daemonid

-----------------------------------------------------------------------------
-- Modules variables
-----------------------------------------------------------------------------
-- DEBUG
local debug = false
local MAXN = 3

-- Routing information
local successor = nil
local predecessor = nil
local successors_list = nil
-- local predecessors_list = list.new(nil, MAXN, identifier.comp_des)
local finger_table = nil

--
local rebuilding = false
local pendingMessages = {}

-- Internal DHT events
local DHT_JOIN_REQUEST                  = "dht-join-request"
local DHT_JOIN_REPLY                    = "dht-join-reply"
local DHT_UPDATE_ROUTING_TABLE          = "dht-update-routing-table"
-- local DHT_UPDATE_ROUTING_TABLE_REPLY    = "dht-update-routing-table-reply"
local DHT_ROUTE                         = "dht-route"
local DHT_ROUTE_REPLY                   = "dht-route-reply"
local DHT_ROUTE_MULTICAST               = "dht-route-multicast"

local DHT_NOTIFY                        = "dth-notify"

local DHT_PING_REQUEST                  = "dht-ping-request"
local DHT_PING_REPLY                    = "dht-ping-reply"

local DHT_GET_NODES                     = "dht-get-nodes"

-- TODO DEBUG retirar este tipo de evento
local DHT_PRINT_NEIGHBOR                = "dht-print-neighbor"


-----------------------------------------------------------------------------
-- Auxiliary functions
-----------------------------------------------------------------------------
-- function make_dht_addr(dst)
--     return {
--         id      = dst,
--         hash    = uuid.hash(dst)
--     }
-- end

-- local function id_to_byte(node_id)
--     local id = {}
--     for i = 1,#node_id do
--         id[i] = string.byte(node_id, i)
--     end
--     return id
-- end
-- 
-- local function byte_to_id(byte_id)
--     local node_id = ""
--     for i = 1, #byte_id do
--         node_id = node_id .. string.char(byte_id[i])
--     end
--     return node_id
-- end
-- 
-- local function addPowerOfTwo(node_id, powerOfTwo)
--     -- local indexOfByte = 20 - ((powerOfTwo - 1) / 8)
--     local id = id_to_byte(node_id)
--     local indexOfByte = math.ceil(#id - ((powerOfTwo - 1) / 8))
--     local toAdd = {1, 2, 4, 8, 16, 32, 64, 128}
--     local valueToAdd = toAdd[((powerOfTwo - 1) % 8) + 1]
--     local oldValue = nil
-- 
--     repeat
--         local overflow = false
--         -- add value
--      oldValue = id[indexOfByte]
--      id[indexOfByte] = id[indexOfByte] + valueToAdd
-- 
--         if id[indexOfByte] > 255 then
--             id[indexOfByte] = id[indexOfByte] - 256
--             overflow = true
--          valueToAdd = 1
--      end
-- 
--         indexOfByte = indexOfByte - 1
--     until not overflow or (indexOfByte < 1)
-- 
--     return byte_to_id(id)
-- end




local function ping_node(node_id, cb)
    local ping_msg = {
        type    = DHT_PING_REQUEST,
        src     = dht.dht_addr,
        dst     = node_id,
        cb      = event.setcb(cb)
    }
    
    local succ, e = routemsg(ping_msg.dst, ping_msg)
    
    if e and cb then
        cb({
            status  = dht.DHT_STATUS_ERROR,
            error   = e
        })
    end
end


local function nexthop(dst_id)
    if not successor and not predecessor then
        return false
    end

    if not successor then
        return predecessor
    end

    if not predecessor then
        return predecessor
    end

    -- local dst_hash = uuid.hash(dst)
    local dst_hash = dst_id.hash
    -- local lcl_hash = uuid.hash(dht.local_node_id)
    local lcl_hash = dht.local_id.hash
    -- local pre_hash = uuid.hash(predecessor)
    local pre_hash = predecessor.id.hash
    -- local suc_hash = uuid.hash(successor)
    local suc_hash = successor.id.hash

    if dst_hash == lcl_hash then -- The destination is this node
        return false
    elseif dst_hash > lcl_hash then -- The destination is after this node
        -- This node is the nearest node to the destination. The destination is the greatest node in the network.
        if (suc_hash > lcl_hash) and (pre_hash > lcl_hash) and (dst_hash > pre_hash) then
            return false
        else
            return successor
        end
    else -- The destination is before this node or this node is the nearest node
        -- This node is the nearest node to the destination. The sucessor node is greater than the destination
        if dst_hash > pre_hash then
            return false
        -- This node is the nearest node to the destination. The destination is the least node in the network.
        elseif (suc_hash > lcl_hash) and (pre_hash > lcl_hash) then
            return false
        else -- The destination is before this node
            return predecessor
        end
    end
end


local function groupProcs(procs)
    local upperGroup = {}
    local lowerGroup = {}
    local localGroup = {}
    local groups = {}
    -- local local_hash = uuid.hash(dht.local_node_id)
    local local_hash = dht.dht_addr.hash
    local proc_hash = nil

    for i, proc in ipairs(procs) do
        -- daemon_hash = uuid.hash(get_daemonid(proc))

        next_node = nexthop(make_dht_addr(get_daemonid(proc)))

        if not next_node then
            table.insert(localGroup, proc)
        elseif next_node == pre_sck then
            table.insert(lowerGroup, proc)
        elseif next_node == suc_sck then
            table.insert(upperGroup, proc)
        end

        -- if daemon_hash == local_hash then
        --     -- Não deve ter nada
        -- elseif local_hash > daemon_hash then
        --     -- for i, proc in ipairs(proclist) do
        --         table.insert(lowerGroup, proc)
        --     -- end
        -- else
        --     -- for i, proc in ipairs(proclist) do
        --         table.insert(upperGroup, proc)
        --     -- end
        -- end
    end

    if #localGroup > 0 then
        groups[dht.dht_addr.id] = localGroup
    end

    if #lowerGroup > 0 then
        groups[predecessor] = lowerGroup
    end

    if #upperGroup > 0 then
        groups[successor] = upperGroup
    end

    return groups
end
-----------------------------------------------------------------------------
-- Rebuilds the DHT network
--
-----------------------------------------------------------------------------
-- function rebuild()
--     rebuilding = true
-- 
--     -- TODO para reconstruir será enviada uma mensagem de join para algum
--     -- nó conhecido (usar a tabela de finger)
-- 
--     -- TODO apos o termino da reconstrucao da rede processar as mensagens
--     -- pendentes em pendingMessages. Como sera via uma menssagem de join
--     -- isto deve ser feito quando o join for realizado com sucesso
-- end -- function rebuild



function stabilize()
    if successor then
        local ping_suc_msg = {
            type = DHT_PING_REQUEST,
            src = dht.local_id,
            dst = successor.id
        }

        while not node.send_data(successor, ping_suc_msg) do
            local old_suc = list.pop(successors_list)
            successor, err = node.new(list.first(successors_list), true)
            print("SUCCESSOR_DOWN[" .. dht.local_id.string .. "]", old_suc.string, successor.id.string)
        end
    end

    if predecessor then
        local ping_pre_msg = {
            type = DHT_PING_REQUEST,
            src = dht.local_id,
            dst = predecessor.id
        }
        
        if not node.send_data(predecessor, ping_pre_msg) then
            print("PREDECESSOR_DOWN[" .. dht.local_id.string .. "]", predecessor.id.string)
            predecessor = nil
        end
    end

    if successor then
        local notify_request = {
            type    = DHT_NOTIFY,
            src     = dht.local_id,
            dst     = successor.id
        }
        -- TODO Colocar na notificacao a lista de predecessores
        -- pois esse pode ser um novo sucessor (no caso do primeiro sucessor ter saido da rede)
        if not node.send_data(successor, notify_request) then
            print("ERROR[" .. dht.local_id.string .. "]: cannot send data to " .. successor.id.string)
        end
    end
end
-----------------------------------------------------------------------------
-- End auxiliary functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Events handlers
-----------------------------------------------------------------------------
local function ping_request(request)
    local ping_reply = {
        type    = DHT_PING_REPLY,
        src     = dht.dht_addr,
        dst     = request.src,
        cb      = request.cb
    }

    local succ, e = routemsg(ping_reply.dst, ping_reply)
    
    -- TODO verificar se ocorreu algum erro no envio
end


local function ping_reply(reply)
    local cb = getcb(reply.cb)
    
    -- TODO chamar a cb
end

local function notify(request)
    -- Envia resposta ao nó origem contendo o predecessor atual
    local succ, err
    local notifing_node = node.new(request.src, true)
    
    if not notifing_node then
        print("ERROR[" .. dht.local_id.string .. "]: cannot conect to " .. request.src.string)
        -- assert(notifing_node, "notifing_node " .. dht.local_id.string)
    else
        if not predecessor and not successor then -- bootstrap
            predecessor = notifing_node
            successor = notifing_node
            
            list.insert(successors_list, successor.id)
            -- list.insert(predecessors_list, predecessor.id)

            -- local pre_list = list.to_table(predecessors_list)
            local notifing_node_msg = {
                type    = DHT_UPDATE_ROUTING_TABLE,
                src     = dht.local_id,
                dst     = notifing_node.id,
                pre     = dht.local_id
                -- pre_list    = pre_list
            }

            succ, err = node.send_data(notifing_node, notifing_node_msg)
            if not succ then
                print("ERROR[" .. dht.local_id.string .. "]: cannot send data to " .. notifing_node.id, err)
                -- assert(succ, "notifing_node " .. dht.local_id.string)
            end
        -- elseif not predecessor then
        --     predecessor = notifing_node
        elseif node.equals(predecessor, notifing_node) or not predecessor then
            if not predecessor then
                predecessor = notifing_node
            end
            
            -- TODO Enviar ao predecessor a lista de sucessores
            local suc_list = list.to_table(successors_list)
            table.insert(suc_list, dht.local_id)

            local notifing_node_msg = {
                type        = DHT_UPDATE_ROUTING_TABLE,
                src         = dht.local_id,
                dst         = predecessor.id,
                suc         = dht.local_id,
                suc_list    = suc_list
            }

            succ, err = node.send_data(notifing_node, notifing_node_msg)
            if not succ then
                print("ERROR[" .. dht.local_id.string .. "]: cannot send data to " .. notifing_node.id.string, err)
                -- assert(succ, "notifing_node " .. dht.local_id.string)
            end
        else
            if node.compare(predecessor, notifing_node) == -1 or node.equals(predecessor, successor) then
                -- manda o nó solicitante atualizar o seu predecessor com o predecessor local
                -- local pre_list = list.new(list.to_table(predecessors_list), MAXN, identifier.comp_des)
                local notifing_node_msg = {
                    type        = DHT_UPDATE_ROUTING_TABLE,
                    src         = dht.local_id,
                    dst         = notifing_node.id,
                    pre         = predecessor.id
                    -- pre_list    = list.to_table(pre_list)
                }

                succ, err = node.send_data(notifing_node, notifing_node_msg)
                if not succ then
                    print("ERROR[" .. dht.local_id.string .. "]: cannot send data to " .. notifing_node.id.string, err)
                    -- assert(succ, "notifing_node " .. dht.local_id.string)
                end

                -- manda o predecessor atualizar o seu sucessor com o nó solicitante
                -- Successor list + local node + notifing_node (probably a new node)
                local suc_list = list.to_table(successors_list)
                table.insert(suc_list, dht.local_id)
                table.insert(suc_list, notifing_node.id)

                local pre_msg = {
                    type        = DHT_UPDATE_ROUTING_TABLE,
                    src         = dht.local_id,
                    dst         = predecessor.id,
                    suc         = notifing_node.id,
                    suc_list    = suc_list
                }

                succ, err = node.send_data(predecessor, pre_msg)
                if not succ then
                    print("ERROR[" .. dht.local_id.string .. "]: cannot send data to " .. predecessor.id.string, err)
                    -- assert(succ, "predecessor " .. dht.local_id.string)
                end

                if not node.equals(predecessor, successor) then
                    node.close_conn(predecessor)
                end

                -- atualiza predecessor com o no solicitante
                predecessor = notifing_node
                -- list.insert(predecessors_list, predecessor.id)
            else
                -- manda o nó solicitante atualizar o seu sucessor com o predecessor
                local notifing_node_msg = {
                    type    = DHT_UPDATE_ROUTING_TABLE,
                    src     = dht.local_id,
                    dst     = notifing_node.id,
                    suc     = predecessor.id
                }

                local succ, err = node.send_data(notifing_node, notifing_node_msg)
                if not succ then
                    print("ERROR[" .. dht.local_id.string .. "]: cannot send data to " .. notifing_node.id.string, err)
                    
                    -- assert(succ, "notifing_node " .. dht.local_id.string)
                end

                node.close_conn(notifing_node)
            end
        end
    end


    -- TODO DEBUG
    local pre, suc

    if predecessor then
        pre = predecessor.id.string
    else
        pre = "nil"
    end

    if successor then
        suc = successor.id.string
    else
        suc = "nil"
    end

    -- print(pre .. " -> [[" .. dht.local_id.string .. "]] -> " .. suc)
    print(pre .. " -> [[" .. dht.local_id.string .. "]] -> " .. list.to_string(successors_list))
end



-----------------------------------------------------------------------------
-- Join request event handler
-- Message definition:
--      type    DHT_JOIN_REQUEST
-----------------------------------------------------------------------------
local function join_request(request)
    local new_node = node.new(request.dst, true)
    
    if not new_node then
        print("ERROR[" .. dht.local_id.string .. "]: cannot conect to " .. request.dst.string)
        -- assert(new_node, "new_node " .. dht.local_id.string)
    else
        -- Successors list plus the actual node
        local suc_list = list.to_table(successors_list)
        table.insert(suc_list, dht.local_id)

        local new_node_msg = {
            type        = DHT_UPDATE_ROUTING_TABLE,
            src         = dht.local_id,
            dst         = request.dst,
            suc         = dht.local_id,
            suc_list    = suc_list,
            finger      = finger_table
        }

        if request.cb then
            new_node_msg.cb = request.cb
        end

        local succ, err = node.send_data(new_node, new_node_msg)
        if not succ then
            print("ERROR[" .. dht.local_id.string .. "]: cannot send data to " .. new_node.id.string, err)
            -- assert(succ, "new_node " .. dht.local_id.string)
        end
        node.close_conn(new_node)
    end
end -- function join_request


-----------------------------------------------------------------------------
-- Join reply event handler
-- Message definition:
--      type    DHT_JOIN_REPLY
-----------------------------------------------------------------------------
-- local function join_reply(reply)
--     if reply.cb then
--         local cb = getcb(reply.cb)
--         if reply.error then
--             rebuilding = true
--             cb({
--                 src     = reply.src,
--                 status  = dht.DHT_STATUS_ERROR,
--                 error   = reply.error
--             })
--         else
--             rebuilding = false
--
--             -- TODO ao processar as mensagens pendentes será que nao deve
--             -- descartar alguma? Imagine o caso de um join de um nó x que
--             -- foi interrompido por um rebuild e a resposta será enviada
--             -- incorreta. Verificar esses casos.
--             for i, message in ipairs(pendingMessages) do
--                 table.remove(pendingMessages, i)
--                 event.process(message)
--             end
--
--             cb({
--                 src     = reply.src,
--                 status  = dht.DHT_STATUS_OK
--             })
--         end
--     end
-- end -- function join_reply


-----------------------------------------------------------------------------
-- Join reply event handler
-- Message definition:
--      type    DHT_UPDATE_ROUTING_TABLE
-----------------------------------------------------------------------------
local function update_routing_table(message)
    local status = true
    local error

    -- New successor
    if message.suc then
        local successor_node = node.new(message.suc, true)

        if not successor_node then
            status = dht.DHT_STATUS_ERROR
            error = "ERROR[" .. dht.local_id.string .. "]: cannot conect to " .. message.suc.string
            -- assert(successor_node, "successor_node " .. dht.local_id.string)
        else
            -- Closes the socket to the old successor if it exists
            if successor and not node.equals(successor, predecessor) then
                node.close_conn(successor)
            end

            successor = successor_node
            
            if message.suc_list then
                list.insertn(successors_list, message.suc_list)
            end

            status = status and dht.DHT_STATUS_OK
        end
    end

    -- New predecessor
    if message.pre then
        local predecessor_node = node.new(message.pre, true)

        if not predecessor_node then
            status = dht.DHT_STATUS_ERROR
            error = "ERROR[" .. dht.local_id.string .. "]: cannot conect to " .. message.pre.string
            -- assert(predecessor_node, "predecessor_node " .. dht.local_id.string)
        else
            -- Closes the socket to the old predecessor if it exists
            if predecessor and not node.equals(successor, predecessor) then
                node.close_conn(predecessor)
            end

            predecessor = predecessor_node
            
            -- O predecessor já esta na lista pois a lista veio do sucessor
            -- list.insert(predecessors_list, predecessor.id)
            -- if message.pre_list then
            --     list.insertn(predecessors_list, message.pre_list)
            -- end

            status = status and dht.DHT_STATUS_OK
        end
    end

    if message.finger then
        -- local suc_finger = message.finger
        -- suc_finger[0] = {start = successor.hash, node = successor}
        -- updateFinger(suc_finger)
    end        
        
    if message.cb then
        local cb = getcb(message.cb)
        local reply = {
            src = message.src.string,
            status = status
        }
        if error then
            reply.error = error
        end
        cb(reply)
    end

    -- TODO DEGUG
    local pre, suc

    if predecessor then
        pre = predecessor.id.string
    else
        pre = "nil"
    end

    if successor then
        suc = successor.id.string
    else
        suc = "nil"
    end

    -- print(pre .. " -> [[" .. dht.local_id.string .. "]] -> " .. suc)
    print(pre .. " -> [[" .. dht.local_id.string .. "]] -> " .. list.to_string(successors_list))
end -- function update_routing_table


-----------------------------------------------------------------------------
-- Join reply event handler
-- Message definition:
--      type    DHT_UPDATE_ROUTING_TABLE_REPLY
-----------------------------------------------------------------------------
-- local function update_routing_table_reply(msg)
--     -- TODO Verificar se isto nao pode causar um deadlock
--     -- if rebuilding then
--     --     table.insert(pendingMessages, message)
--     --     return
--     -- end
-- 
--     -- Retrieve the context
--     local ctx = getctx(msg.ctx)
-- 
--     -- TODO Verificar como colocar isto em um único if
--     -- Decrements the replies counter
--     if ctx.value > 0 then
--         ctx.dec()
--     end
-- 
--     -- When the last reply arrives update this node routing table
--     if ctx.value == 0 then
--         if ctx.op == "join" then
--             if predecessor then
--                 tcp.close(pre_sck)
--             end
-- 
--             predecessor = ctx.new_pre
--             -- table.insert(predecessor, 1, ctx.new_pre)
-- 
--             -- Opens a socket to the new predecessor
--             local ip, port = string.match(predecessor, "^(%d+%.%d+%.%d+%.%d+):(%d+)")
--             local new_pre_sck, err = tcp.connect(ip, port)
-- 
--             if err then
--                 print("ERROR: cannot conect to " .. predecessor)
--                 -- TODO retornar erro
--             end
-- 
--             pre_sck = new_pre_sck
-- 
--             -- If this node is the only one in the network successor and predecessor are the same (the new node)
--             if ctx.bootstrap then
--                 successor = predecessor
--                 suc_sck = pre_sck
--             end
-- 
--             -- Reply to the new node
--             local reply = {
--                 type    = DHT_JOIN_REPLY,
--                 src     = dht.local_node_id,
--                 dst     = predecessor
--             }
-- 
--             if ctx.cb then
--                 reply.cb = ctx.cb
--             end
-- 
--             -- TODO Retornar msg de erro caso não consiga enviar a mensagem
--             network.routemsg(reply.dst, reply)
--         elseif ctx.op == "leave" then
--             if ctx.cb then
--                 local cb = event.getcb(ctx.cb)
--                 cb({
--                     -- src     = reply.src,
--                     status  = dht.DHT_STATUS_OK
--                 })
--             end
--         end
--     end
-- end -- function update_routing_table_reply


-----------------------------------------------------------------------------
-- Route message event handler
-- Message definition:
--      type    DHT_ROUTE
-----------------------------------------------------------------------------
local function route(msg)
    -- TODO Colocar algum tipo de retentativa por outro caminho

    -- TODO Verificar
    -- if rebuilding then
    --     table.insert(pendingMessages, message)
    --     return
    -- end

    local unpacked_msg = msg.message

    -- TODO Workaround
    unpacked_msg.sock = nil
    msg.sock = nil

    local next_node = nexthop(msg.dst)

    if not next_node then
        event.process(unpacked_msg)
    else
        local succ, e = routemsg(msg.dst.string, unpacked_msg)

        -- If the message has a status, it is a reply: discart it.
        if not succ and unpacked_msg.cb and not unpacked_msg.status then
          local tb = {
              type    = DHT_ROUTE_REPLY,
              src     = dht.local_id.string,
              dst     = unpacked_msg.src,
              status  = dht.DHT_STATUS_ERROR,
              error   = e,
              cb      = unpacked_msg.cb,
              ori_dst = unpacked_msg.dst
          }
          routemsg(unpacked_msg.src.string, tb)
        end
    end
end -- function route


local function route_reply(reply)
    local cb = event.getcb(reply.cb)
    -- Use the most general fields in the message
    cb({
        status  = reply.status,
        error   = reply.error,
        -- src     = reply.src,
        -- dst     = reply.dst
        ori_dst = reply.ori_dst
        })
end -- function route_reply

-----------------------------------------------------------------------------
-- Route message event handler
-- Message definition:
--      type    DHT_GET_NODES
-----------------------------------------------------------------------------
function get_nodes_request(request)
    local nodes = request.nodes

    if not nodes[dht.dht_addr.id] then
        request.nodes[dht.dht_addr.id] = true
        request.dst = successor
        -- TODO Retornar msg de erro caso não consiga enviar a mensagem
        network.routemsg(request.dst, request)
    else
        -- TODO Enviar somente os identificadores do nós
        local cb = getcb(request.cb)
        cb({
            src     = dht.dht_addr,
            status  = dht.DHT_STATUS_OK,
            nodes   = request.nodes
        })
    end
end


-- TODO DEBUG Retirar esta função
function print_neighbor(request)
    local nodes = request.nodes

    if not nodes[dht.local_id.string] then
        local pre, suc

        if predecessor then
            pre = predecessor.id.string
        else
            pre = "nil"
        end

        if successor then
            suc = successor.id.string
        else
            suc = "nil"
        end

        print(pre .. " -> [[" .. dht.local_id.string .. "]] -> " .. list.to_string(successors_list))

        request.nodes[dht.local_id.string] = true
        request.dst = successor.id.string
        if request.dst then
            network.routemsg(request.dst, request)
        end
    end
end

-- Registers the handlers
event.register(DHT_JOIN_REQUEST, join_request)
event.register(DHT_JOIN_REPLY, join_reply)
event.register(DHT_UPDATE_ROUTING_TABLE, update_routing_table)
-- event.register(DHT_UPDATE_ROUTING_TABLE_REPLY, update_routing_table_reply)
event.register(DHT_ROUTE, route)
event.register(DHT_ROUTE_REPLY, route_reply)
event.register(DHT_ROUTE_MULTICAST, route_multicast)

event.register(DHT_NOTIFY, notify)

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
function init(node_id)
    dht.local_id = identifier.new(node_id)
    successors_list = list.new(dht.local_id, MAXN)
    finger_table = finger.new(dht.local_id)
end -- function init


-----------------------------------------------------------------------------
-- Join the same P2P network that the especifeied node belongs.
--
-- @param remote_node
--
-----------------------------------------------------------------------------
function join(remote_node_id, callback)
    local remote_id = identifier.new(remote_node_id)
    local remote_node, err = node.new(remote_id, true)
    
    if not remote_node then
        print("ERROR[" .. dht.local_id.string .. "]: cannot conect to " .. remote_id.string, err)
        -- assert(remote_node, "remote_node " .. dht.local_id.string)
    end

    -- Join message
    local msg = {
        type    = DHT_JOIN_REQUEST,
        dst     = dht.local_id,
        src     = dht.local_id
    }

    if callback then
        msg.cb  = setcb(callback)
    end

    -- TODO Fazer um modulo para mensagens (pode ser no evento, pois a msg nao deixa de ser uma evento)
    -- Pack the join message in a route message
    pack_msg = {
        type    = DHT_ROUTE,
        dst     = msg.dst,
        message = msg
    }

    local succ, err = node.send_data(remote_node, pack_msg)
    if not succ then
        print("ERROR[" .. dht.local_id.string .. "]: cannot send data to " .. remote_node.id.string, err)
        -- assert(succ, "remote_node " .. dht.local_id.string)
    end
    node.close_conn(remote_node)
end -- function join


-----------------------------------------------------------------------------
-- Leave the P2P network.
-----------------------------------------------------------------------------
function leave(callback)
    local pre_msg = {
        type    = DHT_UPDATE_ROUTING_TABLE,
        src     = dht.local_node_id,
        dst     = predecessor.id,
        suc     = successor.id
    }

    node.send_data(predecessor, pre_msg)

    local suc_msg = {
        type    = DHT_UPDATE_ROUTING_TABLE,
        src     = dht.local_node_id,
        dst     = successor.id,
        pre     = predecessor.id
    }

    node.send_data(successor, suc_msg)
end -- function leave


-----------------------------------------------------------------------------
-- Routes a message to the destination
--
-- @param dst the destination
-- @param msg the message
-----------------------------------------------------------------------------
function routemsg(dst, msg)
    -- TODO Workaround
    msg.sock = nil
    
    local dst_id = identifier.new(dst)

    local next_node = nexthop(dst_id)

    if not next_node then
        -- If destination is a node and the message type isn't a join request
        -- the node isn't in the network
        if dst_id.is_node and not msg.type ~= DHT_JOIN_REQUEST then
            return false, "unknown destination"
        else
            task.schedule(event.process, msg)
            return true
        end
    else
        -- TODO Implementar a funcao para empacotar msgs (e desempacotar tb)
        local dht_route_msg = {
            type    = DHT_ROUTE,
            dst     = dst_id, -- destination's daemon
            message = msg
        }

        return node.send_data(next_node, dht_route_msg)
    end
end -- function routemsg


-----------------------------------------------------------------------------
-- Routes a multicast message to the destinations
--
-- @param dst the destination
-- @param msg the message
-----------------------------------------------------------------------------
function routeMulticastMessage(dst, msg)
    -- TODO Problema quando um nó que não está na rede é destinatario
    -- Como nao esta na rede ele vai agrupado no pre ou suc
    -- Vai ficar um ping-pong
    local multicastGroups = groupProcs(dst)
    for grouprep, proclist in pairs(multicastGroups) do
        if grouprep == dht.local_node_id then
            for i, proc in ipairs(proclist) do
                local message = copyTable(msg)
                message.dst = proc
                message.message.dst = proc
                local packed_message = {
                    type    = DHT_ROUTE,
                    dst     = make_dht_addr(get_daemonid(proc)),
                    message = message
                }
                event.process(packed_message)
            end
        else
            local message = copyTable(msg)
            message.dst = proclist
            -- TODO Workaround
            message.message.dst = proclist
            local multicastMessage = {
                type    = DHT_ROUTE,
                dst     = make_dht_addr(grouprep),
                message = message
            }
            event.process(multicastMessage)
        end
    end
end

-----------------------------------------------------------------------------
-- Checks the neighbors
--
-- @param callback callback function
-- @return
-----------------------------------------------------------------------------
-- function checkneighbors()
--     local ping_suc_msg = {
--         type = "ping",
--         src = dht.local_node_id,
--         dst = successor
--     }
-- 
--     if not tcp.send(suc_sck, ping_suc_msg) then
--         -- rebuild network
-- 
--         table.remove(successor, 1)
--         local ip, port = string.match(successor[1], "^(%d+%.%d+%.%d+%.%d+):(%d+)")
--         local new_suc_sck, err = tcp.connect(ip, port)
--         if err then
--             print("ERROR: cannot conect to " .. successor[1])
--             -- TODO retornar erro
--         end
--         suc_sck = new_suc_sck
--         print__()
--     end
-- 
--     local ping_pre_msg = {
--         type = "ping",
--         src = dht.local_node_id,
--         dst = predecessor
--     }
-- 
--     if not tcp.send(pre_sck, ping_pre_msg) then
--         -- rebuild network
--         table.remove(predecessor, 1)
--         local ip, port = string.match(predecessor[1], "^(%d+%.%d+%.%d+%.%d+):(%d+)")
--         local new_pre_sck, err = tcp.connect(ip, port)
--         if err then
--             print("ERROR: cannot conect to " .. predecessor[1])
--             -- TODO retornar erro
--         end
--         pre_sck = new_pre_sck
--         print__()
--     end
-- end


-----------------------------------------------------------------------------
-- Send the message to the destination
--
-- @param callback callback function
-- @return
-----------------------------------------------------------------------------
function get_nodes(callback)
    local request = {
        type    = DHT_GET_NODES,
        dst     = dht.dht_addr,
        nodes   = {},
        cb      = setcb(callback)
    }

    return network.routemsg(request.dst.id, request)
end
-----------------------------------------------------------------------------
-- End exported functions
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- End alua.dht.route
-----------------------------------------------------------------------------

-- TODO DEBUG
function print__()
    local request = {
        type = "dht-print-neighbor",
        dst = dht.dht_addr,
        nodes = {}
    }
    network.routemsg(dht.dht_addr.id, request)
end
