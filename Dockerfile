FROM php:5.6-fpm-alpine

RUN addgroup -g 10099 ibtech-www \
    && adduser -u 10099 -G ibtech-www -H -D -s /sbin/nologin ibtech-www \
    && apk add --update freetype-dev libjpeg-turbo-dev libmcrypt-dev libpng-dev libxml2-dev \
    && docker-php-ext-install iconv mcrypt \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install opcache \
    && docker-php-ext-install mbstring \
    && docker-php-ext-install gd \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install soap \
    && docker-php-ext-install sockets \
    && docker-php-ext-install shmop \
    && docker-php-ext-install zip \
    && rm -rf /var/cache/apk/*

COPY config/php.ini /usr/local/etc/php/php.ini
COPY config/php-fpm.conf /usr/local/etc/php-fpm.conf
