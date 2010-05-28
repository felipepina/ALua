-----------------------------------------------------------------------------
-- Test script
-- Scenario 1.6
-----------------------------------------------------------------------------

local cen = "1.6"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local function sendcb(reply)
	assert(reply.status == "ok", error_msg)
end

local function spawncb(reply)
	assert(reply.status == "ok", error_msg)

	spawn_id = reply.id
	
	local code = "start(\"" .. alua.id  .. "\")"

	alua.send(spawn_id, code, sendcb)
end

function conncb(reply)
	assert(reply.status == "ok", err_msg)
	
	local spawn_code = [[
        local cen = "1.6"
        local suc_msg = "Scenario " .. cen .. ": ok!"
        local err_msg = "Scenario " .. cen .. ": erro!"

        local ret = false
            
		local function sendcb(reply)
			ret = assert(reply.status == "ok", error_msg)

			if ret then
				print(suc_msg)
				alua.send(alua.daemonid, "alua.quit()")
				alua.quit()
			end
		end
		
		function start(dst)
			local code = "alua.quit()"
			-- local code = "assert(recv_flag, error_msg)"
			alua.send(dst, code, sendcb)
		end
	]]
	
	alua.spawn(spawn_code, false, spawncb)
	alua.spawn(spawn_code, false, spawncb)
end
