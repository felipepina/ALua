--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 2.2 - Criar três daemons e conectá-los. Realizar troca de mensagens entre eles.
--

-- Script do processo roteador

local cen = "2.2"
local msg = "Cenário " .. cen .. ": ok!"
local error_msg = "Cenario " .. cen .. ": erro!"

-- local ret = false

local daemonlist = {"127.0.0.1:8888/0", "127.0.0.1:8889/0", "127.0.0.1:8890/0"}

require("alua")

local function sendcb(reply)
	assert(reply.status == "ok", error_msg)
	alua.quit()
end

local function linkcb(reply)
	assert(reply.status == "ok", error_msg)

	local code = "sendtodaemon(%q)"

	alua.send(reply.daemons[1], string.format(code, reply.daemons[2]), sendcb)
	alua.send(reply.daemons[2], string.format(code, reply.daemons[3]), sendcb)
	alua.send(reply.daemons[3], string.format(code, reply.daemons[1]), sendcb)
end

local function conncb(reply)
	assert(reply.status == "ok", error_msg)
	
	alua.link(daemonlist, linkcb)
end

alua.connect("127.0.0.1", 8888, conncb)

alua.loop()
