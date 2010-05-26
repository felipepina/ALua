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

local t1, t2, flag
function sendcb(reply)
  if flag then
    alua.send(t1, "ping()")
  else
    flag = true
  end
end

function spawncb(reply)
  if t1 then
    t2 = reply
    alua.send(t1, format("remote = %q", t2), sendcb) 
    alua.send(t2, format("remote = %q", t1), sendcb) 
  else
    t1 = reply
  end
end

function conncb(reply)
  if reply.status == "ok" then
    print("[R] done")
    alua.newthread([[dofile("ping.lua")]], spawncb)
    alua.newthread([[dofile("ping.lua")]], spawncb)
  else
    print("[R] error:", reply.error)
  end
end

alua.connect("127.0.0.1", 8888, conncb)
alua.loop()
