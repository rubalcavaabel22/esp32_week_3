#!/bin/bash
set -e
cat > esp32.log <<'EOF'
[INFO] Boot
[DATA] Temp: 26.7 C
[DATA] Hum: 45 %
[ERROR] WiFi fail
[DATA] Temp: 27.0 C
[INFO] Done
EOF

grep "DATA" esp32.log | awk -F'[: ]+' '
/Temp/ {printf "Temperatura,%.1f\n", $(NF-1)}
/Hum/  {printf "Humedad,%d\n", $(NF-1)}
' > datos.csv

echo "Generado datos.csv:"
cat datos.csv
