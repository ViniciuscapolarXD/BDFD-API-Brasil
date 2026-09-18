# Termos de Serviço — BDFD API Brasil

**Versão:** 1.0  
**Vigência:** 18 de setembro de 2026

Estes Termos de Serviço regulam o uso da **BDFD API Brasil**, incluindo seus endpoints públicos, recursos de autenticação, armazenamento de dados, DevKit, Multi-API, integrações com a Discord API e demais funcionalidades disponibilizadas pelo serviço.

Ao cadastrar um bot, gerar uma API Key ou utilizar qualquer endpoint autenticado da BDFD API Brasil, você declara que leu e aceita estes Termos.

## 1. Natureza do serviço

A BDFD API Brasil é uma API independente voltada a desenvolvedores que utilizam Bot Designer For Discord e outras aplicações compatíveis com HTTP.

O serviço não é produto oficial, afiliado ou endossado pelo Discord, pelo Bot Designer For Discord ou por terceiros cujas APIs possam ser acessadas por meio dos recursos oferecidos.

Recursos atualmente disponibilizados podem incluir, entre outros:

- variáveis persistentes e temporárias;
- leaderboards;
- cooldowns;
- travas distribuídas;
- DevKit para manipulação de JSON, texto, listas, hashes, UUIDs e Snowflakes;
- pipelines de processamento seguro;
- chamadas Multi-API;
- integração indireta com recursos da Discord API.

A disponibilidade de uma funcionalidade não implica garantia de permanência, compatibilidade futura ou disponibilidade ininterrupta.

## 2. Cadastro de bots e prova de controle

O endpoint `POST /v2/bots/cadastrar` exige um token válido de bot do Discord para confirmar que o solicitante possui controle sobre aquele bot.

O token enviado é validado diretamente contra a Discord API. O serviço não deve ser utilizado para cadastrar bots que você não controla ou para testar, validar ou explorar credenciais de terceiros.

Ao utilizar o endpoint de cadastro, você declara que possui autorização legítima para utilizar o token informado.

## 3. API Key

Após o cadastro, o serviço gera uma API Key própria do bot, normalmente iniciada por `bbk_`.

A API Key:

- identifica o bot perante a BDFD API Brasil;
- deve ser mantida em segredo;
- não deve ser publicada em snippets, mensagens, repositórios públicos ou comandos acessíveis por terceiros;
- pode ser invalidada e substituída quando o bot for recuperado ou recadastrado.

O usuário é responsável por proteger sua API Key e por qualquer uso realizado com uma chave válida enquanto ela permanecer ativa.

Se houver suspeita de exposição, a credencial deve ser substituída imediatamente.

## 4. Tratamento do token do Discord

O token de bot precisa ser recuperável pelo serviço porque é utilizado para autenticar chamadas autorizadas à Discord API em nome do próprio bot.

Por esse motivo, o token não pode ser armazenado somente como hash irreversível.

A implementação atual:

- valida o token antes do armazenamento;
- utiliza criptografia autenticada AES-GCM;
- utiliza IV aleatório de 12 bytes para cada operação de criptografia;
- armazena no banco apenas o conteúdo criptografado e o IV correspondente;
- mantém a chave criptográfica separada dos registros do banco;
- não oferece endpoint público para leitura do token original.

A API Key `bbk_`, por outro lado, não precisa ser recuperada pelo servidor e, portanto, é armazenada somente por meio de hash SHA-256.

A documentação técnica e a comprovação reproduzível desses controles estão descritas em [SECURITY.md](./SECURITY.md).

## 5. Dados processados

Para operar o serviço, a BDFD API Brasil pode processar dados como:

- ID do bot no Discord;
- nome público do bot;
- rótulo informado pelo desenvolvedor;
- token do bot em forma criptografada;
- hash da API Key;
- variáveis e valores armazenados pelo usuário;
- pontuações de leaderboards;
- cooldowns;
- locks;
- IDs de usuários, servidores, canais ou outros identificadores necessários às funções utilizadas;
- metadados técnicos indispensáveis à execução, diagnóstico, segurança e prevenção de abuso.

O usuário não deve armazenar na API senhas, tokens de terceiros, dados financeiros, documentos pessoais, informações médicas ou outros dados sensíveis que não sejam estritamente necessários para a finalidade do bot.

## 6. Responsabilidade sobre dados e comandos

O desenvolvedor é responsável pelos dados que envia à API e pelo comportamento dos comandos, automações e sistemas construídos sobre ela.

A BDFD API Brasil não concede permissões adicionais dentro do Discord. Toda operação realizada por meio da Discord API continua sujeita às permissões, intents, limites e políticas do próprio Discord.

O usuário deve garantir que seu bot possua consentimento e base legítima para processar os dados que utilizar.

## 7. Uso permitido

O serviço pode ser utilizado para desenvolver bots, sistemas de comunidade, ferramentas administrativas, automações, rankings, armazenamento de estado e integrações legítimas compatíveis com a finalidade técnica da API.

É permitido criar aplicações comerciais ou não comerciais utilizando os endpoints públicos, desde que estes Termos e eventuais limites técnicos sejam respeitados.

## 8. Uso proibido

É proibido utilizar a BDFD API Brasil para:

- roubar, validar, coletar ou testar tokens de terceiros;
- tentar acessar dados de outro bot;
- contornar autenticação, permissões ou isolamento entre bots;
- realizar spam, fraude, phishing, malware ou abuso de plataforma;
- atacar, sobrecarregar ou degradar deliberadamente a infraestrutura;
- contornar limites de uso ou mecanismos antiabuso;
- utilizar o Multi-API para acessar hosts privados, metadados de infraestrutura ou recursos internos;
- explorar falhas de segurança contra usuários ou terceiros;
- violar os Termos do Discord, políticas de desenvolvedor do Discord ou leis aplicáveis;
- utilizar a API para facilitar atividade ilícita.

Testes de segurança de boa-fé devem ser limitados ao próprio bot e aos próprios dados do pesquisador. Vulnerabilidades encontradas devem ser reportadas de forma privada.

## 9. Multi-API e serviços de terceiros

O recurso Multi-API permite que uma requisição à BDFD API Brasil execute chamadas permitidas a serviços externos.

O usuário é responsável por:

- possuir autorização para acessar a API externa;
- respeitar os termos e limites do serviço de destino;
- não enviar credenciais a destinos não confiáveis;
- verificar a resposta antes de utilizá-la em ações sensíveis.

A BDFD API Brasil não controla a disponibilidade, segurança, conteúdo ou políticas de APIs externas.

## 10. Limites, uso justo e proteção contra abuso

A API pode impor limites por requisição, bot, IP, recurso ou período para preservar disponibilidade e segurança.

Esses limites podem ser alterados conforme a capacidade do serviço, comportamento de abuso ou requisitos de provedores externos.

Tentar burlar limites por meio de múltiplas chaves, bots, endereços ou outras técnicas pode resultar em bloqueio.

## 11. Suspensão e encerramento

O acesso de um bot pode ser suspenso ou encerrado quando houver evidência razoável de:

- comprometimento de credenciais;
- violação destes Termos;
- abuso de recursos;
- risco à segurança de terceiros;
- tentativa de exploração;
- exigência legal ou de plataforma externa.

Quando tecnicamente e juridicamente possível, incidentes serão analisados antes de uma medida permanente.

## 12. Disponibilidade e alterações

A API é fornecida de acordo com a capacidade técnica disponível.

Não há garantia de uptime absoluto, latência específica ou ausência completa de falhas.

Endpoints, limites e formatos podem ser corrigidos ou alterados. Mudanças incompatíveis relevantes devem, sempre que possível, ser documentadas e versionadas.

## 13. Segurança

Nenhum serviço conectado à internet pode ser considerado absolutamente invulnerável.

A BDFD API Brasil não promete “segurança impenetrável”. O compromisso é implementar controles verificáveis, reduzir a exposição de credenciais, corrigir vulnerabilidades identificadas e documentar honestamente o modelo de segurança.

A existência de criptografia não elimina riscos como:

- comprometimento do ambiente de execução;
- vazamento de uma credencial pelo próprio usuário;
- dependências vulneráveis;
- falhas de autorização;
- engenharia social;
- comprometimento da conta do Discord.

## 14. Reporte responsável de vulnerabilidades

Falhas de segurança não devem ser publicadas antes de haver oportunidade razoável para correção.

Relatos devem conter, quando possível:

- descrição do problema;
- endpoint afetado;
- passos para reprodução;
- impacto potencial;
- prova de conceito que utilize somente dados próprios.

Contato público para reporte: **Discord: @_.viniciuscapolar**

O envio de um relatório não cria obrigação de recompensa financeira.

## 15. Exclusão e correção de dados

Solicitações relacionadas à exclusão, correção ou revisão de dados associados a um bot podem ser feitas pelo contato oficial do projeto.

Antes de atender a uma solicitação sensível, poderá ser exigida prova razoável de controle do bot.

## 16. Propriedade intelectual

A BDFD API Brasil, sua documentação e seu código próprio permanecem sujeitos aos direitos de seus respectivos autores.

Discord, Bot Designer For Discord e demais marcas, APIs e serviços citados pertencem aos seus respectivos proprietários.

O uso da API não transfere ao usuário propriedade sobre o serviço, sua infraestrutura ou suas credenciais internas.

## 17. Isenção de garantias

O serviço é fornecido “como está” e “conforme disponível”, dentro dos limites permitidos pela legislação aplicável.

Não é garantido que a API atenderá a todas as necessidades de um projeto, permanecerá compatível com toda alteração de terceiros ou funcionará sem interrupções.

## 18. Limitação de responsabilidade

Na extensão permitida pela legislação aplicável, o responsável pelo serviço não responde por prejuízos indiretos decorrentes de:

- uso incorreto da API;
- exposição de credenciais pelo usuário;
- indisponibilidade de terceiros;
- mudanças na Discord API;
- exclusão ou corrupção causada por comandos do próprio usuário;
- integrações externas inseguras configuradas pelo desenvolvedor.

Nada nestes Termos exclui responsabilidades que não possam ser legalmente afastadas.

## 19. Alterações destes Termos

Os Termos podem ser atualizados para refletir novas funções, mudanças de segurança, requisitos legais ou alterações de plataforma.

A data de vigência e a versão devem ser atualizadas quando houver mudança material.

O uso continuado do serviço após uma alteração publicada representa aceitação da versão então vigente, quando permitido pela legislação aplicável.

## 20. Legislação aplicável

Estes Termos serão interpretados de acordo com a legislação brasileira aplicável, sem afastar direitos obrigatórios eventualmente existentes.

## 21. Contato

Dúvidas técnicas, pedidos relacionados a dados e relatos de segurança podem ser encaminhados pelo canal oficial do projeto:

**Discord: @_.viniciuscapolar**

---

Este documento é um modelo operacional para o projeto e não substitui revisão jurídica profissional caso a API passe a operar comercialmente, processe dados em escala relevante ou assuma obrigações contratuais específicas.
