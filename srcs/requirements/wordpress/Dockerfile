FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
	curl \
	ca-certificates \
	tar \
	mariadb-client \
	php8.2-cli \
	php8.2-fpm \
	php8.2-mysql \
	php8.2-curl \
	php8.2-gd \
	php8.2-mbstring \
	php8.2-xml \
	php8.2-zip \
	&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/www/html /run/php \
	&& curl -fsSL https://wordpress.org/latest.tar.gz -o /tmp/wordpress.tar.gz \
	&& tar -xzf /tmp/wordpress.tar.gz -C /tmp \
	&& cp -a /tmp/wordpress/. /var/www/html/ \
	&& chown -R www-data:www-data /var/www/html /run/php \
	&& rm -rf /tmp/wordpress /tmp/wordpress.tar.gz

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar -o /usr/local/bin/wp \
	&& chmod +x /usr/local/bin/wp

COPY conf/www.conf /etc/php/8.2/fpm/pool.d/www.conf
COPY tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh

WORKDIR /var/www/html

EXPOSE 9000

CMD ["init.sh"]
