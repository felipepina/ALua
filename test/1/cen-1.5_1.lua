--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 1.5 - Criar dois novos processos Lua associados ao daemon e realizar troca de mensagens entre eles
--

-- Script de criacao do daemon

cen = "1.5"
-- msg = "Cenário " .. cen .. ": ok!"
error_msg = "Cenario " .. cen .. ": erro!"

recv_flag = true

require("alua")

alua.create("127.0.0.1", 8888)

alua.loop()
