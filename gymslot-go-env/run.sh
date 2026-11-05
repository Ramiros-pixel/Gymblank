#!/usr/bin/env bash
set -euo pipefail
ENV_NAME="${1:?usage: run.sh <dev|prod>}"
BASE="$(cd "$(dirname "$0")/.." && pwd)"
ENV_DIR="$BASE/gymslot-go-env/$ENV_NAME"
SRC="$BASE/gymslot-go"
BIN="$ENV_DIR/gymslot-$ENV_NAME"
if [ ! -f "$ENV_DIR/env" ]; then echo "missing $ENV_DIR/env"; exit 1; fi
set -a; . "$ENV_DIR/env"; set +a
echo "[build] $SRC -> $BIN"
(cd "$SRC" && go build -o "$BIN" .)
echo "[run] env=$ENV_NAME port=${GYMSLOT_PORT:-} db=${GYMSLOT_DB:-}"
exec "$BIN"
