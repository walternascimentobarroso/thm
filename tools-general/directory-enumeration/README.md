# directory-enumeration

Descoberta de conteúdo por **brute-force** com [gobuster](https://github.com/OJ/gobuster). É a parte *automated* da Enumeration (**Etapa 1, item 7**): envia centenas/milhares de pedidos com uma wordlist para encontrar diretórios, ficheiros, subdomínios e vhosts que não estão listados em lado nenhum.

Correr **depois** do [content-discovery](../content-discovery/) (manual) — o que o `robots.txt`/`sitemap.xml` já revelam poupa fuzzing e aponta logo para o que interessa.

## Modos do gobuster

| Modo | Para quê | Precisa de |
|------|----------|------------|
| `dir` | Diretórios e ficheiros escondidos num web server | URL + wordlist |
| `dns` | Subdomínios de um domínio | domínio + wordlist de subdomínios |
| `vhost` | Virtual hosts servidos no mesmo IP (header `Host`) | URL + wordlist |

## dir mode (script)

```bash
./gobuster-dir.sh <URL_ou_IP> [wordlist] [extensoes]
./gobuster-dir.sh 10.128.178.173
./gobuster-dir.sh http://alvo.thm "" php,txt,html
./gobuster-dir.sh http://alvo.thm /usr/share/seclists/Discovery/Web-Content/common.txt
```

Não lê `.env` nem tem IP hardcoded — o alvo vem sempre por argumento (ferramenta reutilizável entre rooms). Grava o output em `gobuster_<timestamp>.txt`.

**Wordlist:** se não passares, o script procura o SecLists nos caminhos convencionais (`/usr/share/seclists/...`, `/usr/share/wordlists/SecLists/...`). No AttackBox/Kali já vem instalado. Para varreduras rápidas usa `Discovery/Web-Content/common.txt`; para cobertura maior, `directory-list-2.3-medium.txt`.

Flags úteis do `dir` (caso corras à mão): `-x .php,.txt` (extensões), `-r` (segue redirects), `-k` (ignora TLS), `-s 200,301` (só certos status), `-t` (threads), `--delay` (contra rate limiting).

## dns mode (subdomínios)

```bash
gobuster dns -d alvo.thm -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt -t 40
```

## vhost mode (virtual hosts)

```bash
gobuster vhost -u http://alvo.thm -w /usr/share/seclists/Discovery/DNS/subdomains-top1million-5000.txt --append-domain
```

Útil quando o nmap mostra um web server mas o site "real" só responde a um `Host:` específico (comum em CTF).

## A seguir

Cada rota `[200/301/302]`, subdomínio ou vhost encontrado é uma **pista, não garantia** — testar diretamente no browser e registar no `investigacao.md` (secção *Directory enumeration* / *API / Endpoints*). Ver [METODOLOGIA.md](../../METODOLOGIA.md), Etapa 1.

> Usar só em alvos autorizados (rooms de CTF/labs, bug bounty com escopo).
