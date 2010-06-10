-----------------------------------------------------------------------------
-- Test script
-- Scenario 8.1
-----------------------------------------------------------------------------

local cen = "8.1"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

function conncb(reply)
    assert(reply.status == alua.ALUA_STATUS_OK, err_msg)

    -- Premise: initial thread pool is 2
    if assert(alua.inc_threads(1) == 3, err_msg) then
        print(suc_msg)
        alua.send(alua.daemonid, "alua.quit()")
        alua.quit()
    end
end