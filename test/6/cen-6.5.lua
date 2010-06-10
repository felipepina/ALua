-----------------------------------------------------------------------------
-- Test script
-- Scenario 6.5
-----------------------------------------------------------------------------

local cen = "6.5"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

function spawncb(reply)
    if reply.status == "ok" then
        local function data()
            return true
        end
        local ret, error = alua.send_data(reply.id, data, sendcb)
        if assert(ret == false, err_msg) then
            print(suc_msg)
            alua.send(alua.daemonid, "alua.quit()")
            alua.quit()            
        end
    end
end

function conncb(reply)
    if reply.status=="ok" then
        alua.spawn(nil, true, spawncb)
    end
end