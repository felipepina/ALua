-----------------------------------------------------------------------------
-- Test script
-- Scenario 2.2
-----------------------------------------------------------------------------

local cen = "2.2"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local function sendcb(reply)
	assert(reply.status == "ok", err_msg)
end

local function setfuncb(reply)
	assert(reply.status == "ok", err_msg)
    
    local code = "sendtodaemon(%q)"
    
    if reply.src == daemonlist[1] then
	    alua.send(reply.src, string.format(code, daemonlist[2]), sendcb)
	elseif reply.src == daemonlist[2] then
	    alua.send(reply.src, string.format(code, daemonlist[3]), sendcb)
	elseif reply.src == daemonlist[3] then
	    alua.send(reply.src, string.format(code, daemonlist[1]), sendcb)
	end
end

local function linkcb(reply)
	assert(reply.status == "ok", err_msg)
	
	local funcode = [[
    	local cen = "2.2"
        local suc_msg = "Scenario " .. cen .. ": ok!"
        local err_msg = "Scenario " .. cen .. ": erro!"
        
        local peer_id = nil
        local count = 0

        function finalize(src)
            count = count + 1
            
            if count == 3 then
                print(suc_msg)

                local ip, port, id = string.match(alua.id, "^(%d+%.%d+%.%d+%.%d+):(%d+)/(%d+)")
                alua.send(ip .. ":8889/0", "alua.quit()")
                alua.send(ip .. ":8890/0", "alua.quit()")

                local dst = string.match(alua.id, "^(%d+%.%d+%.%d+%.%d+:%d+)") .. "/1"
                alua.send(dst, "alua.quit()")
                alua.quit()
            end
        end

        local function sendcb(reply)
            local ret = assert(reply.status == "ok", err_msg) and assert(reply.src == peer_id, err_msg)
            local ip, port, id = string.match(alua.id, "^(%d+%.%d+%.%d+%.%d+):(%d+)/(%d+)")
            alua.send(ip .. ":8888/0", string.format("finalize(%q)", alua.id))
        end

	    function sendtodaemon(dst)
	        peer_id = dst
    	    local code = string.format("assert(alua.daemonid == %q, err_msg)", peer_id)
    	    alua.send(peer_id, code, sendcb)
        end]]

	alua.send(reply.daemons[1], funcode, setfuncb)
	alua.send(reply.daemons[2], funcode, setfuncb)
	alua.send(reply.daemons[3], funcode, setfuncb)
end

function conncb(reply)
	assert(reply.status == "ok", err_msg)
	alua.link(daemonlist, linkcb)
end
