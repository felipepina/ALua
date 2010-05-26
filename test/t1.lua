-- Cen 1 - standalone daemon

-- Cen 1.1

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


function initcb(reply)
    -- printtb(reply)
    -- print(alua.id)
    -- print(alua.daemonid)
    print("initcb")
end

tb = {}
tb.cb = initcb

alua.init(tb)
alua.loop()

-- Cen 1.2

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
    print("sendbc")
    printtb(reply)
end

function initcb(reply)
    -- printtb(reply)
    -- print(alua.id)
    -- print(alua.daemonid)
    print("initcb")
    alua.send(alua.id, "print()", sendcb)
end

tb = {}
tb.cb = initcb

alua.init(tb)
alua.loop()

-- Cen 1.3

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
    -- print("spawncb")
    -- printtb(reply)
    -- print(alua.id)
    alua.send(reply.id, "print(alua.id)")
end

function initcb(reply)
    -- printtb(reply)
    -- print(alua.id)
    -- print(alua.daemonid)
    -- print("initcb")
    code = [[
        print("Process " .. alua.id .. " started.")
    ]]
    alua.spawn(code, spawncb, alua.daemonid)
    alua.spawn(code, spawncb, alua.daemonid)
    -- alua.newthread(code, spawncb)
end

tb = {}
tb.cb = initcb

alua.init(tb)
alua.loop()

-- Cen 1.4

require("alua")

local t1, t2

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
    print("Message sent to " .. reply.src)
end

function spawncb(reply)
    -- print("spawncb")
    -- printtb(reply)
    -- print(alua.id)
    -- alua.send(reply.id, "print(alua.id)")
    
    local code = [=[
        function sendcb(reply)
            print("[T = " .. alua.id .. "]" .. " Message sent to " .. reply.src)
        end
        local code = "print(\"[T = \" .. alua.id .. \"]\" .. \" Message from " .. alua.id .. "\")"
        alua.send(%q, code, sendcb)
    ]=]
    
    if t1 then
        t2 = reply
        alua.send(t1.id, string.format(code, t2.id)) 
        alua.send(t2.id, string.format(code, t1.id)) 
    else
        t1 = reply
    end
end

function initcb(reply)
    -- printtb(reply)
    -- print(alua.id)
    -- print(alua.daemonid)
    -- print("initcb")
    local code = [[
        print(string.format("[T] Process %s started.", alua.id))
    ]]
    alua.spawn(code, spawncb, alua.daemonid)
    alua.spawn(code, spawncb, alua.daemonid)
    -- alua.newthread(code, spawncb)
end

tb = {}
tb.cb = initcb

alua.init(tb)
alua.loop()



-- daemon

require("alua")

alua.create("10.0.1.9", 8888)
alua.loop()



-- router

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
  printtb(reply)
end

function conncb(reply)
  printtb(reply)
  if reply.status == "ok" then
    alua.newprocess(alua.daemonid, 
      [[for k, v in pairs(alua) do print(k, v) end]],
      spawncb)
  end
end

alua.connect("10.0.1.9", 8888, conncb)
alua.loop()