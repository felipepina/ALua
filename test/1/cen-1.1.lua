-----------------------------------------------------------------------------
-- Test script
-- Scenario 1.1
-----------------------------------------------------------------------------

local cen = "1.1"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

alua.create("127.0.0.1", 8888)
print("Daemon created: " ..  alua.id)
print(suc_msg)
os.exit()