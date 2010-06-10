-----------------------------------------------------------------------------
-- Test script
-- Scenario 2.5
-----------------------------------------------------------------------------

local cen = "2.5"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local function quitcb(reply)
    print(suc_msg)

    alua.send(daemonlist[3], "alua.quit()")
    alua.send(daemonlist[2], "alua.quit()")
    alua.send(daemonlist[1], "alua.quit()")
    
    alua.quit()
end

local function sendcb(reply)
	assert(reply.status == "error", err_msg)
	-- Sucess
    -- print(suc_msg)
    
    alua.link({daemonlist[3], daemonlist[1]}, quitcb)
end

local function linkcb(reply)
	assert(reply.status == "ok", err_msg)
	
	local code = [[assert(alua.id == alua.daemonid)]]
	
    alua.send(daemonlist[3], code, sendcb)
end

function conncb(reply)
	assert(reply.status == "ok", err_msg)
	local new_daemonlist = {daemonlist[1], daemonlist[2]}
    alua.link(new_daemonlist, linkcb)
end
