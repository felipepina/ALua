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

local t
function sendcb(reply)
  if flag then
    alua.send(t, "ping()")
  else
    flag = true
  end
end

function spawncb(reply)
  t = reply
  alua.send(t, "remote = alua.daemonid", sendcb) 
  alua.send(alua.daemonid, format("remote = %q", t), sendcb) 
end

function conncb(reply)
  if reply.status == "ok" then
    print("[R] done")
    alua.newthread([[dofile("ping.lua")]], spawncb)
  else
    print("[R] error:", reply.error)
  end
end

alua.connect("127.0.0.1", 8888, conncb)
alua.loop()
