module("alua.dht.identifier", package.seeall)

local uuid  = require("uuid")

local MIN_ID = uuid.min_hash()
local MAX_ID = uuid.max_hash()
-- TODO Colocar este parametro como configurável
LENGTH = 160

local node_pattern = "^(%d+%.%d+%.%d+%.%d+:%d+/%d+)"

local function hash_to_byte(hash_id)
    local byte_id = {}
    for i = 1, #hash_id do
        byte_id[i] = string.byte(hash_id, i)
    end
    return byte_id
end

local function byte_to_hash(byte_id)
    local hash_id = ""
    for i = 1, #byte_id do
        hash_id = hash_id .. string.char(byte_id[i])
    end
    return hash_id
end

local function is_node(str_id)
    local node = string.match(str_id, node_pattern) 
    
    if node then
        return true
    else
        return false
    end
end

function new(str_id)
    local id = {
        string  = str_id,
        hash    = uuid.hash(str_id),
        is_node = is_node(str_id)
    }
    
    -- id.byte     = id_to_byte(id.hash)
    return id
end


-- function print_id(id)
--     if id.string then
--         print()
-- end

function addPowerOfTwo(id, powerOfTwo)
    local byte_id = hash_to_byte(id.hash)
    local indexOfByte = math.ceil(#id.hash - ((powerOfTwo - 1) / 8))
    local toAdd = {1, 2, 4, 8, 16, 32, 64, 128}
    local valueToAdd = toAdd[((powerOfTwo - 1) % 8) + 1]
    local oldValue = nil
    repeat
        local overflow = false
        -- add value
    	oldValue = byte_id[indexOfByte]
    	byte_id[indexOfByte] = byte_id[indexOfByte] + valueToAdd

        if byte_id[indexOfByte] > 255 then
            byte_id[indexOfByte] = byte_id[indexOfByte] - 256
            overflow = true
    	    valueToAdd = 1
    	end

        indexOfByte = indexOfByte - 1
    until not overflow or (indexOfByte < 1)

    -- return byte_to_hash(byte_id)
    return {string = nil, hash = byte_to_hash(byte_id)}
end

--  0 = equals
--  1 = id1 > id2
-- -1 = id1 < id2
function compare(id1, id2)
    if id1.hash == id2.hash then
        return 0
    elseif id1.hash > id2.hash then
        return 1
    else
        return -1
    end
end

function comp_sort(id1, id2)
    return id1.hash < id2.hash
end


-- Interval does not include the two bonds
-- function is_between(id, from_id, to_id)
--     
--     -- The interval is the whole ring, except of the two bounds
--     if from_id.hash == to_id.hash then
--         return not id.hash == from_id.hash
--     end
--         
--     -- The interval does not cross zero
--     if from_id.hash < to_id.hash then
--         return id.hash > from_id.hash and id.hash < to_id.hash
--     end
--     
--     -- The interval crosses zero
--     -- Split interval at zero
--     -- (from_id - MAX_ID] + [MIN_ID - to_id)
--     return (id.hash > from_id.hash and id.hash <= MAX_ID) or (id.hash >= MIN_ID and id.hash < to_id.hash)
-- end

-- Interval includes the two bonds
function is_between(id, from_id, to_id)
    
    -- The interval has only one position
    if from_id.hash == to_id.hash then
        return id.hash == from_id.hash
    end
        
    -- The interval does not cross zero
    if from_id.hash < to_id.hash then
        return id.hash >= from_id.hash and id.hash <= to_id.hash
    end
    
    -- The interval crosses zero
    -- Split interval at zero
    -- [from_id - MAX_ID] + [MIN_ID - to_id]
    return (id.hash >= from_id.hash and id.hash <= MAX_ID) or (id.hash >= MIN_ID and id.hash <= to_id.hash)
end

function to_string(id)
    return id.string
end