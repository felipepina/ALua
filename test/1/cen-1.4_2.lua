--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 1.4 - Criar um novo processo Lua associado ao daemon e realizar troca de mensagens entre o novo processo e o daemon
--

-- Script do processo roteador

local cen = "1.4"
local msg = "Cenário " .. cen .. ": ok!"
local error_msg = "Cenario " .. cen .. ": erro!"

-- local ret = false

require("alua")

local function spawncb(reply)
	assert(reply.status == "ok", error_msg)
	-- envia o comando quit para o novo processo
	-- alua.send(reply.id
	alua.quit()
end

local function conncb(reply)
	-- ret = 
	assert(reply.status == "ok", error_msg)
	
	-- codigo do novo processo lua associado ao daemon
	local spawn_code = [[
		local cen = "1.4"
		local msg = "Cenário " .. cen .. ": ok!"
		local error_msg = "Cenario " .. cen .. ": erro!"
	
		local function sendcb(reply)
			ret = assert(reply.status == "ok", error_msg) and assert(reply.src == alua.daemonid, error_msg)

			if ret then
				print(msg)
				alua.send(alua.daemonid, "alua.quit()")
				alua.quit()
			end
		end
		
		local code = "assert(recv_flag, error_msg)"
		
		alua.send(alua.daemonid, code, sendcb)
	]]
	
	alua.spawn(spawn_code, false, spawncb)
end

alua.connect("127.0.0.1", 8888, conncb)

alua.loop()
