-----------------------------------------------------------------------------
-- Test script
-- Scenario 9.1
-----------------------------------------------------------------------------

local cen = "9.1"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local tdlist = {}
local result = true

local function data_handler(data)
    table.insert(tdlist, data)
    if #tdlist == #daemonlist then
        for k,v in pairs(tdlist) do
            table.sort(v)
        end
        
        table.sort(daemonlist)

        for i = 1, #tdlist do
            for j = 1, #tdlist do
                result = result and assert(tdlist[j][i] == daemonlist[i], err_msg)
            end
        end
        
        if result then
            print(suc_msg)
            for i = 1, #daemonlist do
                alua.send(daemonlist[#daemonlist + 1 - i], "alua.quit()")
            end
            alua.quit()
        end
    end
end

local function setfuncb(reply)
	assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
    
    local code = "dlist(%q)"
    
    for k,v in pairs(daemonlist) do
        alua.send(v, string.format(code, alua.id))
    end

end

local function linkcb(reply)
	assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
	
	local funcode = [[
        function dlist(from)
            local list = alua.getdaemons()
            
            alua.send_data(from, list)
        end
    ]]

	alua.send(reply.daemons[1], funcode)
	alua.send(reply.daemons[2], funcode)
	alua.send(reply.daemons[3], funcode, setfuncb)
end

function conncb(reply)
	assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
	alua.link(daemonlist, linkcb)
end

alua.reg_data_handler(data_handler)
