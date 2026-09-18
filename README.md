# BDFD API Brasil

API independente em português brasileiro para ampliar o **Bot Designer For Discord (BDFD)** com armazenamento persistente, operações atômicas, leaderboards, cooldowns, travas distribuídas, utilitários para desenvolvedores e acesso indireto a partes da Discord API.

**API em produção:** https://bdfdapivt.vinicius-evaristoxd.workers.dev  
**Manual público:** https://go.fliplink.me/view/1F1574A9-2CAF-47E6-B9B8-22CDF0D614FA  
**Versão atual:** 2.2.0

> Este repositório é a referência pública e sanitizada da implementação. Segredos, tokens reais, dumps do banco e identificadores privados de produção não são publicados.

## O que a API resolve

O BDFD já cobre boa parte das funções normais de um bot do Discord. Esta API existe para complementar o que costuma ser mais difícil de manter apenas dentro do BDFD:

- dados persistentes separados por bot;
- variáveis globais, por servidor, usuário e membro;
- TTL para dados temporários;
- incrementos, toggles e compare-and-set;
- consultas, exportação, importação e operações em lote;
- leaderboards com posição calculada;
- cooldowns compartilhados;
- locks distribuídos para impedir duas execuções concorrentes;
- manipulação segura de JSON;
- hashes, UUIDs, Snowflakes, arrays e texto;
- pipelines de transformação sem usar `eval`;
- chamadas HTTP para múltiplas APIs em uma única requisição;
- snippets prontos para BDFD, JavaScript e cURL;
- chamadas adicionais à Discord API usando o token do próprio bot, armazenado de forma criptografada.

## Como a API funciona

O fluxo normal é este:

```text
Bot BDFD
   |
   | 1. Cadastra o bot uma vez usando o token do Discord
   v
BDFD API Brasil
   |
   | 2. Valida o token diretamente na Discord API
   | 3. Identifica o bot pelo Discord User ID
   | 4. Criptografa o token com AES-GCM
   | 5. Gera uma API Key bbk_...
   | 6. Guarda somente o hash SHA-256 da API Key
   v
Cloudflare D1
```

Depois do cadastro, o desenvolvedor usa somente a API Key `bbk_...` para acessar os recursos normais da API.

```text
Comando BDFD
   |
   | X-API-Key: bbk_...
   v
Worker
   |
   | valida a chave
   | identifica o bot
   | executa a rota
   v
D1 / DevKit / Discord API
```

Cada bot possui um namespace próprio. Dados de um bot não são consultados usando a chave de outro bot.

## 1. Cadastro do bot

Não é necessário receber uma chave administrativa.

```http
POST /v2/bots/cadastrar
Content-Type: application/json

{
  "token": "TOKEN_DO_BOT",
  "label": "Meu Bot"
}
```

O backend:

1. valida o formato da requisição;
2. chama `/users/@me` na Discord API com o token enviado;
3. confirma que o token pertence a um bot;
4. usa o ID do bot como prova de controle;
5. criptografa o token;
6. gera uma nova chave `bbk_...`;
7. armazena apenas o hash dessa chave.

Exemplo de resposta:

```json
{
  "ok": true,
  "criado": true,
  "recuperado": false,
  "bot": {
    "discordUserId": "123456789012345678",
    "discordUsername": "MeuBot"
  },
  "apiKey": "bbk_EXEMPLO"
}
```

Se o mesmo bot for cadastrado novamente com um token válido, a API trata o processo como recuperação: atualiza o token criptografado e cria uma nova API Key. A chave anterior deixa de autenticar.

### Cadastro no BDFD

```text
$nomention
$httpAddHeader[Content-Type;application/json]
$httpPost[https://bdfdapivt.vinicius-evaristoxd.workers.dev/v2/bots/cadastrar;{"token":"TOKEN_DO_BOT","label":"Meu Bot"}]

✅ Bot cadastrado!
Nome: $httpResult[bot;discordUsername]
Chave: $httpResult[apiKey]
```

Depois de concluir o cadastro, remova o comando que contém o token.

## 2. Autenticação normal

Use uma das formas:

```http
X-API-Key: bbk_...
```

ou:

```http
Authorization: Bearer bbk_...
```

No BDFD:

```text
$httpAddHeader[X-API-Key;$getVar[API_KEY]]
```

## 3. Variáveis persistentes

A API possui quatro escopos:

```text
global   -> pertence ao bot inteiro
servidor -> pertence a um servidor
usuario  -> pertence a um usuário
membro   -> pertence ao par servidor + usuário
```

Exemplos de rotas:

```text
/v2/variaveis/global/:nome
/v2/variaveis/servidor/:guildId/:nome
/v2/variaveis/usuario/:userId/:nome
/v2/variaveis/membro/:guildId/:userId/:nome
```

Gravar:

```http
PUT /v2/variaveis/usuario/123/saldo
X-API-Key: bbk_...
Content-Type: application/json

{
  "value": 1500
}
```

Ler:

```http
GET /v2/variaveis/usuario/123/saldo
X-API-Key: bbk_...
```

Valor ausente retorna um resultado estruturado com `found: false`, em vez de transformar ausência em erro genérico.

### TTL

Uma variável pode expirar automaticamente:

```json
{
  "value": "codigo-temporario",
  "ttlSeconds": 600
}
```

O TTL máximo aceito é de um ano.

### Operações atômicas

A rota `PATCH` suporta operações como:

- `set`
- `increment`
- `decrement`
- `toggle`
- `append`
- `remove`
- `setIfAbsent`
- `compareSet`

Isso reduz condições de corrida em sistemas de economia, reputação e contadores.

## 4. Consultas, cópia, lote, exportação e importação

Rotas adicionais:

```text
POST /v2/variaveis/consultar
POST /v2/variaveis/contar
POST /v2/variaveis/copiar
POST /v2/variaveis/mover
POST /v2/variaveis/lote
POST /v2/variaveis/exportar
POST /v2/variaveis/importar
```

Operações persistentes em lote são limitadas a **15 itens por chamada**. O limite foi escolhido para respeitar o número de consultas D1 disponíveis por invocação no plano gratuito do Workers.

## 5. Leaderboards

Um leaderboard é separado por `board`.

```http
PUT /v2/leaderboards/reputacao/123
X-API-Key: bbk_...
Content-Type: application/json

{
  "score": 250,
  "metadata": {
    "nivel": 8
  }
}
```

Top:

```http
GET /v2/leaderboards/reputacao?order=desc&limit=10
X-API-Key: bbk_...
```

Posição individual:

```http
GET /v2/leaderboards/reputacao/123
X-API-Key: bbk_...
```

Empates usam `user_id ASC` como critério determinístico.

## 6. Cooldowns

Cooldowns são úteis quando o bloqueio precisa ser compartilhado por diferentes comandos ou execuções.

```http
POST /v2/cooldowns/rep/123/claim
X-API-Key: bbk_...
Content-Type: application/json

{
  "seconds": 60
}
```

O claim usa uma operação condicional atômica. Duas execuções concorrentes não devem conseguir reivindicar o mesmo cooldown ativo ao mesmo tempo.

## 7. Locks distribuídos

Locks existem para proteger trechos críticos.

Exemplo: impedir que duas transferências modifiquem o mesmo saldo simultaneamente.

```text
POST /v2/travas/economia/usuario-123/acquire
POST /v2/travas/economia/usuario-123/renew
POST /v2/travas/economia/usuario-123/release
```

Quando a aquisição funciona, a API devolve um `leaseId`. Somente quem possui esse `leaseId` pode renovar ou liberar aquela trava ativa.

## 8. DevKit

O DevKit executa operações úteis no backend sem permitir JavaScript arbitrário.

Principais rotas:

```text
GET  /v2/dev/capabilities
GET  /v2/dev/uuid
GET  /v2/dev/snowflake/:id
POST /v2/dev/json/caminho
POST /v2/dev/json/manipular
POST /v2/dev/json/mesclar
POST /v2/dev/resumo
POST /v2/dev/lista
POST /v2/dev/texto/slug
POST /v2/dev/inspecionar
POST /v2/dev/fluxo
```

### Pipeline segura

`/v2/dev/fluxo` permite encadear até 50 operações previsíveis.

Exemplo conceitual:

```json
{
  "input": "Olá Mundo!",
  "operations": [
    { "op": "text.slug" },
    { "op": "text.append", "value": "-api" }
  ]
}
```

A API não usa `eval` e não executa código JavaScript enviado pelo cliente.

## 9. Multi-API

Uma única chamada pode consultar até 5 endpoints externos.

```http
POST /v2/dev/http/lote
X-API-Key: bbk_...
Content-Type: application/json

{
  "mode": "parallel",
  "requests": [
    {
      "id": "perfil",
      "url": "https://api.exemplo.com/perfil"
    },
    {
      "id": "status",
      "url": "https://api.exemplo.com/status"
    }
  ]
}
```

Modos:

- `parallel`
- `sequential`

Métodos permitidos:

- GET
- HEAD
- POST
- PUT
- PATCH
- DELETE

Proteções implementadas incluem HTTPS obrigatório, bloqueio de hosts locais/privados conhecidos, bloqueio da própria API, remoção de cabeçalhos perigosos e redirects manuais.

## 10. Discord API indireta

Para algumas funções que não existem diretamente no BDFD, a API pode utilizar o token criptografado do próprio bot.

Exemplos disponíveis incluem:

- dados do próprio bot;
- snapshots de guild;
- membros e busca de membros;
- audit log;
- bans;
- invites;
- AutoMod;
- scheduled events;
- archived threads.

A API não contorna permissões do Discord. Se o bot não possui a permissão ou intent necessária, a Discord API continuará recusando a operação.

## 11. Ajuda paginada

A central de ajuda foi criada para caber em mensagens do Discord.

```text
GET /v2/ajuda?categoria=indice
GET /v2/ajuda?categoria=variaveis&pagina=1&porPagina=4
```

O campo `texto` já vem formatado e limitado para uso direto em mensagem.

No BDFD:

```text
$nomention
$httpGet[https://bdfdapivt.vinicius-evaristoxd.workers.dev/v2/ajuda?categoria=variaveis&pagina=1]
$httpResult[texto]
```

## 12. Snippets públicos

Sem autenticação:

```text
GET /v2/dev/snippets/bdfd/cadastro
GET /v2/dev/snippets/javascript/variaveis
GET /v2/dev/snippets/curl/leaderboard
```

Linguagens aceitas incluem BDFD/BDscript/BladeScript, JavaScript/Node e cURL/Shell.

## 13. Respostas e rastreamento

As respostas do Worker recebem:

```text
X-Request-Id: <uuid>
X-API-Versao: 2.2.0
Content-Language: pt-BR
```

Erros possuem código estável para máquinas e mensagem em português para humanos.

Exemplo:

```json
{
  "ok": false,
  "error": "api_key_invalid",
  "mensagem": "A API Key informada é inválida."
}
```

## 14. Estrutura de dados

O schema definitivo possui cinco tabelas de aplicação:

```text
bots
variables
leaderboard
cooldowns
locks
```

O arquivo [schema.sql](./schema.sql) mostra a estrutura exata publicada.

## 15. Segurança das credenciais

O token do Discord precisa ser recuperável pelo backend para realizar chamadas autorizadas à Discord API, portanto ele não pode ser armazenado somente como hash.

A implementação usa:

- AES-GCM;
- IV aleatório de 12 bytes;
- segredo mestre fornecido pelo ambiente;
- SHA-256 para o hash das API Keys;
- 32 bytes aleatórios na geração das chaves `bbk_`.

O banco não possui coluna destinada ao token original em texto puro.

A API Key também não é armazenada em texto puro: somente seu hash SHA-256 é persistido.

## 16. Teste criptográfico reproduzível

Execute:

```bash
node scripts/security-selftest.mjs
```

O teste usa apenas dados fictícios e verifica:

- round-trip da criptografia;
- IVs diferentes;
- ciphertexts diferentes;
- rejeição de adulteração;
- tamanho do hash SHA-256;
- ausência do plaintext dentro do ciphertext.

## 17. Arquitetura

```text
BDFD / cliente HTTP
       |
       v
Cloudflare Worker
       |
       +---- autenticação bbk_
       |
       +---- D1
       |       + bots
       |       + variables
       |       + leaderboard
       |       + cooldowns
       |       + locks
       |
       +---- DevKit em memória
       |
       +---- Discord REST API
       |
       +---- APIs HTTPS externas
```

Mais detalhes em [docs/ARQUITETURA.md](./docs/ARQUITETURA.md).

## 18. Documentação adicional

- [Arquitetura interna](./docs/ARQUITETURA.md)
- [Guia de rotas](./docs/ROTAS.md)
- [Exemplos para BDFD](./docs/BDFD.md)
- [Segurança](./SECURITY.md)
- [Termos](./TERMS.md)
- [Schema do D1](./schema.sql)

## 19. Configuração local

`wrangler.example.jsonc` contém placeholders públicos.

Para hospedar uma cópia própria:

1. crie seu D1;
2. aplique `schema.sql`;
3. copie a configuração de exemplo;
4. configure seu próprio `database_id`;
5. defina os secrets necessários no ambiente;
6. faça o deploy do Worker.

Nunca faça commit de tokens, API Keys reais ou secrets de infraestrutura.

## 20. Conteúdo que não é publicado

Este repositório não contém:

- tokens reais de Discord;
- API Keys reais;
- chave administrativa real;
- segredo mestre de criptografia;
- dumps do banco;
- logs privados;
- identificadores privados de deploy.

## Reporte de vulnerabilidades

Não publique credenciais, dados de terceiros ou uma exploração ativa.

Consulte [SECURITY.md](./SECURITY.md).

Contato: **Discord @_.viniciuscapolar**

## Independência

BDFD API Brasil é um projeto independente. Discord e Bot Designer For Discord pertencem aos seus respectivos proprietários.
