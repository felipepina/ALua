-----------------------------------------------------------------------------
-- Test script
-- Scenario 1.8
-----------------------------------------------------------------------------

local cen = "1.8"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local proc_list = {}
local count = 0
local proc_total = 10

local function start(reply)
    local code = [[assert(alua.id == %q, err_msg)]]
    -- print("count", count)
    
    -- if count == 500 then
    --     print(alua.inc_threads(15))
    -- elseif count == 3000 then
    --     print(alua.dec_threads(10))
    -- end
    
    if count == 10 then
        alua.inc_threads(30)
    end

    if count < 5000 then
        alua.send(reply.src, string.format(code, reply.src), start)
        count = count + 1
    else
        local quit_code = "alua.quit()"
        for i, proc in ipairs(proc_list) do
            if proc ~= alua.id then
                alua.send(proc, quit_code)
            end
        end
        alua.send(alua.daemonid, quit_code)
        print(suc_msg)
        alua.quit()
    end
end


local function sendcb(reply)
    assert(reply.status == "ok", err_msg)
    
    local code = "start(%q, %q)"
    alua.send(reply.src, string.format(code, alua.id, proc_list[math.random(1, proc_total)]), start)
end

local function spawncb(reply)
    assert(reply.status == "ok", err_msg)
    
    -- print(reply.id)

    table.insert(proc_list, reply.id)

	if #proc_list == proc_total then
        for i,proc in ipairs(proc_list) do
            alua.send(proc, "proc_list = " .. alua.tostring(proc_list), sendcb)
        end
        
        table.insert(proc_list, alua.id)
    end
end

function conncb(reply)
	assert(reply.status == "ok", err_msg)
	
	local spawn_code = [=[
        local cen = "1.8"
        local suc_msg = "Scenario " .. cen .. ": ok!"
        local err_msg = "Scenario " .. cen .. ": erro!"

        local main_proc = nil
        proc_list = {}
        
        local function sendcb(reply)
            -- local code = [[assert(alua.id == %q, err_msg)
            -- print(1)]]
            local code = [[ping(%q)]]
            alua.send(reply.src, string.format(code, alua.id), sendcb)
        end
        
        function ping(from)
            -- print("Ping!")
            -- local code = [[ping(%q)]]
            -- alua.send(from, string.format(code, alua.id), sendcb)
        end

        function start(from, to)
            -- print(from , to)
            main_proc = from
            local code = [[assert(alua.id == %q, err_msg)]]
            alua.send(to, string.format(code, to), sendcb)
        end
	]=]
	
	for i = 1, proc_total do
	    alua.spawn(spawn_code, true, spawncb)
	end
end
