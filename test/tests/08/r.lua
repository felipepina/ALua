require("alua")
require("config")

local ip = config.hosts[1].ip
local port = config.hosts[1].port
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

function spawncb(pid)
  local d = list[2]
  alua.send(d, string.format([=[
print("***")
local function cb(pid)
  print("***", pid)
  alua.send(%q, [[ping("]]..pid..[[")]])
end
alua.newthread([[dofile("ping.lua")]], cb)
]=], pid), printtb) 
end

function linkcb(reply)
  printtb(reply)
  if reply.status == "ok" then
    alua.newthread([[dofile("ping.lua")]], spawncb)
  end
end

function conncb(reply)
  if reply.status == "ok" then
    alua.link(list, linkcb)
  end
end

dofile("ping.lua")

alua.connect(ip, port, conncb)
alua.loop()
