-----------------------------------------------------------------------------
-- Test script
-- Scenario 5.2
-----------------------------------------------------------------------------

require("ccr")

local code = [[
    require("ccr")

    local cen = "5.2"
    local suc_msg = "Scenario " .. cen .. ": ok!"
    local err_msg = "Scenario " .. cen .. ": erro!"
    
    local ret = assert(not ccr.ismain, err_msg)
    
    if ret then
        print(suc_msg)
    end
]]

ccr.spawn(code)

os.execute("sleep 5")
