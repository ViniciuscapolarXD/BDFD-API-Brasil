# Segurança e Comprovação Criptográfica — BDFD API Brasil

**Versão analisada:** API v2.2.0  
**Data da verificação:** 18 de setembro de 2026

Este documento descreve o comportamento **real da implementação atual** de proteção de tokens e API Keys da BDFD API Brasil.

Ele não constitui certificação independente, pentest ou promessa de invulnerabilidade. A finalidade é fornecer evidências técnicas reproduzíveis e deixar claro o que a implementação efetivamente faz.

## 1. Resumo

O token do Discord enviado no cadastro precisa ser utilizado posteriormente para chamadas autorizadas à Discord API. Por isso, ele precisa ser recuperável pelo backend e não pode ser protegido somente com hash.

A implementação atual utiliza:

- **AES-GCM** para criptografar tokens de bot;
- **IV aleatório de 12 bytes** para cada criptografia;
- derivação da chave AES a partir do segredo do ambiente por **SHA-256**;
- **SHA-256** para armazenar somente o hash das API Keys `bbk_`;
- geração de API Key com **32 bytes aleatórios**;
- validação do token diretamente no endpoint `/users/@me` da Discord API antes do cadastro.

## 2. Fluxo de cadastro

```text
Usuário
   │
   │ token do próprio bot
   ▼
POST /v2/bots/cadastrar
   │
   ▼
Discord API /users/@me
   │
   ├─ token inválido → cadastro rejeitado
   ├─ token não pertence a bot → cadastro rejeitado
   │
   └─ token válido
         │
         ▼
   geração da bbk_...
         │
         ├─ SHA-256 da API Key → banco
         │
         ▼
   AES-GCM do token
         │
         ├─ ciphertext → banco
         └─ IV aleatório → banco
```

O token em texto puro existe transitoriamente durante a requisição porque precisa ser recebido, validado e criptografado. A implementação não o grava em uma coluna de token em texto puro.

## 3. Implementação real de criptografia

Trecho correspondente à implementação em `src/services/bots.js`:

```javascript
async function sha256Bytes(value) {
  return new Uint8Array(
    await crypto.subtle.digest("SHA-256", enc.encode(value))
  );
}

async function aesKey(masterKey) {
  if (!masterKey) {
    throw Object.assign(
      new Error("master_key_not_configured"),
      { status: 503 }
    );
  }

  const raw = await sha256Bytes(masterKey);

  return crypto.subtle.importKey(
    "raw",
    raw,
    "AES-GCM",
    false,
    ["encrypt", "decrypt"]
  );
}

export async function encryptToken(token, masterKey) {
  const iv = crypto.getRandomValues(new Uint8Array(12));
  const key = await aesKey(masterKey);

  const cipher = new Uint8Array(
    await crypto.subtle.encrypt(
      { name: "AES-GCM", iv },
      key,
      enc.encode(token)
    )
  );

  return {
    cipher: b64urlEncode(cipher),
    iv: b64urlEncode(iv)
  };
}
```

O IV é gerado novamente a cada chamada de `encryptToken`.

O retorno do Web Crypto para AES-GCM inclui os dados autenticados necessários para que alterações indevidas no ciphertext façam a descriptografia falhar.

## 4. Descriptografia controlada

A descriptografia ocorre apenas quando uma operação autenticada precisa utilizar o token para uma chamada ao Discord.

Trecho real simplificado:

```javascript
export async function decryptToken(cipher, iv, masterKey) {
  const key = await aesKey(masterKey);

  const plain = await crypto.subtle.decrypt(
    { name: "AES-GCM", iv: b64urlDecode(iv) },
    key,
    b64urlDecode(cipher)
  );

  return dec.decode(plain);
}
```

A função de autenticação somente adiciona o token ao contexto interno quando `withToken` é solicitado pela rota que realmente precisa falar com o Discord.

Não existe endpoint público destinado a devolver o token original ao usuário.

## 5. Proteção da API Key

A API Key do bot é gerada com 32 bytes aleatórios:

```javascript
export function generateBotApiKey() {
  return "bbk_" +
    b64urlEncode(
      crypto.getRandomValues(new Uint8Array(32))
    );
}
```

Antes de persistir a credencial:

```javascript
export async function hashSecret(value) {
  const bytes = await sha256Bytes(value);

  return [...bytes]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
```

O banco armazena o SHA-256 da `bbk_`, não a chave original.

Quando uma requisição apresenta `X-API-Key`, a chave recebida é novamente submetida a SHA-256 e o hash é utilizado para localizar o bot.

## 6. Schema real do banco

A tabela de bots atualmente utiliza:

```sql
CREATE TABLE IF NOT EXISTS bots (
  id TEXT PRIMARY KEY,
  label TEXT,
  discord_user_id TEXT NOT NULL UNIQUE,
  discord_username TEXT,
  token_cipher TEXT NOT NULL,
  token_iv TEXT NOT NULL,
  api_key_hash TEXT NOT NULL UNIQUE,
  enabled INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

Pontos verificáveis:

- não existe coluna `token` em texto puro;
- o token persistido está em `token_cipher`;
- o IV está em `token_iv`;
- a API Key persistida está em `api_key_hash`.

## 7. Autenticação da API Key

A autenticação executa o hash da chave apresentada e consulta o registro pelo hash:

```javascript
const supplied = readApiKey(request);

if (!supplied?.startsWith("bbk_")) {
  return {
    ok: false,
    status: 401,
    error: "unauthorized"
  };
}

const apiKeyHash = await hashSecret(supplied);

const row = await env.DB.prepare(
  `SELECT id,label,discord_user_id,discord_username,
          token_cipher,token_iv,enabled,created_at,updated_at
     FROM bots
    WHERE api_key_hash=? AND enabled=1
    LIMIT 1`
).bind(apiKeyHash).first();
```

Isso permite autenticar sem armazenar a `bbk_` original.

## 8. Teste criptográfico reproduzível

O repositório inclui:

`scripts/security-selftest.mjs`

Ele utiliza somente valores fictícios e importa as mesmas funções utilizadas pela aplicação.

O teste verifica:

1. que um token fictício pode ser criptografado e descriptografado corretamente;
2. que duas criptografias do mesmo texto geram IVs diferentes;
3. que duas criptografias do mesmo texto geram ciphertexts diferentes;
4. que adulterar o ciphertext faz a autenticação AES-GCM rejeitar a mensagem;
5. que o hash da API Key possui o formato de SHA-256 em hexadecimal;
6. que o plaintext não aparece literalmente dentro do ciphertext codificado.

Execute:

```bash
node scripts/security-selftest.mjs
```

Resultado esperado:

```json
{
  "roundTripA": true,
  "roundTripB": true,
  "uniqueIV": true,
  "uniqueCiphertext": true,
  "tamperRejected": true,
  "apiKeyHashHexLength": 64,
  "apiKeyHashLooksSha256": true,
  "plaintextAppearsInCiphertext": false
}
```

Esse teste não acessa nenhum token real e não lê nenhuma credencial de produção.

## 9. Evidência executada em 18/09/2026

O teste foi executado contra a implementação atual e retornou:

```text
roundTripA:                    true
roundTripB:                    true
uniqueIV:                      true
uniqueCiphertext:              true
tamperRejected:                true
apiKeyHashHexLength:           64
apiKeyHashLooksSha256:         true
plaintextAppearsInCiphertext:  false
```

Os valores utilizados eram inteiramente sintéticos.

## 10. Impressões digitais dos arquivos auditados

Na data desta verificação:

```text
src/services/bots.js
SHA-256:
3D23735F7E8055E64CE40242D81B586123F4A549CDDCDCF704D4EF1D0D341A3A

schema.sql
SHA-256:
BCA3C8E43D8EDEDE44ADA8CFDE75BBC8F634BAAF6102DD0D0B615E25817196DD
```

Esses hashes permitem verificar se os arquivos analisados foram alterados depois desta comprovação.

Se qualquer um desses arquivos for modificado, uma nova revisão deve gerar novas impressões digitais.

## 11. O que esta comprovação demonstra

Ela demonstra que, na versão analisada:

- a função de criptografia realmente utiliza AES-GCM;
- o IV é gerado com aleatoriedade criptográfica e possui 12 bytes;
- a API Key é gerada com aleatoriedade criptográfica;
- a API Key é persistida por hash SHA-256;
- o schema não possui coluna de token em texto puro;
- adulteração do ciphertext é rejeitada no teste;
- o código consegue recuperar corretamente um token quando possui a chave criptográfica correta.

## 12. O que esta comprovação NÃO demonstra

Este documento não prova que a infraestrutura é “impenetrável”.

Ele também não substitui:

- pentest independente;
- auditoria completa de autorização;
- revisão de dependências;
- auditoria da conta de infraestrutura;
- proteção da conta do mantenedor;
- análise de logs;
- threat modeling contínuo;
- resposta a incidentes.

Criptografia de armazenamento reduz o impacto de determinados tipos de vazamento, mas não protege um token caso um invasor obtenha simultaneamente o ciphertext e acesso ao segredo de descriptografia ou comprometa o processo em execução.

## 13. Separação do segredo criptográfico

A chave utilizada para proteger os tokens é fornecida ao Worker como segredo do ambiente de execução.

Ela não faz parte do schema `bots` e não é gravada junto aos registros criptografados.

O valor desse segredo não deve ser:

- publicado;
- colocado no README;
- colocado no código-fonte;
- colocado em screenshots;
- enviado pela própria API;
- armazenado junto com dumps do banco.

Remover a única cópia existente desse segredo não aumenta a segurança dos tokens já criptografados: torna esses tokens irrecuperáveis.

Rotação da chave deve ser feita de forma planejada, com recriptografia dos registros existentes quando houver bots cadastrados.

## 14. Estado atual da auditoria

Até a data deste documento, esta comprovação é uma **verificação técnica interna e reproduzível**.

Ela não deve ser descrita como “auditoria independente”, “certificação”, “pentest aprovado” ou “segurança garantida” sem que esse trabalho tenha sido efetivamente realizado por terceiro qualificado.

## 15. Reporte de vulnerabilidades

Pesquisadores que identificarem problemas devem evitar publicar tokens, credenciais, dados de terceiros ou uma exploração ativa.

Contato:

**Discord: @_.viniciuscapolar**

Um bom relatório inclui endpoint, comportamento esperado, comportamento observado, impacto e uma prova de conceito utilizando somente dados próprios.
