#!/usr/bin/env bash
# Passo 2 — ffuf: enumeração de diretórios/ficheiros do site.
# Uso: ./2_ffuf.sh            -> usa TARGET_IP do .env
#      ./2_ffuf.sh <IP_ALVO>  -> ignora o .env

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/_common.sh" "$@"

echo "=========================================="
echo " Passo 2 — Enumeração de diretórios (ffuf)"
echo "=========================================="
echo "Alvo: $TARGET"
echo "Comando: ffuf -u http://$TARGET/FUZZ -w /usr/share/wordlists/dirb/common.txt -e .php,.html,.txt -fc 200 -t 50"
echo "Objetivo: procurar diretórios/ficheiros escondidos no site."
echo "Nota: nesta room isto costuma não encontrar nada de novo (tudo devolve 200)."
echo "      A falha real está na versão do PHP identificada no Passo 1, não no conteúdo do site."
echo

ffuf -u "http://$TARGET/FUZZ" -w /usr/share/wordlists/dirb/common.txt -e .php,.html,.txt -fc 200 -t 50 || true
