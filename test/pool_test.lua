require("alua")

local count = 0
local flip = true
local pool_size = 4
local error = 0

function sendcb(reply)
	count = count + 1
	if math.fmod(count, 100) == 0 then
		if flip then
			pool_size, error = alua.inc_threads(2);
		else
			pool_size, error = alua.dec_threads(2);
		end

		print(pool_size, error)
		
		if pool_size > 25 then
			flip = false
		end

		if pool_size < 4 then
			flip = true
		end
		
	end

	if reply.status == "ok" then
		local code = "ping_message = alua.id .. ping_message"
		alua.send(reply.src, code, sendcb)
	end	
end

function spawncb(reply)
	if reply.status == "ok" then
		local code = "ping_message = alua.id .. ping_message"
		alua.send(reply.id, code, sendcb)
	end
end

function conncb(reply)
  if reply.status == "ok" then
	local code = [[
		-- function ping(from)
		-- 	alua.send(from, "print()", )
		-- end
		ping_message = ": Ping!"
	]]
    alua.spawn(code, true, spawncb)
    alua.spawn(code, true, spawncb)
    alua.spawn(code, true, spawncb)
  end
end

alua.connect("127.0.0.1", 8888, conncb)
alua.loop()