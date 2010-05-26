--
-- Script de teste
--
-- Cenarios de validacao da biblioteca UUID
--
-- Cenario 3.2 - Criar um novo identificador único no formato de string ASCII.
--

require("uuid")

id = uuid.create("str")
print(#id, id)
