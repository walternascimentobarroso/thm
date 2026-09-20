#!/usr/bin/env bash
# Recon completo para a room Agent T — corre todos os steps em sequência.
# Cada step também pode ser corrido individualmente, veja steps/.
# Uso: ./recon.sh            -> usa TARGET_IP do .env
#      ./recon.sh <IP_ALVO>  -> ignora o .env e usa o IP passado

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"$SCRIPT_DIR/steps/1_nmap.sh" "$@"
echo
"$SCRIPT_DIR/steps/1b_banner.sh" "$@"
echo
"$SCRIPT_DIR/steps/2_ffuf.sh" "$@"

echo
echo "=========================================="
echo " Próximo passo"
echo "=========================================="
echo "Se o Nmap mostrou 'PHP cli server ... (PHP 8.1.0-dev)', o alvo é vulnerável"
echo "ao Exploit-DB #49933 (RCE via header User-Agentt)."
echo "Corra: ./steps/3_exploit.sh"
