-----------------------------------------------------------------------------
-- Test script
-- Scenario 5.8
-----------------------------------------------------------------------------

require("ccr")

local cen = "5.8"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local code = [[
    require("ccr")
    
    ccr.register(%q, ccr.self)
]]

ccr.spawn(string.format(code, "p2"))
ccr.spawn(string.format(code, "p3"))

os.execute("sleep 3")

local ret = assert(ccr.lookup("p2"), err_msg)
ret = ret and assert(ccr.lookup("p3"), err_msg)

if ret then
    print(suc_msg)
end

ccr.finalize()

os.execute("sleep 3")
