require("alua")

local code1 = [=[
  function pong()
    print("pong")
    alua.send(remote, "ping()")
  end
]=]

local code2 = [=[
  remote = %q
  function ping()
    print("ping")
    alua.send(remote, "pong()")
  end
]=]

local c1, c2
function cb2(reply)
  c2 = reply.id
  alua.send(c1, string.format("remote = %q", c2))
  alua.send(c1, "pong()")
end

function cb1(reply)
  c1 = reply.id
  code2 = string.format(code2, c1)
  alua.newthread(code2, cb2)
end

function conncb(reply)
  print(reply.id)
  alua.newthread(code1, cb1)
end

alua.connect("127.0.0.1", 8888, conncb)
alua.loop()
