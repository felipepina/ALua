-----------------------------------------------------------------------------
-- Event
--
-- Module to register and invoke the event handlers.
--
-- version: 1.1 2010/05/30
-----------------------------------------------------------------------------

module("alua.event", package.seeall)

-----------------------------------------------------------------------------
-- Module variables
-----------------------------------------------------------------------------
local events = {}

local callbacks = {}
local pending = {}

local contexts = {}
-----------------------------------------------------------------------------
-- Exported functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Sets the callback function within a context
--
-- @param cb The callback
-- @param ctx The context
--
-- @return The callback id
-----------------------------------------------------------------------------
function setcb(cb, ctx)
    local idx = #pending + 1
    pending[idx] = true
    contexts[idx] = ctx
    callbacks[idx] = cb
    return idx
end -- function setcb

-----------------------------------------------------------------------------
-- Gets the callback function
--
-- @param idx The callback id
--
-- @return The callback function and the context
-----------------------------------------------------------------------------
function getcb(idx)
    local cb = callbacks[idx]
    local ctx = contexts[idx]
    pending[idx] = nil
    contexts[idx] = nil
    callbacks[idx] = nil
    return cb, ctx
end -- function getcb

-----------------------------------------------------------------------------
-- Set a context
--
-- @param ctx The context
--
-- @return The context id
-----------------------------------------------------------------------------
function setctx(ctx)
    local idx = #contexts + 1
    contexts[idx] = ctx
    return idx
end -- function setctx

-----------------------------------------------------------------------------
-- Get a context
--
-- @param idx The context id
--
-- @return The context
-----------------------------------------------------------------------------
function getctx(idx)
    local cb = contexts[idx]
    return cb
end -- function getctx

-----------------------------------------------------------------------------
-- Delete a context
--
-- @param idx The context id
-----------------------------------------------------------------------------
function delctx(idx)
    contexts[idx] = nil
end

-----------------------------------------------------------------------------
-- Registers a event handler
--
-- @param name The event name
-- @param handler The event handler
-----------------------------------------------------------------------------
function register(name, handler)
    events[name] = handler
end -- function register

-----------------------------------------------------------------------------
-- Unregisters a event handler
--
-- @param name The event name
-----------------------------------------------------------------------------
function unregister(name)
    events[name] = nil
end -- function unregister

-----------------------------------------------------------------------------
-- Processes a message (event) and invoke the registered handler
--
-- @param msg The message (event) to process
-----------------------------------------------------------------------------
function process(msg)
    local f = events[msg.type]
    if f then
        f(msg)
    end
end -- function process

 -----------------------------------------------------------------------------
 -- End exported functions
 -----------------------------------------------------------------------------
