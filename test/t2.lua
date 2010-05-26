-- daemon 1

require("alua")

alua.create("10.0.1.9", 8888)
alua.loop()

-- daemon 2

require("alua")

alua.create("10.0.1.110", 8889)
alua.loop()

-- router 1

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

function linkcb(reply)
  printtb(reply)
  print("Daemons linked.")
end

function spawncb(reply)
  printtb(reply)
  if reply.status == "ok" then
    list = {"10.0.1.9:8888/0", "10.0.1.110:8889/0"}
    alua.link(list, linkcb)
  end 
end

function conncb(reply)
  printtb(reply)
  if reply.status == "ok" then
  alua.newprocess(alua.daemonid, 
    [[print("Spawn process")]],
    spawncb)
  end
end

alua.connect("10.0.1.9", 8888, conncb)
alua.loop()

-- router 2

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

function sendcb(reply)
  printtb(reply)
  print("Send to R1.")
end

function spawncb(reply)
  printtb(reply)
  if reply.status == "ok" then
    -- list = {"10.0.1.9:8888/0", "10.0.1.110:8889/0"}
    -- alua.link(list, linkcb)
    alua.send("10.0.1.9:8888/2", [[print("Recebi de R2");alua.send("10.0.1.110:8889/2","print(\"Recebi de R1\")", nil)]], sendcb)
  end 
end

function conncb(reply)
  printtb(reply)
  if reply.status == "ok" then
  alua.newprocess(alua.daemonid, 
    [[print("Spawn process")]],
    spawncb)
  end
end

alua.connect("10.0.1.110", 8889, conncb)
alua.loop()