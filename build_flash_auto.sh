#!/bin/bash
set -euo pipefail

# ==============================
#  build_flash_auto.sh
#  Detecta puerto + entorno (S3 o esp32dev)
#  build → upload → monitor (opcional log)
# ==============================

ENV="auto"              # -e / --env  (auto|esp32s3-arduino|esp32dev-arduino)
PORT="auto"             # -p / --port (/dev/ttyACM0|/dev/ttyUSB0|/dev/serial/by-id/...|auto)
BAUD="115200"           # -b / --baud
LOG="no"                # -l / --log  (yes|no)
CLEAN="no"              # -c / --clean (yes|no)
PROY="$PWD"             # -d / --dir

usage() {
  cat <<EOF
Uso: $(basename "$0") [opciones]

Opciones:
  -e, --env   <auto|esp32s3-arduino|esp32dev-arduino> (default: auto)
  -p, --port  <puerto>   (/dev/ttyACM0|/dev/ttyUSB0|/dev/serial/by-id/...|auto) (default: auto)
  -b, --baud  <vel>      (default: $BAUD)
  -l, --log   <yes|no>   Guardar salida del monitor (default: $LOG)
  -c, --clean <yes|no>   Limpiar antes de compilar (default: $CLEAN)
  -d, --dir   <ruta>     Ruta del proyecto (default: $PROY)
  -h, --help             Ayuda

Ejemplos:
  $(basename "$0") -e auto -p auto -l yes
  $(basename "$0") --env esp32dev-arduino --port /dev/ttyUSB0
EOF
}

# ----- parse flags
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

# ----- mata monitores que bloquean
pkill -9 -f "pio device monitor" 2>/dev/null || true
pkill -9 minicom 2>/dev/null || true

# ----- helpers de autodetección
first_byid() { ls -1 /dev/serial/by-id/* 2>/dev/null | head -n1 || true; }

detect_port() {
  # 1) by-id (estable y bonito)
  local byid
  byid="$(first_byid)"
  if [[ -n "${byid:-}" ]]; then
    echo "$byid"; return 0
  fi
  # 2) nodos comunes
  for c in /dev/ttyACM0 /dev/ttyUSB0 /dev/ttyACM* /dev/ttyUSB*; do
    [[ -e "$c" ]] && { echo "$c"; return 0; }
  done
  echo ""
}

detect_env_from_port() {
  local port="$1"
  # Heurística: ACM → S3; USB → DevKit (UART bridge)
  if [[ "$port" == *ttyACM* ]]; then
    echo "esp32s3-arduino"
  elif [[ "$port" == *ttyUSB* ]]; then
    echo "esp32dev-arduino"
  else
    # Intento con by-id: si menciona 'Espressif USB JTAG' asumimos S3
    if [[ "$port" == *"Espressif_USB_JTAG"* ]]; then
      echo "esp32s3-arduino"
    else
      # fallback
      echo "esp32dev-arduino"
    fi
  fi
}

# ----- puerto
if [[ "$PORT" == "auto" ]]; then
  PORT="$(detect_port)"
  [[ -z "$PORT" ]] && { echo "❌ No se detectó ningún puerto (ACM/USB). Conecta la placa o indica --port."; exit 1; }
fi

# ----- entorno
if [[ "$ENV" == "auto" ]]; then
  ENV="$(detect_env_from_port "$PORT")"
fi

echo "🔧 Proyecto : $PROY"
echo "🌱 Entorno  : $ENV"
echo "🔌 Puerto   : $PORT"
echo "⏱  Baud     : $BAUD"
echo "🧹 Clean    : $CLEAN"
echo "📝 Log      : $LOG"
echo "=============================="

# ----- limpiar si aplica
if [[ "$CLEAN" == "yes" ]]; then
  echo "🧼 Limpiando…"
  pio run -d "$PROY" -e "$ENV" -t clean
fi

# ----- compilar
echo "🔨 Compilando…"
pio run -d "$PROY" -e "$ENV"

# ----- flashear
echo "⚡ Flasheando…"
pio run -d "$PROY" -e "$ENV" -t upload --upload-port "$PORT"

# ----- monitor
echo "📟 Monitor…  (Ctrl+C para salir, Ctrl+T luego Ctrl+H para ayuda)"
if [[ "$LOG" == "yes" ]]; then
  mkdir -p "$PROY/logs"
  OUT="$PROY/logs/monitor_$(date +%F_%H-%M-%S).log"
  echo "📝 Guardando log en: $OUT"
  pio device monitor -p "$PORT" -b "$BAUD" | tee "$OUT"
else
  pio device monitor -p "$PORT" -b "$BAUD"
fi

