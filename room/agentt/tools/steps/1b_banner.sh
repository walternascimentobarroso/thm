#!/usr/bin/env bash
# Passo 1b — Banner HTTP: confirmar a versão do PHP quando o nmap não
# consegue (fica "http?" em vez do banner completo).
# Uso: ./1b_banner.sh            -> usa TARGET_IP do .env
#      ./1b_banner.sh <IP_ALVO>  -> ignora o .env

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh" "$@"

echo "=========================================="
echo " Passo 1b — Banner HTTP (curl)"
echo "=========================================="
echo "Alvo: $TARGET"
echo "Comando: curl -I --max-time 5 http://$TARGET"
echo "Objetivo: ler o header 'Server' devolvido pelo servidor web."
echo "Ficar atento a: 'PHP 8.1.0-dev Development Server', que indica a"
echo "                 versão vulnerável ao Exploit-DB #49933."
echo

if ! curl -I --max-time 5 "http://$TARGET"; then
    echo
    echo "HEAD não respondeu (ou demorou demais). Tentando com GET e verbose..."
    curl -v --max-time 5 "http://$TARGET" -o /dev/null
fi
