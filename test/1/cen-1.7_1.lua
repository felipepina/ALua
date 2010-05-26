--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 1.7 - Criar dois processos Lua: um no daemon e outro no processo roteador. Realizar troca de mensagens entre eles.
--

-- Script de criacao do daemon

cen = "1.7"
-- msg = "Cenário " .. cen .. ": ok!"
error_msg = "Cenario " .. cen .. ": erro!"

recv_flag = true

require("alua")

alua.create("127.0.0.1", 8888)

alua.loop()
