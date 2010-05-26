--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 1.1 - Criar de daemon
--

-- Script de criacao do daemon

local cen = "1.1"
local msg = "Cenário " .. cen .. ": ok!"
local error_msg = "Cenario " .. cen .. ": erro!"

local id = "127.0.0.1:8888/0"

require("alua")

alua.create("127.0.0.1", 8888)

local ret = assert(id == alua.id, error_msg) and assert(id == alua.daemonid, error_msg)

if ret then
	print(msg)
end

alua.loop()
