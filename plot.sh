#!/usr/bin/env bash
set -euo pipefail

IN="${1:-logs/filters_compare.csv}"
OUT="logs/filters_clean.csv"

# 1) Quita líneas de banner/ayuda del monitor y deja solo líneas con números/comas
#    (asume que la primera columna es numérica)
TMP="$(mktemp)"
awk -F',' '$1 ~ /^[0-9]+(\.[0-9]+)?$/' "$IN" > "$TMP"

# 2) Si el archivo original Sí tenía cabecera en alguna parte, recorta desde ahí
if grep -q 'raw,avg,ema,med' "$IN"; then
  sed -n '/raw,avg,ema,med/,$p' "$IN" > "$OUT"
  # y nos aseguramos de que sólo queden filas numéricas debajo:
  awk -F',' 'NR==1 || $1 ~ /^[0-9]+(\.[0-9]+)?$/' "$OUT" > "$TMP"
fi

# 3) Inserta cabecera si no está en la primera línea
if ! head -n1 "$TMP" | grep -q 'raw,avg,ema,med'; then
  {
    echo "raw,avg,ema,med,dt_avg_us,dt_ema_us,dt_med_us"
    cat "$TMP"
  } > "$OUT"
else
  mv "$TMP" "$OUT"
fi

# 4) Llama al script de Python para graficar
python3 plot_filters.py "$OUT"

echo "Listo ✅  Gráficas guardadas. Revisa la carpeta actual (por defecto: values_over_time.png y timings_us.png)."
