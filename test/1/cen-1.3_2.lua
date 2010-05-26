--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 1.3 - Enviar um comando do processo roteador para o daemon executar
--

-- Script do processo roteador

local cen = "1.3"
local msg = "Cenário " .. cen .. ": ok!"
local error_msg = "Cenario " .. cen .. ": erro!"

local ret = false

require("alua")

local function sendcb(reply)
	ret = ret and assert(reply.status == "ok", error_msg) and assert(reply.src == alua.daemonid, error_msg)

	if ret then
		print(msg)
		alua.send(alua.daemonid, "alua.quit()")
		alua.quit()
	end
end

local function conncb(reply)
	ret = assert(reply.status == "ok", error_msg)
	
	local code = [[
		assert(recv_flag, error_msg)
	]]
	
	alua.send(alua.daemonid, code, sendcb)
end

alua.connect("127.0.0.1", 8888, conncb)

alua.loop()
