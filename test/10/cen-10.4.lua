-----------------------------------------------------------------------------
-- Test script
-- Scenario 10.1
-----------------------------------------------------------------------------

local cen = "10.4"
suc_msg = "Scenario " .. cen .. ": ok!"
err_msg = "Scenario " .. cen .. ": erro!"
local daemonlist = {"127.0.0.1:8888/0", "127.0.0.1:8889/0", "127.0.0.1:8890/0", "127.0.0.1:8891/0", "127.0.0.1:8892/0"}
local key, value

function storecb(reply)
    local ret = assert(reply.status == alua.ALUA_STATUS_OK, err_msg) and assert(reply.key == key, err_msg)
    alua.dht_insert(key, value, storecbf)
end

function storecbf(reply)
    assert(reply.status == alua.ALUA_STATUS_ERROR, err_msg)
    print(suc_msg)
    for i,v in ipairs(daemonlist) do
        alua.send(daemonlist[i], "alua.quit()")
    end
end

function main()
    local ip, port, id = string.match(alua.id, "^(%d+%.%d+%.%d+%.%d+):(%d+)/(%d+)")
    key = port
    value = alua.id
    
    alua.dht_insert(key, value, storecb)
end
