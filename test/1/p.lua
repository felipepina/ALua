-----------------------------------------------------------------------------
-- Script to create a process and connect it to a daemon in the specified
-- ip and port and load a chunck from a file
--      usage: lua p.lua <ip> <port> <filename>
-----------------------------------------------------------------------------

require("alua")

local ip = arg[1]
local port = tonumber(arg[2])
local filename = arg[3]
daemonlist = {}

local i = 4

while arg[i] do
    table.insert(daemonlist, arg[i])
    i = i + 1
end

if ip and port then
    if filename then
        dofile(filename)
        alua.connect(ip, port, conncb)
    else
        alua.connect(ip, port, nil)
    end
    alua.loop()
else
    print("usage: lua p.lua <ip> <port> <filename>")
end
