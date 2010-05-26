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
  -- printtb(reply)
  code = [[
      print("[" .. alua.id .. "] Message received!")
      -- print(alua.daemonid)
  ]]
  if reply.status then
      alua.send(reply.id, "print(alua.inc_threads())", nil)
  end
  
end

-- function conncb(reply)
--   printtb(reply)
--   if reply.status == "ok" then
--     alua.newprocess(alua.daemonid, 
--       [[for k, v in pairs(alua) do print(k, v) end]],
--       spawncb)
--   end
-- end

function _sendcb(reply)
    -- print("_sendcb")
    printtb(reply)
end

function conncb(reply)
    -- print("conncb")
    -- printtb(reply)
    if reply.status == "ok" then
        -- alua.send(alua.daemonid, "print(1)", _sendcb)
        -- alua._send(alua.daemonid, 1, _sendcb)
        -- code = [[
        --     -- print("Process " .. alua.id .." started!")
        --     -- print(alua.daemonid)
        -- ]]
        -- for i=1, 5 do
        --     alua.spawn(code, spawncb, true)
        --     -- alua.spawn(code, nil, false)
        -- end
        
        code = [[
            -- print(alua.inc_threads())
            print(alua.dec_threads(2))
        ]]
        
        alua.send(alua.daemonid, code, nil)       

    end
end

alua.connect("127.0.0.1", 8888, conncb)
alua.loop()
