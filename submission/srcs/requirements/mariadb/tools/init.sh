#!/bin/sh
set -eu

MARIADB_ROOT_PASSWORD="$(cat /run/secrets/mariadb_root_password)"
MARIADB_PASSWORD="$(cat /run/secrets/mariadb_password)"
mkdir -p /run/mysqld
chown mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql

	mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking &
	pid="$!"

	until mariadb-admin ping --silent; do
		sleep 1
	done

	mariadb -u root <<-SQL
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';
		DELETE FROM mysql.user WHERE User='';
		DROP DATABASE IF EXISTS test;
		CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${MARIADB_PASSWORD}';
		CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'localhost' IDENTIFIED BY '${MARIADB_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
		GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'localhost';
		FLUSH PRIVILEGES;
	SQL

	mariadb-admin -u root -p"${MARIADB_ROOT_PASSWORD}" shutdown
	wait "$pid"
fi

exec mariadbd --user=mysql --datadir=/var/lib/mysql
