-----------------------------------------------------------------------------
-- Test script
-- Scenario 8.3
-----------------------------------------------------------------------------

local cen = "8.3"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

function conncb(reply)
    assert(reply.status == alua.ALUA_STATUS_OK, err_msg)

    -- Premise: initial thread pool is 2
    if assert(alua.dec_threads(1) == 0, err_msg) then
        print(suc_msg)
        alua.send(alua.daemonid, "alua.quit()")
        alua.quit()
    end
end