#!/usr/bin/env bash
# Passo 1 — Nmap: descobrir portas abertas e versão dos serviços.
# Uso: ./1_nmap.sh            -> usa TARGET_IP do .env
#      ./1_nmap.sh <IP_ALVO>  -> ignora o .env

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh" "$@"

echo "=========================================="
echo " Passo 1 — Nmap (versões de serviço)"
echo "=========================================="
echo "Alvo: $TARGET"
echo "Comando: nmap -sCV $TARGET"
echo "Objetivo: descobrir as portas abertas e a versão dos serviços."
echo "Ficar atento a: banner do tipo 'PHP cli server ... (PHP 8.1.0-dev)',"
echo "                 que indica a versão vulnerável ao Exploit-DB #49933."
echo

nmap -sCV "$TARGET"
