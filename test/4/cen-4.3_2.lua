--
-- Script de teste
--
-- Cenarios de validacao da biblioteca rawsend
--
-- Cenario 4.3 - Envia dado para um nome não registrado (função send). Verificar se o retorno da função é igual a -1.
--

require("rawsend")
require("socket")

local cen = "4.3"
local succ_msg = "Cenário " .. cen .. ": ok!"
local error_msg = "Cenario " .. cen .. ": erro!"

local sck = socket.connect("127.0.0.1", 8888)

rawsend.setfd("socket1", sck:getfd())

local data = "DADOS"

local ret = assert(rawsend.send("socket2", data .. "\n") == -1, error_msg)

if ret then
	print(succ_msg)
end
