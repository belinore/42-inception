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

## Before Starting

The project expects the domain `belinore.42.fr` to point to the machine running Docker.

On the final VM, add an entry to `/etc/hosts` if needed:

```text
127.0.0.1 belinore.42.fr
```

If the website is accessed from another machine, use the VM IP instead of `127.0.0.1`.

The final data directory must exist under:

```text
/home/belinore/data
```

The project Makefile creates the required subdirectories:

```text
/home/belinore/data/mariadb
/home/belinore/data/wordpress
```

## Credentials

Passwords are stored in local secret files in the repository `secrets/` directory.

Required secret files:

```text
secrets/MARIADB_ROOT_PASSWORD
secrets/MARIADB_PASSWORD
secrets/WP_ADMIN_PASSWORD
secrets/WP_USER_PASSWORD
secrets/SSL_CERTIFICATE
secrets/TLS_PRIVATE_KEY
```

These files are intentionally ignored by git.

The non-secret service settings are stored in:

```text
srcs/.env
```

That file contains names, emails, the domain, and database names. It should not contain passwords.

To change a password, edit the matching file in `secrets/`.

For a new installation, update the secret files before running `make up`.

For an existing installation, changing a database or WordPress password may require recreating the stored data with:

```sh
make fclean
make up
```

`make fclean` deletes the configured persistent database and WordPress files, so use it only when a reset is intended.

## Starting The Project

From the repository root, run:

```sh
make up
```

This creates the data directories, builds the images, and starts the containers.

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

Use the WordPress administrator username from `srcs/.env` and the password from:

```text
secrets/WP_ADMIN_PASSWORD
```

## Stopping The Project

Stop the containers:

```sh
make down
```

This keeps the persistent WordPress files and database data.

To stop the project and delete the Docker volumes and local project data:

```sh
make fclean
```

Use `make fclean` carefully. It removes the stored database and WordPress files from the configured data directory.

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

If `/etc/hosts` is not configured yet, test the domain with curl by resolving it manually:

```sh
curl -k -I --resolve belinore.42.fr:443:127.0.0.1 https://belinore.42.fr
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
