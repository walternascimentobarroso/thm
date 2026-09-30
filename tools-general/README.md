# tools-general

Ferramentas e payloads reutilizáveis em qualquer room, ao contrário de `room/<nome>/tools/`, que é específico de uma room (lê `.env` com o IP daquela instância).

## Estrutura

```
tools-general/
├── content-discovery/       # verifica ficheiros convencionais do web server (ver METODOLOGIA.md, Etapa 1 item 6)
│   └── check-files.sh       # curl a robots.txt, sitemap.xml, .git, .env, headers, etc.
├── directory-enumeration/   # brute-force de diretórios/subdomínios/vhosts com gobuster (ver METODOLOGIA.md, Etapa 1 item 7)
│   └── gobuster-dir.sh      # gobuster dir mode com auto-deteção de wordlist; dns/vhost documentados no README
└── upload-bypass/           # payloads para testar upload de ficheiros (ver METODOLOGIA.md, Etapa 2 item 9)
    ├── test.txt          # ficheiro inofensivo — confirma se há validação nenhuma
    ├── phpinfo.phtml     # confirma execução de PHP sem dar RCE (phpinfo())
    └── shell.phtml       # web shell (?cmd=) — usar só depois de confirmar execução com phpinfo.phtml
```

## content-discovery

Ver [content-discovery/README.md](content-discovery/README.md). Correr no início da Enumeration (Etapa 1), antes do ffuf:

```bash
./content-discovery/check-files.sh <IP_ou_URL_ALVO>
```

## directory-enumeration

Ver [directory-enumeration/README.md](directory-enumeration/README.md). Correr **depois** do content-discovery — brute-force de diretórios/ficheiros (e subdomínios/vhosts) que não estão listados em lado nenhum:

```bash
./directory-enumeration/gobuster-dir.sh <IP_ou_URL_ALVO>
```

## upload-bypass

Uso típico (ver [METODOLOGIA.md](../METODOLOGIA.md) — Etapa 2 item 9 e Etapa 3):

1. Tentar upload de `test.txt` sem alterar nada — se for aceite, não há validação nenhuma.
2. Tentar `.php` puro — normalmente bloqueado por blocklist.
3. Tentar `phpinfo.phtml` (ou renomear para `.php5`, `.pht`, etc. conforme a stack) — se executar, confirma RCE sem já lançar comandos.
4. Confirmado que executa, subir `shell.phtml` e chamar:
   ```bash
   curl "http://<IP_ALVO>/<caminho_upload>/shell.phtml?cmd=whoami"
   ```
5. Dali, escalar para reverse shell (Etapa 3 do METODOLOGIA.md).

> Estes ficheiros só devem ser usados em alvos autorizados (rooms de CTF/labs). `shell.phtml` dá execução de comandos arbitrária no servidor.
