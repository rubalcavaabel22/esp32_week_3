import sys, pandas as pd, matplotlib.pyplot as plt
import numpy as np

if len(sys.argv) < 2:
    print("Uso: plot_filters.py archivo.csv"); sys.exit(1)

csv = sys.argv[1]
# ignora líneas no numéricas
df = pd.read_csv(csv, comment='-', header=0, engine='python')

# normaliza nombres por si hay espacios
df.columns = [c.strip() for c in df.columns]

need = ["raw","avg","ema","med","dt_avg_us","dt_ema_us","dt_med_us"]
missing = [c for c in need if c not in df.columns]
if missing:
    print("ERROR: faltan columnas:", ", ".join(missing)); sys.exit(2)

df = df.replace([np.inf,-np.inf], np.nan).dropna()

# ---- values_over_time
plt.figure()
for c in ["raw","avg","ema","med"]:
    plt.plot(df.index, df[c], label=c)
plt.legend(); plt.xlabel("Sample"); plt.ylabel("Value")
plt.title("Filter outputs over time")
plt.tight_layout(); plt.savefig("plots/values_over_time.png"); plt.close()

# ---- timings_us
plt.figure()
for c in ["dt_avg_us","dt_ema_us","dt_med_us"]:
    plt.plot(df.index, df[c], label=c)
plt.legend(); plt.xlabel("Sample"); plt.ylabel("Time (µs)")
plt.title("Per-call filter timings")
plt.tight_layout(); plt.savefig("plots/timings_us.png"); plt.close()

print("OK: gráficos en plots/values_over_time.png y plots/timings_us.png")
