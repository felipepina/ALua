-----------------------------------------------------------------------------
-- Test script
-- Scenario 1.3
-----------------------------------------------------------------------------

local cen = "1.3"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local ret = false

function sendcb(reply)
    ret = assert(reply.status == alua.ALUA_STATUS_OK, err_msg) and assert(reply.src == alua.daemonid, err_msg)
    if ret then
        print(suc_msg)
        alua.send(alua.daemonid, "alua.quit()")
        alua.quit()
    end
end

-- function conncb(reply)
--  ret = assert(reply.status == "ok", err_msg)
function main()	
    local code = [[
        assert(alua.id == %q, %q)
    ]]

    alua.send(alua.daemonid, string.format(code, alua.daemonid, err_msg), sendcb)
end
