--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 1.2 - Criar um daemon e conectar o processo roteador a ele
--

-- Script de criacao do daemon

local cen = "1.2"
local msg = "Cenário " .. cen .. ": ok!"
local error_msg = "Cenario " .. cen .. ": erro!"

require("alua")

alua.create("127.0.0.1", 8888)

alua.loop()
