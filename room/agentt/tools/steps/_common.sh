#!/usr/bin/env bash
# Carrega o TARGET_IP do .env (ou aceita override por argumento).
# É "sourced" pelos scripts de step, não é para correr diretamente.

STEPS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(dirname "$STEPS_DIR")"

if [ -f "$TOOLS_DIR/.env" ]; then
    set -a
    source "$TOOLS_DIR/.env"
    set +a
fi

TARGET="${1:-${TARGET_IP:-}}"

if [ -z "$TARGET" ]; then
    echo "Nenhum IP definido. Cria $TOOLS_DIR/.env (copia de .env.example) ou passa o IP como argumento."
    echo "Uso: $0 [IP_ALVO]"
    exit 1
fi
