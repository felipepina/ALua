-----------------------------------------------------------------------------
-- Script to create a process and connect it to a daemon in the specified
-- ip and port and load a chunck from a file. As a optional parameter its
-- receive a node id to joing a deamons' network.
--      usage: lua p.lua <ip> <port> <filename> <know node>
--      <daemonlist> uses space as separator. Ex: 1.1.1.1:8080/0 1.1.1.1:8081/0 
-----------------------------------------------------------------------------

require("alua")

local ip = arg[1]
local port = tonumber(arg[2])
local filename = arg[3]

local function conncb(reply)
    assert(reply.status == alua.ALUA_STATUS_OK, err_msg)
    if filename then
        main()
    end
end

if ip and port then
    if filename then
        dofile(filename)
        alua.connect(ip, port, conncb)
    else
        alua.connect(ip, port)
    end
    alua.loop()
else
    print("usage: lua p.lua <ip> <port> <filename>")
end
