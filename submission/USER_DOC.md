# User Documentation

## Overview

This project runs a small WordPress website using three Docker containers:

- `nginx`: receives browser traffic on HTTPS port `443`
- `wordpress`: runs WordPress with PHP-FPM
- `mariadb`: stores the WordPress database

Only nginx is exposed to the host machine. WordPress and MariaDB communicate through the private Docker network.

The expected public URL is:

```text
https://belinore.42.fr
```

The WordPress administration panel is:

```text
https://belinore.42.fr/wp-admin
```

Because the project uses a self-signed TLS certificate, the browser may show a security warning. This is expected for local and VM testing.

## Starting The Project

From the repository root, run:

```sh
make
```

This creates the data directories, generates secrets and SSL keys, builds the images, and starts the containers.

The stack provides these services after startup:

- the public WordPress website through nginx
- the WordPress administration panel
- a private MariaDB database used by WordPress

After startup, visit:

```text
https://belinore.42.fr
```

To access the WordPress dashboard, visit:

```text
https://belinore.42.fr/wp-admin
```

Use the WordPress username from `srcs/.env` and the password from:

```text
secrets/WP_ADMIN_PASSWORD (for administrator)
secrets/WP_USER_PASSWORD (for writer/user)
```

## Credentials

If you wish to choose your own credentials you should create them before running make to avoid them being auto-generated.

Create password secrets with `printf` so accidental newlines are not added:

```sh
mkdir -p secrets
printf '%s' 'choose_a_root_db_password' > secrets/MARIADB_ROOT_PASSWORD
printf '%s' 'choose_a_wp_db_password' > secrets/MARIADB_PASSWORD
printf '%s' 'choose_a_wp_admin_password' > secrets/WP_ADMIN_PASSWORD
printf '%s' 'choose_a_wp_author_password' > secrets/WP_USER_PASSWORD
```

## Stopping The Project

Stop the containers:

```sh
make down
```

This keeps the persistent WordPress files and database data.

To stop the project and delete the Docker volumes:

```sh
make fclean
```

To restart the project after stopping it:

```sh
make up
```

## Checking The Services

Show running containers:

```sh
make ps
```

Expected services:

```text
mariadb
wordpress
nginx
```

Only nginx should publish a host port:

```text
0.0.0.0:443->443/tcp
```

Check logs:

```sh
make logs
```

Check HTTPS with curl:

```sh
curl -k -I https://belinore.42.fr
```

Expected result:

```text
HTTP/1.1 200 OK
```

## Persistent Data

WordPress files are stored in:

```text
/home/belinore/data/wordpress
```

MariaDB data is stored in:

```text
/home/belinore/data/mariadb
```

Removing containers does not remove this data. The data is removed only when the volumes and local data directories are deleted.
