-----------------------------------------------------------------------------
-- DHT
--
-- Module to store pairs in the DHT network
--
-- version: 1.2 2010/09/15
-----------------------------------------------------------------------------

module("alua.dht.storage", package.seeall)

local dht       = require("alua.dht")
local event     = require("alua.event")
local network   = require("alua.network")

-----------------------------------------------------------------------------
-- Local aliases
-----------------------------------------------------------------------------
local setcb             = event.setcb
local getcb             = event.getcb
-- local DHT_STATUS_OK     = dht.DHT_STATUS_OK
-- local DHT_STATUS_ERROR  = dht.DHT_STATUS_ERROR

-----------------------------------------------------------------------------
-- Modules variables
-----------------------------------------------------------------------------
-- DEBUG
local debug = false

-- Distributed storage
local data = {}

-- Internal DHT events
local DHT_INS_PAIR_REQUEST            = "dht-insert-pair-request"
local DHT_INS_PAIR_REPLY              = "dht-insert-pair-reply"
local DHT_DEL_PAIR_REQUEST            = "dht-delete-pair-request"
local DHT_DEL_PAIR_REPLY              = "dht-delete-pair-reply"
local DHT_LOOKUP_REQUEST              = "dht-lookup-request"
local DHT_LOOKUP_REPLY                = "dht-lookup-reply"

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
-- Insert pair request event handler
-- Message definition:
--      type    DHT_INS_PAIR_REQUEST
-----------------------------------------------------------------------------
function insert_pair_request(request)
    debug_msg("insert_pair_request:begin")
    local key = request.key
    local value = request.value
    local status, error_msg = nil

    if not data[key] then
        -- TODO Usar as funções do módulo marshal para armazenar os dados
        data[key] = value
        status = dht.DHT_STATUS_OK
    else
        status = dht.DHT_STATUS_ERROR
        error_msg = "Key already defined"
    end
    -- TODO Colocar msg de erro caso já exista a chave

    -- print("DHT_INS_PAIR:BEGIN")
    -- for k,v in pairs(data) do
    --     print(k,v)
    -- end
    -- print("DHT_INS_PAIR:END")

    if request.cb then
        local reply = {
            type    = DHT_INS_PAIR_REPLY,
            dst     = request.src,
            src     = dht.local_node_id,
            status  = status,
            key     = key,
            cb      = request.cb
        }

        if error_msg then
            reply.error = error_msg
        end

        network.routemsg(reply.dst, reply)
    end
    debug_msg("insert_pair_request:end")
end -- function insert_pair_request


-----------------------------------------------------------------------------
-- Insert pair reply event handler
-- Message definition:
--      type    DHT_INS_PAIR_REPLY
-----------------------------------------------------------------------------
function insert_pair_reply(reply)
    if reply.cb then
        local cb = getcb(reply.cb)
        if reply.error then
            cb({
                src     = reply.src,
                key     = reply.key,
                status  = dht.DHT_STATUS_ERROR,
                error   = reply.error
            })
        else
            cb({
                src     = reply.src,
                key     = reply.key,
                status  = dht.DHT_STATUS_OK
            })
        end
    end
end -- function insert_pair_reply


-----------------------------------------------------------------------------
-- Delete pair reply event handler
-- Message definition:
--      type    DHT_DEL_PAIR_REQUEST
-----------------------------------------------------------------------------
function delete_pair_request(request)
    debug_msg("delete_pair_request:begin")
    local key = request.key
    local status, error_msg = nil

    if data[key] then
        data[key] = nil
        status = dht.DHT_STATUS_OK
        debug_msg("delete_pair_request", "key: " .. "<" .. key .. ">")
    else
        status = dht.DHT_STATUS_ERROR
        error_msg = "Key does not exist"
    end

    if request.cb then
        local reply = {
            type    = DHT_DEL_PAIR_REPLY,
            dst     = request.src,
            src     = dht.local_node_id,
            status  = status,
            key     = key,
            cb      = request.cb
        }

        if error_msg then
            reply.error = error_msg
        end

        network.routemsg(reply.dst, reply)
    end
    debug_msg("delete_pair_request:end")
end -- function delete_pair_request


-----------------------------------------------------------------------------
-- Delete pair reply event handler
-- Message definition:
--      type    DHT_DEL_PAIR_REPLY
-----------------------------------------------------------------------------
function delete_pair_reply(reply)
    if reply.cb then
        local cb = getcb(reply.cb)
        if reply.error then
            cb({
                src     = reply.src,
                key     = reply.key,
                status  = dht.DHT_STATUS_ERROR,
                error   = reply.error
            })
        else
            cb({
                src     = reply.src,
                key     = reply.key,
                status  = dht.DHT_STATUS_OK
            })
        end
    end
end -- function delete_pair_reply


-----------------------------------------------------------------------------
-- Lookup pair request event handler
-- Message definition:
--      type    DHT_LOOKUP_REQUEST
-----------------------------------------------------------------------------
function lookup_request(request)
    local key = request.key

    local value = data[key]

    local reply = {
        type    = DHT_LOOKUP_REPLY,
        dst     = request.src,
        src     = dht.local_node_id,
        cb      = request.cb,
        key     = key
    }

    if value then
        -- TODO Usar as funções do módulo marshal para transmitir os dados
        reply.value     = value
        reply.status    = dht.DHT_STATUS_OK
    else
        reply.error     = "Key not found"
        reply.status    = dht.DHT_STATUS_ERROR
    end

    network.routemsg(reply.dst, reply)
end -- function lookup_request


-----------------------------------------------------------------------------
-- Lookup pair reply event handler
-- Message definition:
--      type    DHT_LOOKUP_REPLY
-----------------------------------------------------------------------------
function lookup_reply(reply)
    if reply.cb then
        local cb = getcb(reply.cb)
        -- TODO Usar as funções do módulo marshal para retornar os dados
        if reply.error then
            cb({
                key     = reply.key,
                value   = reply.value,
                src     = reply.src,
                status  = dht.DHT_STATUS_ERROR,
                error   = reply.error
            })
        else
            cb({
                key     = reply.key,
                value   = reply.value,
                src     = reply.src,
                status  = dht.DHT_STATUS_OK
            })
        end
    end
end -- function lookup_reply

-- Registers the handlers
event.register(DHT_INS_PAIR_REQUEST, insert_pair_request)
event.register(DHT_INS_PAIR_REPLY, insert_pair_reply)
event.register(DHT_DEL_PAIR_REQUEST, delete_pair_request)
event.register(DHT_DEL_PAIR_REPLY, delete_pair_reply)
event.register(DHT_LOOKUP_REQUEST, lookup_request)
event.register(DHT_LOOKUP_REPLY, lookup_reply)
-----------------------------------------------------------------------------
-- End events handlers
-----------------------------------------------------------------------------


-----------------------------------------------------------------------------
-- Exported functions
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- Stores a pair (key, value)
--
-- @param requester
-- @param key
-- @param value
-- @param callback
-- @returns
-----------------------------------------------------------------------------
function insert_pair(requester, key, value, callback)
    local request = {
        type    = DHT_INS_PAIR_REQUEST,
        dst     = key,
        src     = requester,
        key     = key,
        -- TODO Usar as funções do módulo marshal para transmitir os dados
        value   = value
    }

    if callback then
        request.cb = setcb(callback)
    end

    -- return network.routemsg(request.dst, request)
    return network.routemsg(request.dst, request)
end -- function insert_pair


-----------------------------------------------------------------------------
-- Delete a pair (key, value)
--
-- @param requester
-- @param key
-- @param callback
-- @returns
-----------------------------------------------------------------------------
function delete_pair(requester, key, callback)
    local request = {
        type    = DHT_DEL_PAIR_REQUEST,
        dst     = key,
        src     = requester,
        key     = key
    }

    if callback then
        request.cb = setcb(callback)
    end

    return network.routemsg(request.dst, request)
end -- function delete_pair


-----------------------------------------------------------------------------
-- Lookup for a pair (key, value)
--
-- @param requester
-- @param key
-- @param callback
-- @returns
-----------------------------------------------------------------------------
function lookup(requester, key, callback)
    local request = {
        type    = DHT_LOOKUP_REQUEST,
        dst     = key,
        src     = requester,
        key     = key
    }

    if callback then
        request.cb = setcb(callback)
    else
        return nil, "callback is missing"
    end

    return network.routemsg(request.dst, request)
end -- function lookup
-----------------------------------------------------------------------------
-- End exported functions
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
-- End alua.dht.storage
-----------------------------------------------------------------------------