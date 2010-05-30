-----------------------------------------------------------------------------
-- CCR
--
-- version: 1.1 2010/05/15
-----------------------------------------------------------------------------

local core      = require("ccr.core")
local coroutine = require("coroutine")

local pairs = pairs

local print = print
local debug = debug
local os = os

module("ccr")

-----------------------------------------------------------------------------
-- Exported low-level functions
-----------------------------------------------------------------------------
-- Export functions in module ccr.core
for k, v in pairs(core) do
    _M[k] = v
end

-- Overides these functions with theirs returns
self   = core.self()
ismain = core.ismain()

-----------------------------------------------------------------------------
-- Exported function
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Receive data
--
-- @return the data received
-----------------------------------------------------------------------------
function receive()
    -- If the running process is the main process waits for data, don't yeild
    -- because it's needed to route message to the others processes
    -- If 
    if coroutine.running() or ismain then
        return core.receive()
    else
        while true do
            local str = core.tryreceive()
            if str then
                return str
            else
                core.yield()
            end
        end
    end
end
