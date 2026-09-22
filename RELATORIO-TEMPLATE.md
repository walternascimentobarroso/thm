# Template de relatório final

Estrutura de referência para o relatório escrito no fim de um pentest/room, depois de preenchido o `room/<nome>/investigacao.md` (ver [METODOLOGIA.md](METODOLOGIA.md)). O relatório é o entregável para outra pessoa ler — organiza e resume o que já está na investigação, não repete o processo passo a passo do README de writeup.

Secções sempre presentes, e as marcadas (Opcional) só quando fizerem sentido para o público do relatório:

1. Capa
2. Índice (Opcional)
3. Sumário executivo
4. Sumário técnico (Opcional)
5. Tabela de vulnerabilidades (por severidade)
6. Secção detalhada de exploração (uma por vulnerabilidade)

---

## 1. Capa

- Título do relatório/engagement
- Nome do autor
- E-mail de contacto
- Controlo de versão (ex.: `v1.0 — 2026-09-20`, e um changelog se houver revisões)

## 2. Índice (Opcional)

Só em relatórios longos (múltiplas vulnerabilidades). Gerado a partir dos títulos das secções.

## 3. Sumário executivo

Público: gestor/cliente que pediu o engagement, sem contexto técnico. Explicar em linguagem não-técnica:
- O que foi testado.
- O que foi encontrado, em termos de impacto de negócio (ex.: "um atacante conseguiria assumir controlo total do servidor").
- Risco geral (ex.: crítico/alto/médio/baixo) e se recomenda ação imediata.

Sem nomes técnicos de vulnerabilidades, sem comandos, sem jargão.

## 4. Sumário técnico (Opcional)

Público: engineering manager — entende impacto técnico o suficiente para priorizar, mas não vai remediar diretamente. Um parágrafo ou lista curta por vulnerabilidade, com severidade, componente afetado e por que importa. Sem os passos de exploração (isso vai na secção 6).

## 5. Tabela de vulnerabilidades

Público: gestores e engenheiros, para priorizar o trabalho de remediação. Uma linha por vulnerabilidade, ordenada por severidade (Crítico → Alto → Médio → Baixo → Informativo).

| # | Título | Severidade | Componente afetado |
|---|--------|------------|---------------------|
| 1 |        |            |                     |

## 6. Secção detalhada de exploração

Público: engenheiros que vão corrigir. Uma subsecção por vulnerabilidade, na mesma ordem da tabela acima, com este formato:

```markdown
### <Título da vulnerabilidade>

**Severidade:** <Crítico/Alto/Médio/Baixo/Informativo>

**Descrição:** O que é a falha, onde foi encontrada, e por que representa risco.

**Passos de exploração:**
1. ...
2. ...
3. ...

**Recomendação:** Como corrigir — específico e acionável, não genérico.
```

### Exemplo preenchido

```markdown
### Palavra-passe de root guardada em texto simples

**Severidade:** Crítico

**Descrição:** A palavra-passe do utilizador root foi encontrada guardada em
texto simples no ficheiro /etc/password.txt. Este ficheiro era legível por
utilizadores com poucos privilégios, permitindo que qualquer utilizador com
acesso shell obtivesse as credenciais de root e comprometesse totalmente o
sistema.

**Passos de exploração:**
1. Obter uma shell com poucos privilégios no sistema alvo.
2. Ler o conteúdo de /etc/password.txt com `cat /etc/password.txt`.
3. Usar a palavra-passe de root encontrada para escalar privilégios via
   `ssh root@IP`.

**Recomendação:** Remover imediatamente o ficheiro de palavra-passe em texto
simples e rodar a palavra-passe de root. Credenciais nunca devem ser guardadas
em texto simples no sistema de ficheiros. Implementar uma solução de gestão
de segredos ou usar mecanismos de autenticação do sistema devidamente
configurados (como /etc/shadow com hashing forte). Adicionalmente, aplicar o
princípio do menor privilégio para restringir permissões de acesso a
ficheiros.
```

---

Fonte dos dados de cada secção: `room/<nome>/investigacao.md` já deve ter tudo (portas/serviços, testes de falhas, shell/RCE, escalada de privilégios) — o relatório é a tradução disso para um documento apresentável a terceiros.
