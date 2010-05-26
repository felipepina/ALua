require("alua")


function ping(id)
  print("ping")
  alua.send(id, string.format("pong(%q)", alua.id))
end

local remote = arg[1]
function conncb(reply)
  print(reply.id)
  alua.send(remote, string.format("pong(%q)", alua.id))
end

alua.connect("127.0.0.1", 8888, conncb)
alua.loop()
