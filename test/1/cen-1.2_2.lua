--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 1.2 - Criar um daemon e conectar o processo roteador a ele
--

-- Script do processo roteador

local cen = "1.2"
local msg = "Cenário " .. cen .. ": ok!"
local error_msg = "Cenario " .. cen .. ": erro!"

local ret = false

require("alua")

local function conncb(reply)
	ret = assert(reply.status == "ok", error_msg)
	
	if ret then
		print(msg)
		alua.send(alua.daemonid, "alua.quit()")
		alua.quit()
	end
end

alua.connect("127.0.0.1", 8888, conncb)

alua.loop()
