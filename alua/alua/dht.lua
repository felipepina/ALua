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
local_node_id = nil
-- In seconds
rebuild_interval = 120

-- Message status
DHT_STATUS_OK      = "ok"
DHT_STATUS_ERROR   = "error"


-----------------------------------------------------------------------------
-- Exported low-level functions
-----------------------------------------------------------------------------
insert_pair = storage.insert_pair
delete_pair = storage.delete_pair
lookup      = storage.lookup

init        = route.init
join        = route.join
leave       = route.leave
routemsg    = route.routemsg
get_nodes   = route.get_nodes


-----------------------------------------------------------------------------
-- Auxiliary functions
-----------------------------------------------------------------------------
local function rebuild()
    route.rebuild()
    timer.settimer(rebuild_interval, rebuild)
end
-----------------------------------------------------------------------------
-- End auxiliary functions
-----------------------------------------------------------------------------

-- Register a timer to periodically rebuild the DHT network
timer.settimer(rebuild_interval, rebuild)

-----------------------------------------------------------------------------
-- End alua.dht
-----------------------------------------------------------------------------
