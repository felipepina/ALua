-----------------------------------------------------------------------------
-- Mailbox
--
-- Module to manage the communication between Lua processes in the same ALua
-- process.
--
-- version: 1.1 2010/05/15
-----------------------------------------------------------------------------

module("alua.mbox", package.seeall)

local ccr     = require("ccr")
local marshal = require("alua.marshal")
local event   = require("alua.event")

-----------------------------------------------------------------------------
-- Aliases
-----------------------------------------------------------------------------
local dump    = marshal.dump
local load    = marshal.load

local encode    = marshal.encode
local decode    = marshal.decode

local receive       = ccr.receive
local tryreceive    = ccr.tryreceive
local hasdata       = ccr.hasdata
local evtprocess    = event.process

-----------------------------------------------------------------------------
-- Module variables
-----------------------------------------------------------------------------
local cache = {}

-----------------------------------------------------------------------------
-- Auxiliary functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Looks up for a process by the process id
--
-- @param dst The process id
--
-- @return The process
-----------------------------------------------------------------------------
local function lookup(dst)
    local proc = cache[dst]
    if not proc then
        proc = ccr.lookup(dst)
        cache[dst] = proc
    end
    return proc
end

-----------------------------------------------------------------------------
-- End auxiliary functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Exported functions
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Sends a message (event) to a process
--
-- @param dst The process id
-- @param msg The message (event)
--
-- @return True if the message was sent and false if the process was unkonw
-----------------------------------------------------------------------------
function send(dst, msg)
    local proc = lookup(dst)
    if proc then
        ccr.send(proc, dump(msg))
        return true
    end
    return false, "unknown destination"
end

-----------------------------------------------------------------------------
-- Registers the calling process with a id
--
-- @param name The id to register thr process
-----------------------------------------------------------------------------
function register(name)
    cache[name] = ccr.self
    ccr.register(name, ccr.self)
end

-----------------------------------------------------------------------------
-- Processes the inter-process messages (events)
--
-- @param block true if the process blocks until data is avaliable, false
--              otherwise
--
-- @return true if events were processed
-----------------------------------------------------------------------------
function process(block)
    local found
    if block then
        msg = receive()
        succ, msg = load(msg)
        evtprocess(msg)
        found = true
    else
        msg = tryreceive()
        if not msg then
            return
        end
        succ, msg = load(msg)
        evtprocess(msg)
        found = true
    end
    return found
end

-----------------------------------------------------------------------------
-- End exported functions
-----------------------------------------------------------------------------
