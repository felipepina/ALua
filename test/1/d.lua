-----------------------------------------------------------------------------
-- Script to create a daemon in the specified ip and port and load a chunck
-- from a file
--      usage: lua d.lua <ip> <port> <filename>
-----------------------------------------------------------------------------

require("alua")

local ip            = arg[1]
local port          = tonumber(arg[2])
local remote_node   = arg[3]
local filename      = arg[4]

local function linkcb(reply)
    assert(reply.status == alua.ALUA_STATUS_OK, reply.error)
    print(string.format("Daemon %s joined the network!", alua.daemonid))
end

function join_network()
    alua.link(remote_node, linkcb)
end

if ip and port then
    if filename then
        dofile(filename)
    end
    if remote_node then
        alua.create(ip, port, join_network)
    else   
        alua.create(ip, port)
    end
    print("Daemon created: " ..  alua.id)
    alua.loop()
else
    print("usage: lua d.lua <ip> <port> <remote node> <filename>")
end
