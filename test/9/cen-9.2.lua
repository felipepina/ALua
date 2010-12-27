-----------------------------------------------------------------------------
-- Test script
-- Scenario 9.2
-----------------------------------------------------------------------------

local cen = "9.2"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

function main()
    -- assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
	if assert(alua.getdaemons() == nil, err_msg) then
	    print(suc_msg)
	    for i = 1, #daemonlist do
            alua.send(daemonlist[#daemonlist + 1 - i], "alua.quit()")
        end
        alua.quit()
    end
end

-- function conncb(reply)
--  assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
--  alua.link(daemonlist, linkcb)
-- end
