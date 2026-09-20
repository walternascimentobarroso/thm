# tools-general

Ferramentas e payloads reutilizáveis em qualquer room, ao contrário de `room/<nome>/tools/`, que é específico de uma room (lê `.env` com o IP daquela instância).

## Estrutura

```
tools-general/
└── upload-bypass/       # payloads para testar upload de ficheiros (ver METODOLOGIA.md, Etapa 2 item 9)
    ├── test.txt          # ficheiro inofensivo — confirma se há validação nenhuma
    ├── phpinfo.phtml     # confirma execução de PHP sem dar RCE (phpinfo())
    └── shell.phtml       # web shell (?cmd=) — usar só depois de confirmar execução com phpinfo.phtml
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
