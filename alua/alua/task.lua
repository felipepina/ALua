------------------------------------------------------------------------------
-- Task
--
-- Module to manage the events that the process sends to itself.
--
-- version: 1.1 2010/05/15
-----------------------------------------------------------------------------

module("alua.task", package.seeall)

local alua  = require("alua")
local event = require("alua.event")
-- TODO Retirar a linha abaixo
-- local mbox  = require("alua.mbox")


-----------------------------------------------------------------------------
-- Exported variables
-----------------------------------------------------------------------------
hasdata = false

-----------------------------------------------------------------------------
-- Module variables
-----------------------------------------------------------------------------
local signal = false
local tasks = {}

-----------------------------------------------------------------------------
-- Exported functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Processes the messages (events)
--
-- @return true if events were processed
-----------------------------------------------------------------------------
function process()
    if hasdata then
        local tmp = tasks
        tasks = {}
        hasdata = false
        for _, t in ipairs(tmp) do
            t.func(unpack(t.args))
        end
        return true
    end
end

-----------------------------------------------------------------------------
-- Sends a message (event) to itself
-----------------------------------------------------------------------------
function schedule(f, ...)
    tasks[#tasks+1] = {func = f, args = {...}}
    hasdata = true
end

-----------------------------------------------------------------------------
-- End exported functions
-----------------------------------------------------------------------------

-- TODO Deletar as linhas daqui até o final

--event.register("task", process)
--

--[[
local function process(msg)
   local t = tasks[msg.idx]
   tasks[msg.idx] = nil
   t.func(unpack(t.args))
end
--]]

--[[
function schedule(f, ...)
   local idx = #tasks+1
   tasks[idx] = {func = f, args={...}}
   mbox.send(alua.id, {type='task', idx=idx})
end
--]]
