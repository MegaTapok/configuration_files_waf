#!/bin/bash

# Пути к файлам
LOG_DIR="/var/log/nginx/modsec_logs/"
REPORT_FILE="/home/eugene/modsec_audit"
TEMP_FILE="/tmp/modsec_temp_$$"

# Проверка прав доступа
echo "Проверка доступа к лог-директории..." >&2
if [ ! -d "$LOG_DIR" ]; then
    echo "Ошибка: Директория $LOG_DIR не существует" | tee -a "$REPORT_FILE" >&2
    exit 1
fi

if [ ! -r "$LOG_DIR" ]; then
    echo "Ошибка: Нет прав на чтение директории $LOG_DIR" | tee -a "$REPORT_FILE" >&2
    exit 1
fi

# Поиск лог-файлов
echo "Поиск лог-файлов в $LOG_DIR..." >&2
LOG_FILES=$(find "$LOG_DIR" -type f -name '*.log*' 2>/dev/null)
if [ -z "$LOG_FILES" ]; then
    echo "Не найдено ни одного лог-файла в $LOG_DIR" | tee -a "$REPORT_FILE" >&2
    exit 1
fi

echo "Найдены лог-файлы: $LOG_FILES" >&2

# Создаём отчёт с диагностикой
{
    echo "Отчёт об атаках ModSecurity"
    echo "Сгенерирован: $(date)"
    echo "Директория логов: $LOG_DIR"
    echo "Анализируемые файлы: $LOG_FILES"
    echo "----------------------------------------"
    echo
    
    # Поиск атак с сохранением во временный файл для диагностики
    echo "Поиск записей об атаках..." >&2
    grep -h "ModSecurity: Access denied" $LOG_FILES > "$TEMP_FILE"
    
    if [ ! -s "$TEMP_FILE" ]; then
        echo "Не найдено записей об атаках в логах."
        echo "Последние 5 строк из логов для проверки формата:"
        tail -n 5 $(ls -1t $LOG_FILES | head -1)
    else
        echo "Найдено записей об атаках: $(wc -l < "$TEMP_FILE")" >&2
        
        # Анализ логов
        gawk '{
            # Извлекаем данные
            ip = uri = id = msg = "N/A"
            match($0, /\[client ([0-9.]+)\]/, m); if (m[1]) ip = m[1]
            match($0, /\[uri "([^"]+)"/, m); if (m[1]) uri = m[1]
            match($0, /\[id "([^"]+)"/, m); if (m[1]) id = m[1]
            match($0, /\[msg "([^"]+)"/, m); if (m[1]) msg = m[1]
            
            # Выводим информацию об атаке
            printf "IP: %-15s URI: %-40s\nПравило: %-8s Сообщение: %s\n\n", 
                   ip, uri, id, msg
        }' "$TEMP_FILE"
        
        echo "----------------------------------------"
        echo "Всего атак обнаружено: $(wc -l < "$TEMP_FILE")"
    fi
    
    # Удаляем временный файл
    rm -f "$TEMP_FILE"
} > "$REPORT_FILE"

# Права на файл
chown eugene:eugene "$REPORT_FILE"
chmod 644 "$REPORT_FILE"

echo "Отчёт создан: $REPORT_FILE" >&2
echo "Содержимое отчёта:" >&2
head -n 20 "$REPORT_FILE" >&2
