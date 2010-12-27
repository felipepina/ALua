-----------------------------------------------------------------------------
-- Test script
-- Scenario 10.1
-----------------------------------------------------------------------------

local cen = "10.3"
suc_msg = "Scenario " .. cen .. ": ok!"
err_msg = "Scenario " .. cen .. ": erro!"
local daemonlist = {"127.0.0.1:8888/0", "127.0.0.1:8889/0", "127.0.0.1:8890/0", "127.0.0.1:8891/0", "127.0.0.1:8892/0"}
local prolist = {"127.0.0.1:8888/1", "127.0.0.1:8889/1", "127.0.0.1:8890/1", "127.0.0.1:8891/1", "127.0.0.1:8892/1"}
local count = 0
local key, value

function spawncb(reply)
    assert(reply.status == alua.ALUA_STATUS_OK, err_msg)    
    alua.send(reply.id, "start()")
end

function finalize()
    count = count + 1
    if count == 5 then
        print(suc_msg)
        for i,v in ipairs(list) do
            alua.send(prolist[i], "alua.quit()")
            alua.send(daemonlist[i], "alua.quit()")
        end
    end
end

function main()
    local code = [=[
        local hub = "127.0.0.1:8888/1"
        local key, value
    
        function storecb(reply)
            local ret = assert(reply.status == alua.ALUA_STATUS_OK, err_msg) and assert(reply.key == key, err_msg)
            if ret then
                alua.send(hub, "finalize()")
                alua.quit()
            end
        end
        
        function start()
            local ip, port, id = string.match(alua.id, "^(%d+%.%d+%.%d+%.%d+):(%d+)/(%d+)")
            key = port
            value = alua.id

            alua.dht_insert(key, value, storecb)
        end
    ]=]
    
    alua.spawn(code, true, spawncb)
end
