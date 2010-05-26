--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 2.4 - Em uma rede de três daemons criar em cada daemon da rede um processo Lua. Realizar troca de mensagens entres os processos.
--

-- Script de criacao do daemon 3

local cen = "2.4"
local succ_msg = "Cenário " .. cen .. ": ok!"
error_msg = "Cenario " .. cen .. ": erro!"

recv_flag = true
local peer_id
local ret = false

require("alua")

local hub

local function sendcb(reply)
	assert(reply.status == "ok", error_msg)
end

local function spawncb(reply)
	local code = "start(\"" .. reply.id .. "\")"
	alua.send(hub, code, sendcb)
end

function create_pro(from)
	hub = from
	local spawn_code = [[
		local cen = "2.4"
		local succ_msg = "Cenário " .. cen .. ": ok!"
		error_msg = "Cenario " .. cen .. ": erro!"
		local peer
		
		recv_flag = true
		
		local function sendcb(reply)
			local ret = assert(reply.status == "ok", error_msg) and assert(reply.src == peer, error_msg)
			if ret then
				print(succ_msg)
			end
		end

		function sendtopeer(peer_id)
			local code = "assert(recv_flag, error_msg)"
			peer = peer_id
			alua.send(peer, code, sendcb)
		end
	]]
	
	alua.spawn(spawn_code, false, spawncb)
end

alua.create("127.0.0.1", 8890)

alua.loop()
