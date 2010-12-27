-----------------------------------------------------------------------------
-- Test script
-- Scenario 2.1
-----------------------------------------------------------------------------

local cen = "10.1"
suc_msg = "Scenario " .. cen .. ": ok!"
err_msg = "Scenario " .. cen .. ": erro!"
local daemonlist = {"127.0.0.1:8888/0", "127.0.0.1:8889/0", "127.0.0.1:8890/0", "127.0.0.1:8891/0", "127.0.0.1:8892/0"}
local group = nil

local function sendcb(reply)
	assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
end

local function setfuncb(reply)
	assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
    
    local code = "sendtodaemon(%q)"
    
    if reply.src == daemonlist[1] then
	    alua.send(reply.src, string.format(code, daemonlist[2]), sendcb)
	else
	    alua.send(reply.src, string.format(code, daemonlist[1]), sendcb)
	end
end

function main()
	local funcode = [[
    	local cen = "10.1"
        local suc_msg = "Scenario " .. cen .. ": ok!"
        local err_msg = "Scenario " .. cen .. ": erro!"
        
        local peer_id = nil
        local count = 0

        function finalize(src)
            count = count + 1
            
            if count == 2 then
                print(suc_msg)

                local ip, port, id = string.match(alua.id, "^(%d+%.%d+%.%d+%.%d+):(%d+)/(%d+)")
                alua.send(ip .. ":8889/0", "alua.quit()")

                local dst = string.match(alua.id, "^(%d+%.%d+%.%d+%.%d+:%d+)") .. "/1"
                alua.send(dst, "alua.quit()")
                alua.quit()
            end
        end

        local function sendcb(reply)
            local ret = assert(reply.status == alua.ALUA_STATUS_OK, err_msg) and assert(reply.src == peer_id, err_msg)
            local ip, port, id = string.match(alua.id, "^(%d+%.%d+%.%d+%.%d+):(%d+)/(%d+)")
            alua.send(ip .. ":8888/0", string.format("finalize(%q)", alua.id))
        end

	    function sendtodaemon(dst)
	        peer_id = dst
    	    local code = string.format("assert(alua.daemonid == %q, err_msg)", peer_id)
    	    alua.send(peer_id, code, sendcb)
        end
        
        function storecb(reply)
            for k,v in pairs(reply) do
                print(k,v)
            end
        end
        
        function storepair()
            local ip, port, id = string.match(alua.id, "^(%d+%.%d+%.%d+%.%d+):(%d+)/(%d+)")
            alua.dht_insert(port, alua.id, storecb)
        end
        ]]
        
    -- alua.send(daemonlist[1], funcode, setfuncb)
    -- alua.send(daemonlist[2], funcode, setfuncb)
    
    function excludecb(reply)
        -- print("---------")
        -- for k,v in pairs(reply) do
        --     print(k,v)
        -- end
        -- print("---------")
    end
    
    function retrievecb(reply)
        print("---------")
        for k,v in pairs(reply) do
            print(k,v)
        end
        print("---------")
        
        alua.dht_delete(reply.key, excludecb)
    end
    
    function storecb(reply)
        print("---------")
        for k,v in pairs(reply) do
            print(k,v)
        end
        print("---------")
        
        alua.dht_lookup(reply.key, retrievecb)
    end
    
    -- alua.dht_insert("a", alua.id, storecb)
    -- alua.dht_insert("ab", alua.id, storecb)
    -- alua.dht_insert("abc", alua.id, storecb)
    -- alua.dht_insert("abcd", alua.id, storecb)
    -- alua.dht_insert("abcde", alua.id, storecb)
    alua.dht_insert(1, storecb, storecb)
    -- alua.send(daemonlist[3], "print(alua.id)")
    
    function spawncb(reply)
        -- print("---------")
        -- for k,v in pairs(reply) do
        --     print(k,v)
        -- end
        -- print("---------")
    end
    
    function cgrcb(reply)
        -- print("---------")
        -- for k,v in pairs(reply) do
        --     print(k,v)
        -- end
        -- print("---------")
        group = reply.groupname
        
        local code = [=[
        local function gleavecb(reply)
            print("----LEAVE-----")
            for k,v in pairs(reply) dosong
                print(k,v)
            end
            print("---------")
        end
        
        local function gjoincb(reply)
            print("----JOIN-----")
            for k,v in pairs(reply) do
                print(k,v)
            end
            print("---------")
            
            alua.group_leave(%q, gleavecb)
        end
        
        alua.group_join(%q, gjoincb)
        ]=]

        alua.spawn(string.format(code, group, group), true, spawncb)
        alua.spawn(string.format(code, group, group), false, spawncb)
    end
    
    -- alua.group_create("g4", cgrcb)
    -- alua.group_create("g4", cgrcb)
    -- alua.group_create("g1", cgrcb)
    -- alua.group_create("g2", cgrcb)
    -- alua.group_create("g3", cgrcb)
    -- alua.group_create("g5", cgrcb)
    -- alua.group_create("g6", cgrcb)
end
