FROM php:7.1-fpm

RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y \
		git \
		libjpeg-dev \
		libpng12-dev \
		libxml2-dev \
	; \
	cd /root; \
	apt-get autoremove -y; \
	rm -rf /var/lib/apt/lists/*; \
	apt-get clean; \
	\
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
	docker-php-ext-install pdo pdo_mysql mbstring tokenizer xml gd mysqli opcache soap sockets shmop zip php-xdebug
	&& echo "zend_extension=/usr/lib/php/20160303/xdebug.so" > /etc/php/7.1/mods-available/xdebug.ini \
   	&& echo "xdebug.remote_enable=on" >> /etc/php/7.1/mods-available/xdebug.ini \
	&& echo "xdebug.remote_handler=dbgp" >> /etc/php/7.1/mods-available/xdebug.ini \
	&& echo "xdebug.remote_port=9001" >> /etc/php/7.1/mods-available/xdebug.ini \
	&& echo "xdebug.remote_autostart=on" >> /etc/php/7.1/mods-available/xdebug.ini \
	&& echo "xdebug.remote_connect_back=0" >> /etc/php/7.1/mods-available/xdebug.ini \
	&& echo "xdebug.idekey=docker" >> /etc/php/7.1/mods-available/xdebug.ini

COPY config/php.ini /usr/local/etc/php/php.ini
COPY docker-entrypoint.sh /docker-entrypoint.sh

ENTRYPOINT ["sh","/docker-entrypoint.sh"]
CMD ["php-fpm"]
