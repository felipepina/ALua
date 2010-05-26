--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 1.6 - Criar novo processo Lua no daemon. Processo roteador troca mensagens com o processo Lua no daemon.
--

-- Script do processo roteador

local cen = "1.6"
local succ_msg = "Cenário " .. cen .. ": ok!"
local error_msg = "Cenario " .. cen .. ": erro!"
local ret = false
local spawn_id

recv_flag = true

require("alua")

local function sendcb(reply)
	assert(reply.status == "ok", error_msg)
	-- print(reply.status)
end

local function spawncb(reply)
	assert(reply.status == "ok", error_msg)

	spawn_id = reply.id
	
	local code = "start(\"" .. alua.id  .. "\")"
	-- print(code)
	alua.send(spawn_id, code, sendcb)
end

local function conncb(reply)
	assert(reply.status == "ok", error_msg)
	
	local spawn_code = [[
		cen = "1.6"
		succ_msg = "Cenário " .. cen .. ": ok!"
		error_msg = "Cenario " .. cen .. ": erro!"
		recv_flag = true
	
		local function sendcb(reply)
			ret = assert(reply.status == "ok", error_msg)

			if ret then
				print(succ_msg)
				alua.send(alua.daemonid, "alua.quit()")
				alua.quit()
			end
		end
		
		function start(dst)
			local code = "alua.quit()"
			-- local code = "assert(recv_flag, error_msg)"
			alua.send(dst, code, sendcb)
		end
	]]
	
	alua.spawn(spawn_code, false, spawncb)
end

alua.connect("127.0.0.1", 8888, conncb)

alua.loop()
