--
-- Script de teste
--
-- Cenarios de validacao da biblioteca UUID
--
-- Cenario 3.3 - Criar um novo identificador único no formato numérico.
--

require("uuid")

id = uuid.create("siv")
print(#id, id)
