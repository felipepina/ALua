require("alua")

local ds = {"127.0.0.1:8888/0", "127.0.0.1:8889/0"}

function linkcb(reply)
  print("Reply")
  for k, v in pairs(reply) do print(k, v) end
  
  print("Get daemons list via API")
  for k,v in alua.get_daemon_it() do print(k, v) end
    os.exit()
end

function conncb(reply)
  print(reply.id)
  alua.link(ds, linkcb)
end

alua.connect("127.0.0.1", 8888, conncb)
alua.loop()
