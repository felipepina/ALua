-----------------------------------------------------------------------------
-- Test script
-- Scenario 5.3
-----------------------------------------------------------------------------

require("ccr")

local cen = "5.3"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local code = [[
    require("ccr")
    
]]

ccr.spawn(code)

os.execute("sleep 2")

local ret = assert(not ccr.lookup("p2"), err_msg)

if ret then
    print(suc_msg)
end