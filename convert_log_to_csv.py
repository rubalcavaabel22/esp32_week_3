#!/usr/bin/env python3
import re, csv, sys

if len(sys.argv) < 3:
    print("Uso: convert_log_to_csv.py IN.log OUT.csv")
    sys.exit(1)

IN, OUT = sys.argv[1], sys.argv[2]
pat = re.compile(r'RAW:\s*([0-9.]+)\s+FILT:\s*([0-9.]+)\s+.*?t\s*\(us\):\s*([0-9.]+)', re.I)

with open(IN, 'r', encoding='utf-8', errors='ignore') as f, \
     open(OUT, 'w', newline='') as g:
    w = csv.writer(g)
    w.writerow(['raw','med','dt_med_us'])  # nombres que entiende el script
    for line in f:
        m = pat.search(line)
        if m:
            w.writerow([m.group(1), m.group(2), m.group(3)])

print("OK ->", OUT)
