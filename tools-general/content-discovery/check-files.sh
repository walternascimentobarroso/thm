#!/usr/bin/env bash
# Content discovery manual: verifica ficheiros que web servers expõem por convenção.
# Rápido e silencioso — correr antes do brute-force com ffuf/gobuster.
# Uso: ./check-files.sh <URL_ou_IP>
#   ./check-files.sh 10.128.178.173
#   ./check-files.sh http://alvo.thm
#   ./check-files.sh https://alvo.thm:8443

set -uo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    echo "Uso: $0 <URL_ou_IP>"
    echo "  $0 10.128.178.173"
    echo "  $0 http://alvo.thm"
    exit 1
fi

# Sem esquema -> assume http://
case "$TARGET" in
    http://*|https://*) BASE="$TARGET" ;;
    *) BASE="http://$TARGET" ;;
esac
BASE="${BASE%/}"

CURL=(curl -sk --max-time 10)

echo "=========================================="
echo " Content discovery — $BASE"
echo "=========================================="

echo
echo "== Headers (Server / X-Powered-By / tecnologia) =="
"${CURL[@]}" -D - -o /dev/null "$BASE/" \
    | grep -iE '^(server|x-powered-by|x-generator|x-aspnet-version|via|set-cookie):' \
    || echo "  (nenhum header revelador)"

# Ficheiros a inspecionar: status + tamanho. Os marcados dump=1 são impressos na íntegra.
check() {
    local path="$1" dump="${2:-0}" url="$BASE/$1"
    local out status size
    out="$("${CURL[@]}" -w '\n%{http_code} %{size_download}' "$url")" || { echo "  [ERRO] $path"; return; }
    read -r status size <<<"$(printf '%s' "$out" | tail -n1)"
    local body; body="$(printf '%s' "$out" | sed '$d')"

    if [ "$status" = "200" ] && [ "$size" != "0" ]; then
        echo "  [200] $path  (${size} bytes)  <-- existe"
        if [ "$dump" = "1" ]; then
            printf '%s\n' "$body" | sed 's/^/        | /'
        fi
    else
        echo "  [$status] $path"
    fi
}

echo
echo "== robots.txt / sitemap (conteúdo na íntegra) =="
check "robots.txt" 1
check "sitemap.xml" 1
check "sitemap_index.xml"

echo
echo "== Exposição de metadados / segredos =="
check ".well-known/security.txt" 1
check "humans.txt" 1
check ".git/HEAD" 1
check ".env"
check ".htaccess"
check ".DS_Store"

echo
echo "Nota: [200] com conteúdo = vale a pena investigar. Caminhos em robots.txt"
echo "      são pistas, não garantia — testar cada um diretamente no browser."
