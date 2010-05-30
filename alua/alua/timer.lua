-----------------------------------------------------------------------------
-- Timer
--
-- Module to create and run scheduled events
--
-- version: 1.1 2010/05/15
-----------------------------------------------------------------------------

module("alua.timer", package.seeall)

local timer = require("ccr.timer")
local event = require("alua.event")

timer.core.setfmt("{type='timer', tm=%llu}")

-----------------------------------------------------------------------------
-- Alias
-----------------------------------------------------------------------------
settimer = timer.settimer

-----------------------------------------------------------------------------
-- Handler to process scheduled events
-----------------------------------------------------------------------------
local function process(msg)
    timer.trigger(msg.tm)
end

-----------------------------------------------------------------------------
-- Rigester event handler
-----------------------------------------------------------------------------
event.register("timer", process)
