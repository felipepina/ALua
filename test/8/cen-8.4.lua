-----------------------------------------------------------------------------
-- Test script
-- Scenario 8.4
-----------------------------------------------------------------------------

local function spawncb(reply)
    assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
    alua.send(reply.id, "alua.quit()")
    alua.send(alua.daemonid, "alua.quit()")
    alua.quit()
end

function conncb(reply)
    assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
    
    local code = [[
        local cen = "8.4"
        local suc_msg = "Scenario " .. cen .. ": ok!"
        local err_msg = "Scenario " .. cen .. ": erro!"

        -- Premise: initial thread pool is 4
        if (assert(alua.dec_threads(1) == 0, err_msg) and assert(alua.inc_threads(1) == 0, err_msg)) then
            print(suc_msg)
        end
    ]]
    
    alua.spawn(code, true, spawncb)

end