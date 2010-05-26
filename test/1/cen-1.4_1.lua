--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 1.4 - Criar um novo processo Lua associado ao daemon e realizar troca de mensagens entre o novo processo e o daemon
--

-- Script de criacao do daemon

cen = "1.4"
-- msg = "Cenário " .. cen .. ": ok!"
error_msg = "Cenario " .. cen .. ": erro!"

recv_flag = true

require("alua")

alua.create("127.0.0.1", 8888)

alua.loop()
