-----------------------------------------------------------------------------
-- Test script
-- Scenario 10.1
-----------------------------------------------------------------------------

local cen = "10.8"
suc_msg = "Scenario " .. cen .. ": ok!"
err_msg = "Scenario " .. cen .. ": erro!"
local daemonlist = {"127.0.0.1:8888/0", "127.0.0.1:8889/0", "127.0.0.1:8890/0", "127.0.0.1:8891/0", "127.0.0.1:8892/0"}
local count = 0

function lookupcb(reply)
    local ret = assert(reply.status == alua.ALUA_STATUS_ERROR, err_msg) and assert(reply.error == "Key not found", err_msg)
    print(suc_msg)

    for i,v in ipairs(daemonlist) do
        alua.send(v, "alua.quit()")
        alua.quit()
    end
end

function storecb(reply)
    local ret = assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
    alua.dht_lookup("key1", lookupcb)
end

function lookupcb1(reply)
    assert(reply.status == alua.ALUA_STATUS_ERROR, err_msg)
    assert(reply.error == "Key not found", err_msg)
    alua.dht_insert("key", "value", storecb)
end

function main()
    alua.dht_lookup("key", lookupcb1)
end
