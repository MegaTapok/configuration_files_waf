#!/bin/bash
apt update && apt upgrade # Обнволение репозиториев и установленных пакетов
# Уставновка необходимых пакетов для работы ПК
apt install gcc make build-essential autoconf automake 
эlibtool libcurl4-openssl-dev liblua5.3-dev libfuzzy-dev ssdeep 
gettext pkg-config libgeoip-dev libyajl-dev doxygen libpcre++-dev 
libpcre2-16-0 libpcre2-dev libpcre2-posix3 libpcre2-dev 
zlib1g wget curl git yajl-devel zlib1g-dev -y
# Далее следующим шагом необходимо произвести конфигурацию и сборку модуля ModSecurity
cd /opt && sudo git clone https://github.com/owasp-modsecurity/ModSecurity.git
cd ModSecurity

git submodule init
git submodule update

./build.sh
./configure --with-json --with-yajl --with-pcre2

# Для ускорения сборки можно добавить параментр -j n, где n - количество ядер в вашей системе
make 
make install

# Скачивание коннектора
cd /opt && sudo git clone https://github.com/owasp-modsecurity/ModSecurity-nginx.git

apt install nginx -y
nginx_version=$(nginx -v 2>&1 | grep -oP 'nginx/\K[0-9.]+')

# Проверяем, что версия была получена
if [ -z "$nginx_version" ]; then
    echo "Ошибка: не удалось определить версию nginx"
    exit 1
fi

# Формируем URL и скачиваем
download_url="https://nginx.org/download/nginx-${nginx_version}.tar.gz"

cd /opt
wget "$download_url" || {
    echo "Ошибка при скачивании"
    exit 1
}

tar -xzvf nginx-${nginx_version}.tar.gz
cd nginx-${nginx_version}

# Конфигурация модуля для nginx
./configure --with-compat --add-dynamic-module=/opt/ModSecurity-nginx
make
make modules

# Копирование сформированного модуля и файлов необходимых для корректной работы 
cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules-enabled/
cp /opt/ModSecurity/unicode.mapping /etc/nginx/unicode.mapping
cd /etc/nginx/ && wget https://raw.githubusercontent.com/MegaTapok/configuration_files_waf/refs/heads/main/modsecurity.conf
wget https://raw.githubusercontent.com/MegaTapok/configuration_files_waf/refs/heads/main/nginx.conf
cd /sites-available && wget https://raw.githubusercontent.com/MegaTapok/configuration_files_waf/refs/heads/main/reverse_proxy.conf
ln -s /etc/nginx/sites-available/reverse_proxy.conf /etc/nginx/sites-enabled/

git clone https://github.com/coreruleset/coreruleset.git /etc/nginx/owasp-crs
cp /etc/nginx/owasp-crs/crs-setup.conf{.example,}

sudo service nginx restart
