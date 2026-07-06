#!/bin/sh
set -eu

MARIADB_PASSWORD="$(cat /run/secrets/mariadb_password)"
WP_ADMIN_PASSWORD="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASSWORD="$(cat /run/secrets/wp_user_password)"
mkdir -p /run/php
chown -R www-data:www-data /run/php /var/www/html

until mariadb -h mariadb -u "$MARIADB_USER" -p"$MARIADB_PASSWORD" "$MARIADB_DATABASE" -e "SELECT 1;" >/dev/null 2>&1; do
	sleep 1
done

if [ ! -f /var/www/html/wp-config.php ]; then
	wp config create \
		--dbname="$MARIADB_DATABASE" \
		--dbuser="$MARIADB_USER" \
		--dbpass="$MARIADB_PASSWORD" \
		--dbhost="mariadb:3306" \
		--path=/var/www/html \
		--allow-root
fi

if ! wp core is-installed --path=/var/www/html --allow-root >/dev/null 2>&1; then
	wp core install \
		--url="https://$DOMAIN_NAME" \
		--title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--path=/var/www/html \
		--allow-root

	wp user create "$WP_USER" "$WP_USER_EMAIL" \
		--user_pass="$WP_USER_PASSWORD" \
		--role=author \
		--path=/var/www/html \
		--allow-root
fi

chown -R www-data:www-data /var/www/html

exec php-fpm8.2 -F
