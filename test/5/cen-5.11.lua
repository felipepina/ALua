-----------------------------------------------------------------------------
-- Test script
-- Scenario 5.11
-----------------------------------------------------------------------------

require("ccr")

local cen = "5.11"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local code = [[
    require("ccr")
    local cen = "5.11"
    local suc_msg = "Scenario " .. cen .. ": ok!"
    local err_msg = "Scenario " .. cen .. ": erro!"
    
    local remote_data = %q
    
    ccr.register(%q, ccr.self)
    
    os.execute("sleep 5")
    
    if ccr.hasdata() then
        data = ccr.receive()
    end

    local ret = assert(not ccr.hasdata(), err_msg)

    if ret then
        print(suc_msg)
    end



]]

data2 = "data to p2"
data3 = "data to p3"

ccr.spawn(string.format(code, data2, "p2"))
ccr.spawn(string.format(code, data3, "p3"))

os.execute("sleep 3")

p2 = ccr.lookup("p2")
p3 = ccr.lookup("p3")

ccr.send(p2, data2)
ccr.send(p3, data3)

os.execute("sleep 3")

ccr.finalize()
