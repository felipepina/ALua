-----------------------------------------------------------------------------
-- Marshal
--
-- Module with functions to marshalling/unmarshallin data to send/receive.
--
-- version: 1.1 2010/05/15
-----------------------------------------------------------------------------

module("alua.marshal", package.seeall)

-----------------------------------------------------------------------------
-- Aliases
-----------------------------------------------------------------------------
local type = type
local pcall = pcall
local pairs = pairs
local setfenv = setfenv
local tostring = tostring
local loadstring = loadstring
local concat = table.concat
local format = string.format
local error = error

-----------------------------------------------------------------------------
-- Local module variables
-----------------------------------------------------------------------------

-- Defines the types in the marshalling/unmarshaling
local types = {
    number  = "N",
    boolean = "B",
    string  = "S",
    table   = "T"
}

-- Sets the runtime environment
local env = {}

-----------------------------------------------------------------------------
-- Auxiliary functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Helper function to serialize
--
-- @param obj The object to serialize
-- @param buf The buffer to write the serialized objetc
-----------------------------------------------------------------------------
local function dump2(obj, buf)
    local tobj = type(obj)
    if tobj == "thread" or tobj == "userdata" or tobj == "function" then
        error("unable to serialize " .. tboj)
    end
    if tobj == "table" then
        buf[#buf+1] = "{"
        for k, v in pairs(obj) do
            buf[#buf+1] = "["
            dump2(k, buf)
            buf[#buf+1] = "] = "
            dump2(v, buf)
            buf[#buf+1] = ","
        end
        buf[#buf+1] = "}"
    elseif tobj == "string" then
        buf[#buf+1] = string.format("%q", obj)
    else
        buf[#buf+1] = tostring(obj)
   end
end

-----------------------------------------------------------------------------
-- Helper function to encode data
--
-- @param obj The data to encode
-- @param buf The buffer to write the encoded data
--
-- @return nil if the data was encoded or a error message
-----------------------------------------------------------------------------
local function encode2(obj, buf)
    local tobj = type(obj)
    if tobj == "thread" or tobj == "userdata" or tobj == "function" then
        error("unable to serialize " .. tboj)
    end
    if tobj == "table" then
        buf[#buf+1] = "type="..types.table..";data={"
        for k, v in pairs(obj) do
                    buf[#buf+1] = "["
                    dump2(k, buf)
                    buf[#buf+1] = "] = "
                    dump2(v, buf)
                    buf[#buf+1] = ","
        end
        buf[#buf+1] = "}\n"
    elseif tobj == "string" then
        buf[#buf+1] = string.format("%s", "type="..types.string..";data=" .. obj .. "\n")
    elseif tobj == 'number' then
        buf[#buf+1] = string.format("%s", "type="..types.number..";data=" .. obj .. "\n")
    elseif tobj == 'boolean' then
        buf[#buf+1] = string.format("%s", "type="..types.boolean..";data=" .. tostring(obj) .. "\n")
   end
end

-----------------------------------------------------------------------------
-- Helper function to decode data
--
-- @param data The data to decode
--
-- @return The decoded data
-----------------------------------------------------------------------------
local function decode2(data)
    local tobj, obj = string.match(data, "^type=([^\n]+);data=([^\n]+)")

    if tobj == types.tables then
        local f = loadstring(string.format("return { %s }", obj))
        setfenv(f, {})
        local succ, val = pcall(f)
        return val[1]
    elseif tobj == types.string then
        return obj
    elseif tobj == types.number then
        return tonumber(obj)
    elseif tobj == types.boolean then
        if obj == "true" then
            return true
        elseif obj == "false" then
            return false
        end
    end
end

-----------------------------------------------------------------------------
-- End auxiliary functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Exported functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Unserializes code
--
-- @param chunck The chack to execute
--
-- @return True if the chuck executed or false if there was a error
-----------------------------------------------------------------------------
function load(chunk)
    local f = loadstring(format("return { %s }", chunk))
    setfenv(f, env)
    local succ, val = pcall(f)
    if succ then
        return succ, val[1]
    end
    return false, val
end

-----------------------------------------------------------------------------
-- Serializes code to execute
--
-- @param obj The object to serialize
--
-- @return The serialized object
-----------------------------------------------------------------------------
function dump(obj)
    local buf = {}
    dump2(obj, buf)
    return concat(buf)
end

-----------------------------------------------------------------------------
-- Decodes data received
--
-- @param buf The buffer to decode
--
-- @return The decoded data
-----------------------------------------------------------------------------
function decode(buf)
    local ret = {}
    for data in string.gmatch(buf, "([^\n]+)\n") do
        ret[#ret + 1] = decode2(data)
    end
    return unpack(ret)
end

-----------------------------------------------------------------------------
-- Encodes data to transmit
--
-- The encode the data in the folowing way:
--      type=<types>;data=<data><eol>
--
-- @param obj The data to encode
--
-- @return The encoded data
-----------------------------------------------------------------------------
function encode(obj)
    local buf = {}
    encode2(obj, buf)
    return table.concat(buf)
end

-----------------------------------------------------------------------------
-- End exported functions
-----------------------------------------------------------------------------
