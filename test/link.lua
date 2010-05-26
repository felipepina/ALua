require("alua")

local ds = {"127.0.0.1:8888/0", "127.0.0.1:8889/0", "127.0.0.1:8890/0", "127.0.0.1:8891/0"}

function linkcb(reply)
  print("Reply")
  for k, v in pairs(reply) do print(k, v) end
  
  code = [[
  print(1)
  for k,v in alua.get_daemon_it() do
    print(k,v)
  end
  ]]

  for i,v in ipairs(ds) do
    alua.send(v, code)
  end
  os.exit()
end

function conncb(reply)
  print(reply.id)
  alua.link(ds, linkcb)
end

alua.connect("127.0.0.1", 8888, conncb)
alua.loop()
