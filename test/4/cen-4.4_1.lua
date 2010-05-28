-----------------------------------------------------------------------------
-- Test script
-- Scenario 4.3
-----------------------------------------------------------------------------

require("rawsend")
require("socket")

sck = socket.bind("127.0.0.1", 8888)

local cliente = sck:accept()

local data = cliente:receive("*l")
