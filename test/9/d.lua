-----------------------------------------------------------------------------
-- Script to create a daemon in the specified ip and port and load a chunck
-- from a file
--      usage: lua d.lua <ip> <port> <filename>
-----------------------------------------------------------------------------

require("alua")

local ip = arg[1]
local port = tonumber(arg[2])
local filename = arg[3]

if ip and port then
    if filename then
        dofile(filename)
    end
    alua.create(ip, port)
    print("Daemon created: " ..  alua.id)
    alua.loop()
else
    print("usage: lua d.lua <ip> <port> <filename>")
end
