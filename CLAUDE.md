# tryhackme

Writeups e ferramentas de rooms do TryHackMe. Cada room fica na sua pasta em `room/<nome>/`, com um `README.md` a documentar a resolução passo a passo e um `tools/` com scripts prontos a correr. Ferramentas/payloads que servem para qualquer room (não específicos de uma instância) ficam em `tools-general/`.

## Estrutura

```
room/<nome>/
├── README.md          # writeup: recon, vulnerabilidade, exploração, flag
├── investigacao.md    # documento de investigação (ver METODOLOGIA.md)
└── tools/
    ├── .env.example    # template do IP do alvo (copiar para .env)
    ├── .env            # IP real da instância — git-ignored, muda a cada run da room
    ├── requirements.txt
    ├── recon.sh         # corre todos os steps de recon em sequência
    ├── steps/
    │   ├── _common.sh   # carrega TARGET_IP do .env; é "sourced", não corre diretamente
    │   ├── 1_*.sh       # nmap
    │   ├── 2_*.sh       # enumeração web (ffuf/gobuster)
    │   └── 3_*.sh       # exploit
    └── *-exploit.py     # exploit(s) usado(s) na room

tools-general/           # ferramentas/payloads reutilizáveis entre rooms (ver tools-general/README.md)
└── upload-bypass/       # payloads para testar upload de ficheiros (test.txt, phpinfo.phtml, shell.phtml)
```

## Metodologia

Antes de testar qualquer room ou projeto novo, seguir sempre [METODOLOGIA.md](METODOLOGIA.md): nmap → visualização/curl → documento de investigação → directory enumeration → API/endpoints, atualizando o documento de investigação a cada descoberta.

## Convenções

- Todo script de step lê o IP do alvo via `_common.sh` (a partir de `tools/.env`), com fallback para argumento posicional — nunca hardcode IP.
- `.env` nunca é commitado (está no `.gitignore`); só `.env.example` fica no repo.
- Dependências Python instalam-se numa venv local em `tools/.venv` (evita `externally-managed-environment` no macOS/Homebrew).
- READMEs em português, com secções numeradas (Recon → Enumeração → Vulnerabilidade → Exploração → Flag → Lições).

## Rooms existentes

- **agentt** ([room/agentt/README.md](room/agentt/README.md)) — PHP 8.1.0-dev backdoor RCE via header `User-Agentt` (Exploit-DB #49933).

## Ao adicionar uma nova room

1. Seguir a [METODOLOGIA.md](METODOLOGIA.md) e ir preenchendo `room/<nome>/investigacao.md` à medida que se descobre coisas.
2. Criar `room/<nome>/README.md` seguindo o mesmo formato do agentt.
3. Criar `room/<nome>/tools/` com `.env.example`, `steps/_common.sh` (copiar/adaptar) e os scripts de cada etapa.
4. Nunca commitar `.env` nem IPs reais fora do `.env`.
