-----------------------------------------------------------------------------
-- Test script
-- Scenario 4.2
-----------------------------------------------------------------------------

require("rawsend")
require("socket")

local cen = "4.2"
local suc_msg = "Scenario " .. cen .. ": ok!"
local err_msg = "Scenario " .. cen .. ": erro!"

local sck = socket.connect("127.0.0.1", 8888)

rawsend.setfd("socket1", sck:getfd())

local data = "DATA"

local ret = assert(rawsend.send("socket1", data .. "\n") == 0, err_msg)

ret = ret and assert(sck:receive("*l") == data, err_msg)


if ret then
	print(suc_msg)
end

