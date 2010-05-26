--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 1.6 - Criar novo processo Lua no daemon. Processo roteador troca mensagens com o processo Lua no daemon.
--

-- Script de criacao do daemon

cen = "1.6"
-- msg = "Cenário " .. cen .. ": ok!"
error_msg = "Cenario " .. cen .. ": erro!"

recv_flag = true

require("alua")

alua.create("127.0.0.1", 8888)

alua.loop()
