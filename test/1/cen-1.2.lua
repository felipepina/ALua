-----------------------------------------------------------------------------
-- Test script
-- Scenario 1.2
-----------------------------------------------------------------------------

local cen = "1.2"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local ret = false

-- function conncb(reply)
--     ret = assert(reply.status == "ok", err_msg)
function main()
    print(suc_msg)
    alua.send(alua.daemonid, "alua.quit()")
    alua.quit()
end
