#!/usr/bin/env bash
# Directory enumeration por brute-force com gobuster (dir mode).
# Correr DEPOIS do content-discovery — para o que não está no robots.txt/sitemap.
# Uso: ./gobuster-dir.sh <URL_ou_IP> [wordlist] [extensoes]
#   ./gobuster-dir.sh 10.128.178.173
#   ./gobuster-dir.sh http://alvo.thm /usr/share/seclists/Discovery/Web-Content/common.txt
#   ./gobuster-dir.sh http://alvo.thm "" php,txt,html

set -uo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    echo "Uso: $0 <URL_ou_IP> [wordlist] [extensoes]"
    echo "  $0 10.128.178.173"
    echo "  $0 http://alvo.thm /caminho/wordlist.txt php,txt"
    exit 1
fi

if ! command -v gobuster >/dev/null 2>&1; then
    echo "gobuster não encontrado. Instalar: brew install gobuster (macOS) / apt install gobuster (Kali)"
    exit 1
fi

# Sem esquema -> assume http://
case "$TARGET" in
    http://*|https://*) BASE="$TARGET" ;;
    *) BASE="http://$TARGET" ;;
esac
BASE="${BASE%/}"

# Wordlist: argumento tem prioridade; senão procura nos caminhos convencionais.
WORDLIST="${2:-}"
if [ -z "$WORDLIST" ]; then
    for candidate in \
        /usr/share/seclists/Discovery/Web-Content/common.txt \
        /usr/share/wordlists/SecLists/Discovery/Web-Content/common.txt \
        /usr/share/wordlists/dirb/common.txt \
        /opt/homebrew/share/wordlists/SecLists/Discovery/Web-Content/common.txt; do
        if [ -f "$candidate" ]; then WORDLIST="$candidate"; break; fi
    done
fi
if [ -z "$WORDLIST" ] || [ ! -f "$WORDLIST" ]; then
    echo "Wordlist não encontrada. Passa uma como 2º argumento ou instala o SecLists."
    echo "  ex.: $0 $TARGET /usr/share/seclists/Discovery/Web-Content/common.txt"
    exit 1
fi

EXTENSIONS="${3:-php,txt,html}"

TS="$(date +%Y%m%d_%H%M%S)"
OUT="gobuster_${TS}.txt"

echo "=========================================="
echo " gobuster dir — $BASE"
echo " wordlist:   $WORDLIST"
echo " extensões:  $EXTENSIONS"
echo " output:     $OUT"
echo "=========================================="

gobuster dir \
    -u "$BASE" \
    -w "$WORDLIST" \
    -x "$EXTENSIONS" \
    -t 40 \
    -k \
    -o "$OUT"

echo
echo "Resultados gravados em $OUT. Cada rota [200/301/302] encontrada é uma pista —"
echo "testar no browser e registar no documento de investigação (Directory enumeration)."
