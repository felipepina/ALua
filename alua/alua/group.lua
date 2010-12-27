-----------------------------------------------------------------------------
-- Group
--
-- Module to manage groups
--
-- version: 1.2 2010/09/15
-----------------------------------------------------------------------------

module("alua.group", package.seeall)

-----------------------------------------------------------------------------
-- Modules variables
-----------------------------------------------------------------------------
local alua      = require("alua")
local event     = require("alua.event")
local dht       = require("alua.dht")
local network   = require("alua.network")
local message   = require("alua.network")
local uuid      = require("uuid")

-- TODO Implementar uma estrutura de dados mais eficiente
local groups = {}

-- TODO como detectar que um nó que caiu nao esta mais no grupo

-- Internal group events
local GROUP_CREATE          = "group-create"
local GROUP_CREATE_REPLY    = "group-create-reply"
local GROUP_DELETE          = "group-delete"
local GROUP_DELETE_REPLY    = "group-delete-reply"
local GROUP_JOIN            = "group-join"
local GROUP_JOIN_REPLY      = "group-join-reply"
local GROUP_LEAVE           = "group-leave"
local GROUP_LEAVE_REPLY     = "group-leave-reply"

local MULTICAST_MESSAGE     = "multicast-message"
local LOAD_BALANCED_MESSAGE = "load-balanced-message"


-----------------------------------------------------------------------------
-- Events handlers
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Insert pair request event handler
-- Message definition:
--      type    GROUP_CREATE
-----------------------------------------------------------------------------
function group_create_request(request)
    local groupname = request.groupname
    local status, err_msg

    if not groups[groupname] then
        groups[groupname] = {}
        status = ALUA_STATUS_OK
    else
        status = ALUA_STATUS_ERROR
        err_msg = "Group already exists"
    end

    if request.cb then
       local reply = {
           type         = GROUP_CREATE_REPLY,
           dst          = request.src,
           groupname    = groupname,
           cb           = request.cb,
           status       = status
       }

       if err_msg then
           reply.error = err_msg
       end

       network.routemsg(reply.dst, reply)
    end
end -- function group_create_request


-----------------------------------------------------------------------------
-- Insert pair request event handler
-- Message definition:
--      type    GROUP_CREATE_REPLY
-----------------------------------------------------------------------------
function group_create_reply(reply)
    if reply.cb then
        local cb = event.getcb(reply.cb)
        if reply.error then
            cb({
                -- src         = reply.src,
                groupname   = reply.groupname,
                status      = alua.ALUA_STATUS_ERROR,
                error       = reply.error
            })
        else
            cb({
                -- src         = reply.src,
                groupname   = reply.groupname,
                status      = alua.ALUA_STATUS_OK
            })
        end
    end
end -- function group_create_reply


-----------------------------------------------------------------------------
-- Insert pair request event handler
-- Message definition:
--      type    GROUP_DELETE
-----------------------------------------------------------------------------
function group_delete_request(request)
    local groupname = request.groupname
    local status, err_msg

    if groups[groupname] then
        groups[groupname] = nil
        status = ALUA_STATUS_OK
    else
        status = ALUA_STATUS_ERROR
        err_msg = "Group does not exist"
    end

    if request.cb then
       local reply = {
           type         = GROUP_DELETE_REPLY,
           dst          = request.src,
           groupname    = groupname,
           cb           = request.cb,
           status       = status
       }

       if err_msg then
           reply.error  = err_msg
       end

       network.routemsg(reply.dst, reply)
    end
end -- function group_delete_request


-----------------------------------------------------------------------------
-- Insert pair request event handler
-- Message definition:
--      type    GROUP_DELETE_REPLY
-----------------------------------------------------------------------------
function group_delete_reply(reply)
    if reply.cb then
        local cb = event.getcb(reply.cb)
        if reply.error then
            cb({
                -- src=reply.src,
                groupname   = reply.groupname,
                status      = alua.ALUA_STATUS_ERROR,
                error       = reply.error
            })
        else
            cb({
                -- src=reply.src,
                groupname   = reply.groupname,
                status      = alua.ALUA_STATUS_OK
            })
        end
    end
end -- function group_delete_reply


-----------------------------------------------------------------------------
-- Insert pair request event handler
-- Message definition:
--      type    GROUP_JOIN
-----------------------------------------------------------------------------
function group_join_request(request)
    local groupname     = request.groupname
    local new_member    = request.member
    local status, err_msg

    if groups[groupname] then
        -- TODO verificar se o novo membro já esta no grupo
        local group = groups[groupname]
        table.insert(group, new_member)
        status = ALUA_STATUS_OK
    else
        status = ALUA_STATUS_ERROR
        err_msg = "Group [" ..  groupname .. "] does not exist"
    end

    if request.cb then
       local reply = {
           type         = GROUP_JOIN_REPLY,
           dst          = request.src,
           groupname    = groupname,
           cb           = request.cb,
           status       = status
       }

       if err_msg then
           reply.error  = err_msg
       end

       network.routemsg(reply.dst, reply)
    end
end -- function group_join_request


-----------------------------------------------------------------------------
-- Insert pair request event handler
-- Message definition:
--      type    GROUP_JOIN_REPLY
-----------------------------------------------------------------------------
function group_join_reply(reply)
    if reply.cb then
        local cb = event.getcb(reply.cb)
        if reply.error then
            cb({
                -- src         = reply.src,
                groupname   = reply.groupname,
                status      = alua.ALUA_STATUS_ERROR,
                error       = reply.error
            })
        else
            cb({
                -- src     = reply.src,
                groupname   = reply.groupname,
                status      = alua.ALUA_STATUS_OK
            })
        end
    end
end -- function group_join_reply


-----------------------------------------------------------------------------
-- Insert pair request event handler
-- Message definition:
--      type    GROUP_LEAVE_REPLY
-----------------------------------------------------------------------------
function group_leave_request(request)
    local groupname = request.groupname
    local new_member = request.member
    local status, err_msg

    if groups[groupname] then
        local group = groups[groupname]
        -- TODO remove pelo indice.  Melhorar esta estrutura de dados
        for i, process in ipairs(group) do
            if process == request.member then
                table.remove(group, i)
                break
            end
        end
        
        status = ALUA_STATUS_OK
    else
        status = ALUA_STATUS_ERROR
        err_msg = "Group does not exist"
    end

    if request.cb then
        local reply = {
            type        = GROUP_JOIN_REPLY,
            dst         = request.src,
            groupname   = groupname,
            cb          = request.cb,
            status      = status
        }

        if err_msg then
            reply.error = err_msg
        end

        network.routemsg(reply.dst, reply)
    end
end -- function group_leave_request


-----------------------------------------------------------------------------
-- Insert pair request event handler
-- Message definition:
--      type    GROUP_JOIN_REPLY
-----------------------------------------------------------------------------
function group_leave_reply(reply)
    if reply.cb then
        local cb = event.getcb(reply.cb)
        if reply.error then
            cb({
                -- src=reply.src,
                groupname   = reply.groupname,
                status      = alua.ALUA_STATUS_ERROR,
                error       = reply.error
            })
        else
            cb({
                -- src=reply.src,
                groupname   = reply.groupname,
                status      = alua.ALUA_STATUS_OK
            })
        end
    end
end -- function group_leave_reply


function multicast_handler(multicast_message)
    local message = multicast_message.message
    local groupname = multicast_message.groupname
    message.dst = groups[groupname]
    
    -- Callback to remove dead node
    function remove_dead_node(reply)
        -- TODO Melhorar colocando uma função que tente se comunicar com o nó para confirmar que o mesmo esta morto realmente
        local groupname = groupname
        if reply.status == alua.ALUA_STATUS_ERROR then
            for i, process in ipairs(groups[groupname]) do
                if process == reply.ori_dst then
                    table.remove(groups[groupname], i)
                    break
                end
            end
        end
    end

    message.cb = event.setpcb(remove_dead_node, #groups[groupname])
    message.src = alua.id

    network.routemsg(groups[groupname], message)
end


function load_balance_handler(load_balanced_message)
    -- TODO Encontrar o nó com o identificador mais próximo do identificador da msg
    -- E então enviar a msg para este nó
end

-- Registers the handlers
event.register(GROUP_CREATE, group_create_request)
event.register(GROUP_CREATE_REPLY, group_create_reply)
event.register(GROUP_DELETE, group_delete_request)
event.register(GROUP_DELETE_REPLY, group_delete_reply)
event.register(GROUP_JOIN, group_join_request)
event.register(GROUP_JOIN_REPLY, group_join_reply)
event.register(GROUP_LEAVE, group_leave_request)
event.register(GROUP_LEAVE_REPLY, group_leave_reply)

event.register(MULTICAST_MESSAGE, multicast_handler)
event.register(LOAD_BALANCED_MESSAGE, load_balance_handler)
-----------------------------------------------------------------------------
-- End events handlers
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Exported functions
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Create a group
--
-- @param requester
-- @param groupname
-- @param callback
-----------------------------------------------------------------------------
function group_create(requester, groupname, callback)
    local request = {
        type = GROUP_CREATE,
        dst = groupname,
        src = requester,
        groupname = groupname
    }

    if callback then
        request.cb = event.setcb(callback)
    end

    network.routemsg(groupname, request)
end -- function group_create


-----------------------------------------------------------------------------
-- Delete a group
--
-- @param requester
-- @param groupname
-- @param callback
-----------------------------------------------------------------------------
function group_delete(requester, groupname, callback)
    local request = {
        type = GROUP_DELETE,
        dst = groupname,
        src = requester,
        groupname = groupname
    }

    if callback then
        request.cb = event.setcb(callback)
    end

    network.routemsg(groupname, request)
end -- function group_delete


-----------------------------------------------------------------------------
-- Join a group
--
-- @param requester
-- @param groupname
-- @param callback
-----------------------------------------------------------------------------
function group_join(requester, groupname, callback)
    local request = {
        type = GROUP_JOIN,
        dst = groupname,
        src = requester,
        groupname = groupname,
        member = requester
    }

    if callback then
        request.cb = event.setcb(callback)
    end

    network.routemsg(groupname, request)
end -- function group_join


-----------------------------------------------------------------------------
-- Leave a group
--
-- @param requester
-- @param groupname
-- @param callback
-----------------------------------------------------------------------------
function group_leave(requester, groupname, callback)
    local request = {
        type        = GROUP_LEAVE,
        dst         = groupname,
        src         = requester,
        groupname   = groupname,
        member      = requester
    }

    if callback then
        request.cb = event.setcb(callback)
    end

    network.routemsg(groupname, request)
end -- function group_leave


-----------------------------------------------------------------------------
-- Sends a multicast message to a group
--
-- @param requester
-- @param groupname
-- @param callback
-----------------------------------------------------------------------------
function multicast_send(requester, groupname, message, callback)
    local multicastMessage = {
        type        = MULTICAST_MESSAGE,
        dst         = groupname,
        src         = requester,
        groupname   = groupname,
        message     = message
    }

    -- TODO Implementar o mecanismo de deteccao de desconecao de um grupo

    -- TODO Sem retorno para mensagens do tipo multicast
    -- if callback then
    --     request.cb = event.setcb(callback)
    -- end

    return network.routemsg(groupname, multicastMessage)
end


-----------------------------------------------------------------------------
-- Sends a message to a group (only one member of the group will receive)
--
-- @param requester
-- @param groupname
-- @param callback
-----------------------------------------------------------------------------
function loadbalanced_send(requester, groupname, message, callback)
    local loadBalancedMessage = {
        type        = LOAD_BALANCED_MESSAGE,
        dst         = groupname,
        src         = requester,
        groupname   = groupname,
        message     = message,
        msg_id      = uuid.create("siv")
    }

    return network.routemsg(groupname, loadBalancedMessage)
end
-----------------------------------------------------------------------------
-- End exported functions
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- End alua.group
-----------------------------------------------------------------------------