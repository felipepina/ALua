-----------------------------------------------------------------------------
-- Test script
-- Scenario 1.7
-----------------------------------------------------------------------------

local cen = "1.7"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local peer_a = nil
local peer_b = nil

function spawncb(reply)
	assert(reply.status == "ok", err_msg)
	
	if not peer_a then
		peer_a = reply.id
	else
		peer_b = reply.id

        local code_a = "sendtopeer(\"" .. peer_b  .. "\")"
        local code_b = "sendtopeer(\"" .. peer_a  .. "\")"
        
        -- print(code_a)
        -- print(code_b)
		
        alua.send(peer_a, code_a)
        alua.send(peer_b, code_b)
	end
end

function conncb(reply)
	assert(reply.status == "ok", err_msg)
	
	local spawn_code = [[
        local cen = "1.7"
        local suc_msg = "Scenario " .. cen .. ": ok!"
        local err_msg = "Scenario " .. cen .. ": erro!"

        local ret = false
            
        local peer_id = nil
        
        function quitcb(reply)
            if reply.status == "ok" then
                print(suc_msg)
                local dst = string.match(alua.daemonid, "^(%d+%.%d+%.%d+%.%d+:%d+)") .. "/1"
                alua.send(dst, "alua.quit()")
                alua.send(alua.daemonid, "alua.quit()")
                alua.quit()
            end
        end

        function sendcb(reply)
            if peer_id then
                local ret = assert(reply.status == "ok", err_msg) and assert(reply.src == peer_id, err_msg)
             
                local ip, port, id = string.match(alua.id, "^(%d+%.%d+%.%d+%.%d+):(%d+)/(%d+)")
             
                if ret and id == "2" then
                    alua.send(peer_id, "alua.quit()", quitcb)
                end
            end
        end

        function sendtopeer(peerid)
            peer_id = peerid
            local code = "assert(alua.id == %q, err_msg)"
            alua.send(peer_id, string.format(code, peer_id), sendcb)
        end
	]]
	
    alua.spawn(spawn_code, false, spawncb)
    alua.spawn(spawn_code, true, spawncb)
end
