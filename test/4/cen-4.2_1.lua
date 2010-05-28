-----------------------------------------------------------------------------
-- Test script
-- Scenario 4.2
-----------------------------------------------------------------------------

require("rawsend")
require("socket")

sck = socket.bind("127.0.0.1", 8888)

local cliente = sck:accept()

local data = cliente:receive("*l")

cliente:send(data .. "\n")
