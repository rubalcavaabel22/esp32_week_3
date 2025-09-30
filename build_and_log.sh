#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-esp32s3-arduino}"
PORT="${2:-/dev/ttyACM0}"
BAUD="${3:-115200}"

mkdir -p logs

# Compila y sube
pio run -e "$ENV" -t upload --upload-port "$PORT"

# Captura 10 s de datos (ajusta si quieres)
timeout 10s pio device monitor -p "$PORT" -b "$BAUD" \
  | tee "logs/filters_compare.csv" >/dev/null

# Limpia y grafica
./plot.sh logs/filters_compare.csv
