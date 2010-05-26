--
-- Script de teste
--
-- Cenarios com apenas um daemon
--
-- Cenario 1.3 - Enviar um comando do processo roteador para o daemon executar
--

-- Script de criacao do daemon

cen = "1.3"
-- msg = "Cenário " .. cen .. ": ok!"
error_msg = "Cenario " .. cen .. ": erro!"

recv_flag = true

require("alua")

alua.create("127.0.0.1", 8888)

alua.loop()
