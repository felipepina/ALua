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

function ping(id)
  print(alua.id, "ping")
  alua.send(id, string.format("pong(%q)", alua.id), printtb)
end

function pong(id)
  print(alua.id, "pong")
  alua.send(id, string.format("ping(%q)", alua.id), printtb)
end

