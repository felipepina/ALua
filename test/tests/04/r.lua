require("alua")

local format = string.format

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
    print("[R] done")
    remote = alua.daemonid
    alua.send(alua.daemonid, format("remote = %q ; ping()", alua.id))
  end
end

dofile("ping.lua")

alua.connect("127.0.0.1", 8888, conncb)
alua.loop()
