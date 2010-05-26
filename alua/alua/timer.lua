-----------------------------------------------------------------------------
-- Timer
--
-- version: 1.1 2010/05/15
-----------------------------------------------------------------------------

module("alua.timer", package.seeall)

local timer = require("ccr.timer")
local event = require("alua.event")

timer.core.setfmt("{type='timer', tm=%llu}")

settimer = timer.settimer

local function process(msg)
    timer.trigger(msg.tm)
end

event.register("timer", process)
