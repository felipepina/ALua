--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 2.2 - Criar três daemons e conectá-los. Realizar troca de mensagens entre eles.
--

-- Script de criacao do daemon 1

local cen = "2.2"
local succ_msg = "Cenário " .. cen .. ": ok!"
error_msg = "Cenario " .. cen .. ": erro!"

recv_flag = true
local peer_id

require("alua")

local function sendcb(reply)
	local ret = assert(reply.status == "ok", error_msg) and assert(reply.src == peer_id, error_msg)
	
	if ret then
		print(succ_msg)
		-- alua.send(peer_id, "alua.quit()")
	end
end

function sendtodaemon(dst)
	peer_id = dst
	local code = "assert(recv_flag, error_msg)"
	alua.send(peer_id, code, sendcb)
end

alua.create("127.0.0.1", 8888)

alua.loop()
