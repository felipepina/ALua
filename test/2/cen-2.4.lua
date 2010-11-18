-----------------------------------------------------------------------------
-- Test script
-- Scenario 2.4
-----------------------------------------------------------------------------

local cen = "2.4"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"
local proclist = {}
local count = 0
local daemonlist = {"127.0.0.1:8888/0", "127.0.0.1:8889/0", "127.0.0.1:8890/0"}

function finalize(from)
    count = count + 1
    if count == 3 then
        print(suc_msg)
        for i,proc in ipairs(proclist) do
            alua.send(proc, "alua.quit()")
        end
        
        alua.send(daemonlist[3], "alua.quit()")
        alua.send(daemonlist[2], "alua.quit()")
        alua.send(daemonlist[1], "alua.quit()")
        
        alua.quit()
    end
end

function start(pid)
	table.insert(proclist, pid)
	
	if #proclist == 3 then
		local code = "alua.sendtopeer(%q, %q)"
		alua.send(proclist[1], string.format(code, alua.id, proclist[2]))
		alua.send(proclist[2], string.format(code, alua.id, proclist[3]))
		alua.send(proclist[3], string.format(code, alua.id, proclist[1]))
	end
end

local function sendcb(reply)
	assert(reply.status == "ok", err_msg)
end

local function setdaemon(reply)
    assert(reply.status == "ok", err_msg)
	local code = "create_pro(\"" .. alua.id .. "\")"
	alua.send(reply.src, code, sendcb)
end

function main()
    local daemon_code = [=[
        local cen = "2.4"
        local suc_msg = "Scenario " .. cen .. ": ok!"
        local err_msg = "Scenario " .. cen .. ": erro!"

        local hub

        local function sendcb(reply)
        	assert(reply.status == "ok", err_msg)
        end

        local function spawncb(reply)
        	local code = "start(\"" .. reply.id .. "\")"
        	alua.send(hub, code, sendcb)
        end

        function create_pro(from)
        	hub = from
        	local spawn_code = [[
                local cen = "2.4"
                local suc_msg = "Scenario " .. cen .. ": ok!"
                local err_msg = "Scenario " .. cen .. ": erro!"

        		local peer
        		local hub

        		local function sendcb(reply)
        			local ret = assert(reply.status == "ok", err_msg) and assert(reply.src == peer, err_msg)
        			if ret then
        			    local code = "finalize(%q)"
        				alua.send(hub, string.format(code, alua.id))
        			end
        		end

        		function sendtopeer(hub_id, peer_id)
        			local code = "assert(alua.id == %q, err_msg)"
        			peer = peer_id
        			hub = hub_id
        			alua.send(peer, string.format(code, peer), sendcb)
        		end
        	]]

        	alua.spawn(spawn_code, false, spawncb)
        end
    ]=]
    
	for i, daemon in ipairs(daemonlist) do
		local code = "create_pro(\"" .. alua.id .. "\")"
		alua.send(daemon, daemon_code, setdaemon)
	end
end
