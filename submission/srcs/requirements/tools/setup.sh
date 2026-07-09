#!/bin/sh

set -eu

. ./srcs/.env

mkdir -p /home/$USER/data/mariadb /home/$USER/data/wordpress
sudo chown -R $USER:$USER /home/$USER/data

echo "Generating secrets..."

mkdir -p secrets

generate_secret() {
    [ -f "$1" ] || openssl rand -hex 32 > "$1"
}

generate_secret secrets/MARIADB_PASSWORD
generate_secret secrets/MARIADB_ROOT_PASSWORD
generate_secret secrets/WP_ADMIN_PASSWORD
generate_secret secrets/WP_USER_PASSWORD

echo "Generating SSL certificate..."

if [ ! -f secrets/TLS_PRIVATE_KEY ] || [ ! -f secrets/SSL_CERTIFICATE ]; then
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout secrets/TLS_PRIVATE_KEY \
        -out secrets/SSL_CERTIFICATE \
        -subj "/CN=$DOMAIN_NAME"
fi
