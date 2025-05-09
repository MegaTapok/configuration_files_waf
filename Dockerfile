# Используем официальный образ Nginx
FROM nginx:latest

# Устанавливаем зависимости для ModSecurity и компиляции
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        gcc \
        g++ \
        flex \
        bison \
        libyajl-dev \
        liblua5.2-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        libpcre3-dev \
        libtool \
        autoconf \
        automake \
        make \
        pkg-config \
        wget \
        libgeoip-dev \
        libssl-dev \
        ca-certificates \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Устанавливаем ModSecurity v3 (как модуль Nginx)
WORKDIR /tmp
RUN git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity && \
    cd ModSecurity && \
    git submodule init && \
    git submodule update && \
    ./build.sh && \
    ./configure && \
    make && \
    make install && \
    rm -rf /tmp/ModSecurity

# Устанавливаем ModSecurity-nginx (коннектор для Nginx)
RUN git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
    wget http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -xvzf nginx-${NGINX_VERSION}.tar.gz && \
    cd nginx-${NGINX_VERSION} && \
    ./configure --with-compat --add-dynamic-module=../ModSecurity-nginx && \
    make modules && \
    cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/ && \
    rm -rf /tmp/*

# Загружаем OWASP Core Rule Set (CRS)
WORKDIR /etc/modsecurity.d
RUN git clone --depth 1 -b v3.3/master https://github.com/coreruleset/coreruleset.git && \
    mv coreruleset /etc/modsecurity.d/owasp-crs && \
    cd /etc/modsecurity.d/owasp-crs && \
    mv crs-setup.conf.example crs-setup.conf && \
    mv rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf && \
    mv rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf

# Копируем конфигурационные файлы
COPY modsecurity.conf /etc/modsecurity.d/modsecurity.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY main.conf /etc/modsecurity.d/main.conf

# Включаем ModSecurity в Nginx
RUN echo "load_module modules/ngx_http_modsecurity_module.so;" > /etc/nginx/load-modules.conf

# Опционально: Устанавливаем GeoIP (для блокировки по странам)
RUN apt-get update && \
    apt-get install -y libmaxminddb0 libmaxminddb-dev mmdb-bin && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 80 443
CMD ["nginx", "-g", "daemon off;"]