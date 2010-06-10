-----------------------------------------------------------------------------
-- Test script
-- Scenario 6.6
-----------------------------------------------------------------------------

local cen = "6.6"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

function sendcb(reply)
    if assert(reply.status == "error") then
        print(suc_msg)
        alua.send(alua.daemonid, "alua.quit()")
        alua.quit()
    end
end

function spawncb(reply)
    if reply.status == "ok" then
        local data = 100
        alua.send_data(reply.id, data, sendcb)
    end
end

function conncb(reply)
    if reply.status=="ok" then
        alua.spawn(nil, true, spawncb)
    end
end