-----------------------------------------------------------------------------
-- Test script
-- Scenario 1.6
-----------------------------------------------------------------------------

local cen = "1.6"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local count = 0

local function sendcb(reply)
	assert(reply.status == alua.ALUA_STATUS_OK, error_msg)
	count = count + 1
	if count == 2 then
	    alua.send(alua.daemonid, "alua.quit()")
	    print(suc_msg)
	    alua.quit()
    end
end

local function spawncb(reply)
	assert(reply.status == alua.ALUA_STATUS_OK, error_msg)

	spawn_id = reply.id
	
	local code = "start(\"" .. alua.id  .. "\")"

	alua.send(spawn_id, code, sendcb)
end

-- function conncb(reply)
--  assert(reply.status == "ok", err_msg)

function main()
	local spawn_code = [[
        local cen = "1.6"
        local suc_msg = "Scenario " .. cen .. ": ok!"
        local err_msg = "Scenario " .. cen .. ": erro!"

		local function sendcb(reply)
			assert(reply.status == alua.ALUA_STATUS_OK, error_msg)
            alua.quit()
		end
		
		function start(from)
			local code = "assert(alua.id == %q, err_msg)"
			alua.send(from, string.format(code, from), sendcb)
		end
	]]
	
	alua.spawn(spawn_code, false, spawncb)
	alua.spawn(spawn_code, false, spawncb)
end
