# content-discovery

Verifica os ficheiros que web servers expõem por convenção. É um passo de **Enumeration (Etapa 1)** — rápido, silencioso e muitas vezes entrega diretamente caminhos "escondidos" que os donos do site listam achando que ninguém vai lá.

Correr **antes** do brute-force com `ffuf`/`gobuster`: o que o `robots.txt`/`sitemap.xml` revelam poupa fuzzing e aponta logo para o que interessa.

## Uso

```bash
./check-files.sh 10.128.178.173        # sem esquema -> assume http://
./check-files.sh http://alvo.thm
./check-files.sh https://alvo.thm:8443
```

Não lê `.env` nem tem IP hardcoded — o alvo vem sempre por argumento (é uma ferramenta reutilizável entre rooms).

## O que verifica

| Ficheiro | Porque interessa |
|----------|------------------|
| Headers `Server` / `X-Powered-By` / `Set-Cookie` | Revela a stack (Apache/nginx/IIS, PHP/ASP.NET, framework) antes de qualquer scan. |
| `robots.txt` | Lista de `Disallow:` = diretórios que o dono não quer indexados (ex.: `/staff-portal`, `/admin`). É só uma guideline para bots — os caminhos continuam acessíveis diretamente. |
| `sitemap.xml` / `sitemap_index.xml` | Páginas que o dono quer indexadas — às vezes inclui páginas de staging, conteúdo antigo ou URLs difíceis de alcançar pela navegação normal. |
| `/.well-known/security.txt` | Contactos de segurança, por vezes escopo/domínios. |
| `humans.txt` | Nomes/emails da equipa — úteis para user enumeration e password spraying. |
| `.git/HEAD` | Se existir, o repositório-fonte pode estar exposto (`git-dumper` reconstrói o código). |
| `.env` | Credenciais/segredos da aplicação em texto simples. |
| `.htaccess` / `.DS_Store` | Config do Apache exposta / listagem de ficheiros de uma pasta (macOS). |

`[200]` com conteúdo = investigar. Os caminhos encontrados no `robots.txt` são **pistas, não garantia** — testar cada um diretamente no browser.

## A seguir

Depois disto, o brute-force de diretórios (`ffuf`/`gobuster`) para o que não está listado em lado nenhum. Ver [METODOLOGIA.md](../../METODOLOGIA.md), Etapa 1.

> Usar só em alvos autorizados (rooms de CTF/labs, bug bounty com escopo).
