-----------------------------------------------------------------------------
-- Test script
-- Scenario 7.5
-----------------------------------------------------------------------------

local cen = "7.5"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local function sendcb(reply)
    if assert(reply.status == alua.ALUA_STATUS_OK, err_msg) then 
        print(suc_msg)
        local quitcode = "alua.quit()"
        alua.send(reply.src, quitcode)
        alua.send(alua.daemonid, quitcode)
        alua.quit()
    end
end

local function spawncb(reply)
    assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
    
    local ret, error = alua.send_event(reply.id, "evento_teste", print, sendcb)
    if assert(ret == false, err_msg) then
        print(suc_msg)
        alua.send(reply.id, "alua.quit()")
        alua.send(alua.daemonid, "alua.quit()")
        alua.quit()            
    end
end

function conncb(reply)
    assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
    
    local code = [[
    local count = 0

    local function count_handler(msg)
        local data_type = type(msg.data)
        
        if data_type == "number" then
            count = count + msg.data
            msg.cb(alua.ALUA_STATUS_OK)
        else
            msg.cb(alua.ALUA_STATUS_ERROR, "ERROR 9")
        end
    end
    
    alua.reg_event("evento_teste", count_handler)
    ]]
    
    alua.spawn(code, false, spawncb)
end