-----------------------------------------------------------------------------
-- Test script
-- Scenario 5.9
-----------------------------------------------------------------------------

require("ccr")

local cen = "5.9"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local code = [[
    require("ccr")
    local cen = "5.9"
    local suc_msg = "Scenario " .. cen .. ": ok!"
    local err_msg = "Scenario " .. cen .. ": erro!"
    
    ccr.register(%q, ccr.self)
    
    os.execute("sleep 5")
    
    local ret = assert(ccr.hasdata(), err_msg)
    
    if ret then
        print(suc_msg)
    end
]]

ccr.spawn(string.format(code, "p2"))
ccr.spawn(string.format(code, "p3"))

os.execute("sleep 3")

p2 = ccr.lookup("p2")
p3 = ccr.lookup("p3")

data2 = "oi 2"
data2 = "oi 3"

ccr.send(p2, data2)
ccr.send(p3, data3)

os.execute("sleep 3")

ccr.finalize()
