require("alua")

function printtb(tb, s)
  s = s or 0
  for k, v in pairs(tb) do
    for i = 1, s do io.stdout:write("  ") end
    print(alua.id, k, v)
    if type(v) == "table" then
      printtb(v, s+1)
    end
  end
end

function ping()
  print(alua.id, "ping")
  alua.send(remote, "pong()", printtb)
end

function pong()
  print(alua.id, "pong")
  alua.send(remote, "ping()", printtb)
end

