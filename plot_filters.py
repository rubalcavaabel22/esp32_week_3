#!/usr/bin/env python3
import argparse, sys, os
import pandas as pd
import matplotlib.pyplot as plt

def read_csv_smart(path: str):
    try:
        df = pd.read_csv(path)
    except Exception:
        df = pd.read_csv(path, header=None)
        df.columns = [f"col{i}" for i in range(1, len(df.columns)+1)]
    df.columns = [str(c).strip().lower() for c in df.columns]
    rename_map = {}
    variants = {
        "raw":["raw","adc","x","val","value"],
        "avg":["avg","mean","movingavg","movavg","avgfilter","avg_v"],
        "ema":["ema","exp","iir","emafilter","ema_v"],
        "med":["med","median","medianfilter","med_v"],
        "dt_avg_us":["dt_avg_us","dtavg","dt_avg","tavg","t_avg","avg_us"],
        "dt_ema_us":["dt_ema_us","dtema","dt_ema","tema","t_ema","ema_us"],
        "dt_med_us":["dt_med_us","dtmed","dt_med","tmed","t_med","med_us"],
    }
    for canon, names in variants.items():
        for c in df.columns:
            if c in names:
                rename_map[c] = canon; break
    if rename_map: df = df.rename(columns=rename_map)
    return df

def main():
    ap = argparse.ArgumentParser(description="Plot raw/avg/ema/med and timings from CSV")
    ap.add_argument("csv", nargs="?", default="logs/filters_compare.csv")
    ap.add_argument("--outdir","-o", default="plots")
    ap.add_argument("--maxpoints", type=int, default=0)
    args = ap.parse_args()

    if not os.path.exists(args.csv):
        print(f"ERROR: CSV not found: {args.csv}", file=sys.stderr); sys.exit(2)

    df = read_csv_smart(args.csv)
    value_cols  = [c for c in ["raw","avg","ema","med"] if c in df.columns]
    timing_cols = [c for c in ["dt_avg_us","dt_ema_us","dt_med_us"] if c in df.columns]
    if not value_cols:
        print("ERROR: No value columns (raw/avg/ema/med).", file=sys.stderr); sys.exit(3)

    if args.maxpoints>0: df = df.iloc[:args.maxpoints].copy()
    os.makedirs(args.outdir, exist_ok=True)

    # Valores
    plt.figure()
    x = range(len(df))
    for c in value_cols: plt.plot(x, df[c], label=c.upper())
    plt.xlabel("Sample"); plt.ylabel("Value"); plt.title("Signal vs Filters"); plt.legend()
    values_path = os.path.join(args.outdir,"values_over_time.png")
    plt.savefig(values_path, dpi=160, bbox_inches="tight")

    # Tiempos
    if timing_cols:
        plt.figure()
        for c in timing_cols: plt.plot(x, df[c], label=c)
        plt.xlabel("Sample"); plt.ylabel("Time (µs)"); plt.title("Per-call filter timings"); plt.legend()
        timings_path = os.path.join(args.outdir,"timings_us.png")
        plt.savefig(timings_path, dpi=160, bbox_inches="tight")

    print("Saved:", values_path)
    if timing_cols: print("Saved:", timings_path)

if __name__ == "__main__":
    main()
