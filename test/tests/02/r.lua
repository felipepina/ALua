require("alua")

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

function spawncb(reply)
  remote = reply
  alua.send(reply, string.format([[remote = %q]], alua.id))
  alua.send(reply, [[ping()]])
end

function conncb(reply)
  if reply.status == "ok" then
    alua.newthread([[dofile("ping.lua")]], spawncb)
  else
    print("[R] error:", reply.error)
  end
end

dofile("ping.lua")

alua.connect("127.0.0.1", 8888, conncb)
alua.loop()
