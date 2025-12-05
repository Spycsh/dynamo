import pandas as pd
import matplotlib.pyplot as plt

# Your data
data = {
    "prefix_ratio": [0.1, 0.3, 0.5, 0.7, 0.9],
    # "TTFT_round_robin": [12374, 12485, 11602, 11996, 10211],
    # "TTFT_kv": [12992, 13343, 11305, 10978, 9749],
    # "Throughput_round_robin": [201, 202, 214, 210, 232],
    # "Throughput_kv": [190, 192, 218, 223, 236],
    "TTFT_round_robin": [9891, 9964, 9051, 8132, 7637],
    "TTFT_kv": [8967, 9631, 8025, 7165, 6856],
    "Throughput_round_robin": [233.4, 239.6, 253.0, 269.1, 280.3],
    "Throughput_kv": [236.8, 236.1, 264.6, 274.0, 271.1],

}

df = pd.DataFrame(data)

# --- Plot 1: TTFT ---
plt.figure(figsize=(8, 5))
plt.plot(df["prefix_ratio"], df["TTFT_round_robin"], marker='o', label="TTFT (ms) - Round Robin")
plt.plot(df["prefix_ratio"], df["TTFT_kv"], marker='s', label="TTFT (ms) - KV Router")
plt.xlabel("Prefix Ratio")
plt.ylabel("TTFT (ms)")
plt.title("Time To First Token vs Prefix Ratio")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("ttft_vs_prefix_ratio_4p4d.png", dpi=300)

# --- Plot 2: Throughput ---
plt.figure(figsize=(8, 5))
plt.plot(df["prefix_ratio"], df["Throughput_round_robin"], marker='o', label="Throughput (tokens/sec) - Round Robin")
plt.plot(df["prefix_ratio"], df["Throughput_kv"], marker='s', label="Throughput (tokens/sec) - KV Router")
plt.xlabel("Prefix Ratio")
plt.ylabel("Throughput (tokens/sec)")
plt.title("Throughput vs Prefix Ratio")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.savefig("throughput_vs_prefix_ratio_4p4d.png", dpi=300)

