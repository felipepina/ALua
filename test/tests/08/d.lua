require("alua")
require("config")

if not arg[1] then
  io.stderr:write(string.format("Usage: %s <config_num>\n", arg[0]))
  os.exit(1)
end

local i = tonumber(arg[1])
local ip = config.hosts[i].ip
local port = config.hosts[i].port

print(string.format("Listen: %s:%d", ip, port))

alua.create(ip, port)
alua.loop()
