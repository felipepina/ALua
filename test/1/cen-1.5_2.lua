--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 1.5 - Criar dois novos processos Lua associados ao daemon e realizar troca de mensagens entre eles
--

-- Script do processo roteador

local cen = "1.5"
local msg = "Cenário " .. cen .. ": ok!"
local error_msg = "Cenario " .. cen .. ": erro!"

-- local ret = false

local peer_a
local peer_b

require("alua")

local function spawncb(reply)
	assert(reply.status == "ok", error_msg)
	-- envia o comando quit para o novo processo
	-- alua.send(reply.id
	
	if not peer_a then
		peer_a = reply.id
	else
		peer_b = reply.id
		local code_a = "sendtopeer(\"" .. peer_b  .. "\")"
		local code_b = "sendtopeer(\"" .. peer_a  .. "\")"
		
		-- local code_a = "print(error_msg)"
		-- local code_b = "print(error_msg)"
		
		alua.send(peer_a, code_a)
		alua.send(peer_b, code_b)
	end
end

local function conncb(reply)
	assert(reply.status == "ok", error_msg)
	
	local spawn_code = [[
		cen = "1.5"
		succ_msg = "Cenário " .. cen .. ": ok!"
		error_msg = "Cenario " .. cen .. ": erro!"
		recv_flag = true
	
		peer_id = nil
	
		function sendcb(reply)
			if peer_id then
				local ret = assert(reply.status == "ok", error_msg) and assert(reply.src == peer_id, error_msg)
		
				if ret then
					print(succ_msg)
					-- alua.send(alua.daemonid, "alua.quit()")
					alua.quit()
				end
			end
		end
		
		function sendtopeer(peerid)
			print(alua.id .. " " .. peerid)
			peer_id = peerid
			local code = "assert(recv_flag, error_msg)"
			alua.send(peer_id, code, sendcb)
		end
	]]
	
	alua.spawn(spawn_code, false, spawncb)
	alua.spawn(spawn_code, false, spawncb)
end

alua.connect("127.0.0.1", 8888, conncb)

alua.loop()
