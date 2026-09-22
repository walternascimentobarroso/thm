#!/usr/bin/env bash
# Passo 1 — Nmap: descobrir portas abertas e versão dos serviços.
# Uso: ./1_nmap.sh            -> usa TARGET_IP do .env
#      ./1_nmap.sh <IP_ALVO>  -> ignora o .env

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh" "$@"

ROOM_DIR="$(dirname "$TOOLS_DIR")"
SCAN_DIR="$ROOM_DIR/scans"
mkdir -p "$SCAN_DIR"
OUTPUT_FILE="$SCAN_DIR/nmap.txt"

echo "=========================================="
echo " Passo 1 — Nmap (versões de serviço)"
echo "=========================================="
echo "Alvo: $TARGET"
echo "Comando: nmap -sCV -Pn -oN $OUTPUT_FILE $TARGET"
echo "Objetivo: descobrir as portas abertas e a versão dos serviços."
echo "Ficar atento a: banner do tipo 'PHP cli server ... (PHP 8.1.0-dev)',"
echo "                 que indica a versão vulnerável ao Exploit-DB #49933."
echo "Output salvo em: $OUTPUT_FILE (útil depois para o relatório/documento de investigação)."
echo

nmap -sCV -oN "$OUTPUT_FILE" "$TARGET"
