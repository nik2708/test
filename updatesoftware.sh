#!/bin/sh
# Быстрая проверка майнера

echo "=== Quick Miner Check ==="
echo "Time: $(date)"

# Ключевые индикаторы
FOUND=0

# 1. Проверка процессов майнеров
echo ""
echo "1. Checking miner processes..."
if ps aux 2>/dev/null | grep -v grep | grep -E 'xmrig|miner|cpuminer|xmr-stak|ccminer|49Wg2WsaZS1WA1s4USLNmxK1o5iBqw8aK6tButK4HLgK4XHn3xXGa247BNyLiE7ZzyHR17fotQJwqJF5Mi8Lz6B4L9JGKDE' >/dev/null; then
    echo "❌ FOUND: Miner processes detected!"
    ps aux 2>/dev/null | grep -v grep | grep -E 'xmrig|miner|cpuminer|xmr-stak|ccminer' | head -5
    FOUND=1
else
    echo "✅ No miner processes"
fi

# 2. Проверка популярных пулов
echo ""
echo "2. Checking mining pools..."
POOLS="moneroocean.stream minexmr.com supportxmr.com nanopool.org pool.hashvault.pro"
for pool in $POOLS; do
    if ps aux 2>/dev/null | grep -v grep | grep -i "$pool" >/dev/null; then
        echo "❌ FOUND: Process using pool: $pool"
        ps aux 2>/dev/null | grep -v grep | grep -i "$pool" | head -3
        FOUND=1
    fi
done

# 3. Проверка сетевых соединений
echo ""
echo "3. Checking network connections..."
if command -v ss >/dev/null 2>&1; then
    if ss -tnp 2>/dev/null | grep -E '10128|4444|7777|9999|14444' | grep -i 'moneroocean\|minexmr\|supportxmr' >/dev/null; then
        echo "❌ FOUND: Mining connections detected!"
        ss -tnp 2>/dev/null | grep -E '10128|4444|7777|9999|14444' | grep -i 'moneroocean\|minexmr\|supportxmr' | head -5
        FOUND=1
    fi
elif command -v netstat >/dev/null 2>&1; then
    if netstat -tnp 2>/dev/null | grep -E '10128|4444|7777|9999|14444' | grep -i 'moneroocean\|minexmr\|supportxmr' >/dev/null; then
        echo "❌ FOUND: Mining connections detected!"
        netstat -tnp 2>/dev/null | grep -E '10128|4444|7777|9999|14444' | grep -i 'moneroocean\|minexmr\|supportxmr' | head -5
        FOUND=1
    fi
fi

# 4. Проверка высокого использования CPU
echo ""
echo "4. Checking CPU usage..."
if ps aux 2>/dev/null | awk '$3 > 50.0 && !/grep/ {print $1":"$2":"$3":"$11}' | grep -v 'systemd\|kworker' | head -3; then
    echo "⚠️  High CPU usage detected (check if legitimate)"
else
    echo "✅ CPU usage normal"
fi

# Итог
echo ""
echo "=== RESULT ==="
if [ "$FOUND" -eq 1 ]; then
    echo "❌ MINING ACTIVITY DETECTED!"
    echo ""
    echo "Quick cleanup commands:"
    echo "  pkill -9 xmrig miner cpuminer xmr-stak"
    echo "  crontab -r"
    echo "  rm -rf /tmp/.systemd /dev/shm/.systemd"
    exit 1
else
    echo "✅ No mining activity detected"
    exit 0
fi
