-----------------------------------------------------------------------------
-- DHT
--
-- Module to handle DHT
--
-- version: 1.2 2010/09/15
-----------------------------------------------------------------------------

module("alua.dht", package.seeall)

local storage   = require("alua.dht.storage")
local route     = require("alua.dht.route")
local timer     = require("alua.timer")

-----------------------------------------------------------------------------
-- Modules variables
-----------------------------------------------------------------------------

local_id = nil

-- In seconds
check_interval = 1

-- Message status
DHT_STATUS_OK      = "ok"
DHT_STATUS_ERROR   = "error"


-----------------------------------------------------------------------------
-- Exported low-level functions
-----------------------------------------------------------------------------
insert_pair = storage.insert_pair
delete_pair = storage.delete_pair
lookup      = storage.lookup

init                    = route.init
join                    = route.join
leave                   = route.leave
routemsg                = route.routemsg
routeMulticastMessage   = route.routeMulticastMessage
get_nodes               = route.get_nodes
print_neighbor          = route.print_neighbor

-----------------------------------------------------------------------------
-- Auxiliary functions
-----------------------------------------------------------------------------
local function checkneighbors()
    print("Checking neighbors")
    route.stabilize()
    -- timer.settimer(check_interval, rebuild)
    timer.settimer(check_interval, checkneighbors)
end
-----------------------------------------------------------------------------
-- End auxiliary functions
-----------------------------------------------------------------------------

-- Register a timer to periodically rebuild the DHT network
-- timer.settimer(check_interval, checkneighbors)
timer.settimer(check_interval, checkneighbors)

-----------------------------------------------------------------------------
-- End alua.dht
-----------------------------------------------------------------------------
