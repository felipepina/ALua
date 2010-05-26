--
-- Script de teste
--
-- Cenarios de validacao da biblioteca UUID
--
-- Cenario 3.3 - Criar um novo identificador único no formato textual.
--

require("uuid")

id = uuid.create("txt")
print(#id, id)
