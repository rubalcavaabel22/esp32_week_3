#!/bin/bash
set -euo pipefail

# ==============================
#  Script base Semana 3 (PIO)
#  build → upload → monitor
# ==============================

ENV="esp32s3-arduino"   # -e / --env
PORT="auto"             # -p / --port  (/dev/ttyACM0 | /dev/ttyUSB0 | auto)
BAUD="115200"           # -b / --baud
LOG="no"                # -l / --log   (yes|no)
CLEAN="no"              # -c / --clean (yes|no)
PROY="$PWD"             # -d / --dir   (ruta del proyecto)

usage() {
  cat <<EOF
Uso: $(basename "$0") [opciones]

Opciones:
  -e, --env   <entorno>   (default: $ENV)
  -p, --port  <puerto>    (/dev/ttyACM0 | /dev/ttyUSB0 | auto) (default: $PORT)
  -b, --baud  <velocidad> (default: $BAUD)
  -l, --log   <yes|no>    Guardar monitor a logs/ con timestamp (default: $LOG)
  -c, --clean <yes|no>    Limpiar antes de compilar (default: $CLEAN)
  -d, --dir   <ruta>      Ruta del proyecto PlatformIO (default: $PROY)
  -h, --help              Mostrar esta ayuda
Ejemplos:
  $(basename "$0") -e esp32s3-arduino -p auto -l yes
  $(basename "$0") --env esp32s3-idf --port /dev/ttyACM0 --clean yes
EOF
}

# ---- parseo simple de flags
while [[ "${1:-}" =~ ^- ]]; do
  case "$1" in
    -e|--env)   ENV="$2"; shift 2;;
    -p|--port)  PORT="$2"; shift 2;;
    -b|--baud)  BAUD="$2"; shift 2;;
    -l|--log)   LOG="$2"; shift 2;;
    -c|--clean) CLEAN="$2"; shift 2;;
    -d|--dir)   PROY="$2"; shift 2;;
    -h|--help)  usage; exit 0;;
    *) echo "Opción desconocida: $1"; usage; exit 1;;
  esac
done

# ---- cerrar monitores que bloqueen el puerto
pkill -9 -f "pio device monitor" 2>/dev/null || true
pkill -9 minicom 2>/dev/null || true

autodetect_port() {
  for c in /dev/ttyACM0 /dev/ttyUSB0 /dev/ttyACM* /dev/ttyUSB*; do
    [[ -e "$c" ]] && { echo "$c"; return 0; }
  done
  # by-id es más estable si existe
  local byid
  byid=$(ls -1 /dev/serial/by-id/* 2>/dev/null | head -n1 || true)
  [[ -n "${byid:-}" ]] && { echo "$byid"; return 0; }
  echo ""
}

if [[ "$PORT" == "auto" ]]; then
  DETECTED="$(autodetect_port)"
  if [[ -z "$DETECTED" ]]; then
    echo "❌ No se detectó ningún puerto (ACM/USB). Conecta la placa o indica --port manualmente."
    exit 1
  fi
  PORT="$DETECTED"
fi

echo "🔧 Proyecto : $PROY"
echo "🌱 Entorno  : $ENV"
echo "🔌 Puerto   : $PORT"
echo "⏱  Baud     : $BAUD"
echo "🧹 Clean    : $CLEAN"
echo "📝 Log      : $LOG"
echo "=============================="

# ---- limpiar si aplica
if [[ "$CLEAN" == "yes" ]]; then
  echo "🧼 Limpiando…"
  pio run -d "$PROY" -e "$ENV" -t clean
fi

# ---- compilar
echo "🔨 Compilando…"
pio run -d "$PROY" -e "$ENV"

# ---- flashear
echo "⚡ Flasheando…"
pio run -d "$PROY" -e "$ENV" -t upload --upload-port "$PORT"

# ---- monitor
echo "📟 Monitor…  (Ctrl+C para salir, Ctrl+T luego Ctrl+H para ayuda)"
if [[ "$LOG" == "yes" ]]; then
  mkdir -p "$PROY/logs"
  OUT="$PROY/logs/monitor_$(date +%F_%H-%M-%S).log"
  echo "📝 Guardando log en: $OUT"
  pio device monitor -p "$PORT" -b "$BAUD" | tee "$OUT"
else
  pio device monitor -p "$PORT" -b "$BAUD"
fi
