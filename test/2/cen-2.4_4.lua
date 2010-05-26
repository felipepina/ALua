--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 2.4 - Em uma rede de três daemons criar em cada daemon da rede um processo Lua. Realizar troca de mensagens entres os processos.
--

-- Script do processo roteador

local cen = "2.4"
local msg = "Cenário " .. cen .. ": ok!"
local error_msg = "Cenario " .. cen .. ": erro!"

-- local ret = false

local daemonlist = {"127.0.0.1:8888/0", "127.0.0.1:8889/0", "127.0.0.1:8890/0"}
local proclist = {}

require("alua")


function start(pid)
	table.insert(proclist, pid)
	
	if #proclist == 3 then
		local code = "alua.sendtopeer(%q)"
		alua.send(proclist[1], string.format(code, proclist[2]))
		alua.send(proclist[2], string.format(code, proclist[3]))
		alua.send(proclist[3], string.format(code, proclist[1]))
	end
end

local function sendcb(reply)
	assert(reply.status == "ok", error_msg)
	-- alua.quit()
end

local function linkcb(reply)
	assert(reply.status == "ok", error_msg)
	for i,v in ipairs(reply.daemons) do
		local code = "create_pro(\"" .. alua.id .. "\")"
		alua.send(v, code, sendcb)
	end
end

local function conncb(reply)
	assert(reply.status == "ok", error_msg)
	
	alua.link(daemonlist, linkcb)
end

alua.connect("127.0.0.1", 8888, conncb)

alua.loop()
