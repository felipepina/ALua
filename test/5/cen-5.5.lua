-----------------------------------------------------------------------------
-- Test script
-- Scenario 5.5
-----------------------------------------------------------------------------

require("ccr")

local cen = "5.5"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local code = [[
    require("ccr")
    
    ccr.register("p2", ccr.self)
]]

ccr.spawn(code)

os.execute("sleep 3")

local ret = assert(ccr.lookup("p2"), err_msg)

if ret then
    print(suc_msg)
end