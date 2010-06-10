-----------------------------------------------------------------------------
-- Test script
-- Scenario 6.4
-----------------------------------------------------------------------------

function sendcb(reply)
    if reply.status=="ok" then
        alua.send(alua.daemonid, "alua.quit()")
        alua.quit()
    end
end

function spawncb(reply)
    if reply.status == "ok" then
        local data = {first = 1, second = "2", third = false}
        alua.send_data(reply.id, data, sendcb)
    end
end

function conncb(reply)
    if reply.status=="ok" then
        local code = [[
            local cen = "6.4"
            local suc_msg = "Scenario " .. cen .. ": ok!"
            local err_msg = "Scenario " .. cen .. ": erro!"
            
            local local_data = {first = 1, second = "2", third = false}

            local function user_data_handler(data)
                local ret = assert((local_data.first == data.first) and (local_data.second == data.second) and (local_data.third == data.third), err_msg)
                
                if ret then
                    print(suc_msg)
                    alua.quit()
                end
            end
            
            alua.reg_data_handler(user_data_handler)
        ]]
        alua.spawn(code, true, spawncb)
    end
end