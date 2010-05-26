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

function linkcb(reply)
  printtb(reply)
  if reply.status == "ok" then
     for _, d in pairs(reply.daemons) do
       if d ~= alua.daemonid then
         alua.newthread(string.format([[dofile("ping.lua") ; ping(%q)]], d))
         break
       end
     end
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
