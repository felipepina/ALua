--
-- Script de teste
--
-- Cenarios de validacao da biblioteca rawsend
--
-- Cenario 4.2 - Registra um par (nome, socket) para enviar dados (função setfd)
--

require("rawsend")
require("socket")

local cen = "4.2"
local succ_msg = "Cenário " .. cen .. ": ok!"
local error_msg = "Cenario " .. cen .. ": erro!"

sck = socket.bind("127.0.0.1", 8888)

local cliente = sck:accept()

local data = cliente:receive("*l")

cliente:send(data .. "\n")
