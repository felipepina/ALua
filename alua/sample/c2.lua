require("alua")

local code = [=[

  function pong()
    print("pong")
    alua.send(alua.daemonid, "ping()")
  end

  alua.send(alua.daemonid, string.format("remote = %q", alua.id))
  alua.send(alua.daemonid, [[
    print("done")
    function ping()
      print("ping")
      alua.send(remote, "pong()")
    end
    print("done")
  ]])
  alua.send(alua.daemonid, "print(123) ; ping()")
]=]

function conncb(reply)
  print(reply.id)
  alua.newthread(code)
end

alua.connect("127.0.0.1", 8888, conncb)
alua.loop()
