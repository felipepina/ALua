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

local sck = socket.connect("127.0.0.1", 8888)

rawsend.setfd("socket1", sck:getfd())

local data = "DADOS"

local ret = assert(rawsend.send("socket1", data .. "\n") == 0, error_msg)

ret = ret and assert(sck:receive("*l") == data, error_msg)


if ret then
	print(succ_msg)
end

