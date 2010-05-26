--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 2.3 - Criar três daemons e conectá-los. Cria mais um daemon e conectá-lo somente a um dos três anteriormente ligados em rede. Realizar troca de mensagens entre eles.
--

-- Script do processo roteador

local cen = "2.3"
local msg = "Cenário " .. cen .. ": ok!"
local error_msg = "Cenario " .. cen .. ": erro!"

-- local ret = false

local daemonlist = {"127.0.0.1:8888/0", "127.0.0.1:8889/0", "127.0.0.1:8890/0"}

require("alua")

local function sendcb(reply)
	assert(reply.status == "ok", error_msg)
	-- alua.quit()
end

local function linkcb2(reply)
	
	daemonlist[4] = "127.0.0.1:8891/0"
	
	-- for i,v in ipairs(daemonlist) do
	-- 	print(i,v)
	-- end
	
	local code = "sendtodaemon(%q)"
	alua.send(daemonlist[1], string.format(code, daemonlist[2]), sendcb)
	alua.send(daemonlist[2], string.format(code, daemonlist[3]), sendcb)
	alua.send(daemonlist[3], string.format(code, daemonlist[4]), sendcb)
	alua.send(daemonlist[4], string.format(code, daemonlist[1]), sendcb)
end

local function linkcb(reply)
	assert(reply.status == "ok", error_msg)
	local list = {"127.0.0.1:8889/0", "127.0.0.1:8891/0"}
	alua.link(list, linkcb2)
end

local function conncb(reply)
	assert(reply.status == "ok", error_msg)
	
	alua.link(daemonlist, linkcb)
end

alua.connect("127.0.0.1", 8888, conncb)

alua.loop()
