DHT
===

Armazenamento de dados
----------------------

1. Em uma rede de cinco daemons armazenar cinco pares (chave, valor) utilizando o comando alua.dht_insert. Enviar o comando de um  daemon.

2. Em uma rede de cinco daemons armazenar cinco pares (chave, valor) utilizando o comando alua.dht_insert. Enviar o comando de um processo ALua.

3. Em uma rede de cinco daemons armazenar cinco pares (chave, valor) utilizando o comando alua.dht_insert. Enviar o comando de um processo Lua.

4. Tentar armazenar um par já armazenado. Processo solicitante recebe mensagem informando que não é possível.

5. Armazenar quatro pares com os seguintes tipos de dados no campo 'value': number, string, boolean e table.

6. Tentar armazenar pares com o campo 'value' do tipo function. Processo solicitante recebe mensagem informando que não é possível.

Busca de dados
--------------

7. Buscar os dados armazenados utilizando o comando alua.dh_lookup.

8. Buscar por chave que não existe. Processo solicitante recebe mensagem informando que a chave não existe.


Exclusão de dados
-----------------

9. Incluir cinco pares e excluir três pares utilizando o comando alua.delete. Buscar os pares excluídos e os ainda armazenados utilizando o comando alua.dht_lookup.

10. Excluir um par não armazenado. Processo solicitante recebe mensagem informando que par não existe.

11. Excluir um par já excluído. Processo solicitante recebe mensagem informando que par não existe.

Criação de grupos
-----------------

Inclusão de processos em grupos
-------------------------------

Exclusão de processos de grupos
-------------------------------

Remoção de grupos
-----------------


