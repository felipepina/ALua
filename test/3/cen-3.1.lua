--
-- Script de teste
--
-- Cenarios de validacao da biblioteca UUID
--
-- Cenario 3.1 - Criar um novo identificador único no formato binário.
--

require("uuid")

id = uuid.create("bin")
print(#id, id)
