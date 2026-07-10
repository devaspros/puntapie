#!/bin/bash
set -eo pipefail

# Opens the deploy step logs (deployments/logs/NNN_*.log) in lnav, merged
# into a single chronological timeline instead of tailing each file
# separately. Excludes 100_cron.log on purpose (backup jobs have their own
# monitoring).

LOG_DIR="${LOG_DIR:-/home/ubuntu/puntapie/deployments/logs}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORMAT_SRC="$SCRIPT_DIR/lnav/puntapie_deploy_log.json"
FORMAT_DEST_DIR="$HOME/.lnav/formats/installed"
FORMAT_DEST="$FORMAT_DEST_DIR/puntapie_deploy_log.json"

if ! command -v lnav >/dev/null 2>&1; then
  echo "lnav no está instalado. Instálalo con: sudo apt install lnav" >&2
  exit 1
fi

if [ ! -d "$LOG_DIR" ]; then
  echo "No existe el directorio de logs: $LOG_DIR" >&2
  exit 1
fi

mkdir -p "$FORMAT_DEST_DIR"
if [ ! -e "$FORMAT_DEST" ] || [ "$(readlink "$FORMAT_DEST" 2>/dev/null)" != "$FORMAT_SRC" ]; then
  ln -sf "$FORMAT_SRC" "$FORMAT_DEST"
fi

logs=()
while IFS= read -r f; do
  logs+=("$f")
done < <(find "$LOG_DIR" -maxdepth 1 -name '*.log' ! -name '100_cron.log' | sort)

if [ "${#logs[@]}" -eq 0 ]; then
  echo "No se encontraron logs de deploy en: $LOG_DIR" >&2
  exit 1
fi

exec lnav "${logs[@]}" "$@"
