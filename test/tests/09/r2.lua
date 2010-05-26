require("alua")
require("config")

if not arg[1] then
  io.stderr:write(string.format("Usage: %s <pid>\n", arg[0]))
  os.exit(1)
end

local pid = arg[1]
local ip = config.hosts[2].ip
local port = config.hosts[2].port
local list = {}
for k, v in pairs(config.hosts) do
  table.insert(list, string.format("%s:%d/0", v.ip, v.port))
end

function printtb(tb, s)
  s = s or 0
  for k, v in pairs(tb) do
    for i = 1, s do io.stdout:write("  ") end
    print(k, v)
    if type(v) == "table" then
      printtb(v, s+1)
    end
  end
end

function conncb(reply)
  if reply.status == "ok" then
    alua.send(pid, string.format("ping(%q)", alua.id))
  end
end

dofile("ping.lua")

alua.connect(ip, port, conncb)
alua.loop()
