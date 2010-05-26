require("alua")

function pong(id)
  print("pong")
  alua.send(id, string.format("ping(%q)", alua.id))
end

function conncb(reply)
  print(reply.id)
end

alua.connect("127.0.0.1", 8889, conncb)
alua.loop()
