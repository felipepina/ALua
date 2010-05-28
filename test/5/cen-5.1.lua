-----------------------------------------------------------------------------
-- Test script
-- Scenario 5.1
-----------------------------------------------------------------------------

require("ccr")

local cen = "5.1"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local ret = assert(ccr.ismain, err_msg)

if ret then
    print(suc_msg)
end