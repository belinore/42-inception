# Inception Project Context

This file captures the current state, design choices, and remaining work for the 42 Inception project.

## Current Status

The core Docker stack is working locally:

```text
browser -> nginx:443/TLS -> wordpress:9000/php-fpm -> mariadb:3306
```

The main remaining work is:

- create the required root documentation files
- move/test the project on the Linux VM
- switch local macOS data paths to the required VM paths
- run a final clean validation before submission

The VM step is important because it also solves the final required data directory location:

```text
/home/belinore/data
```

## Project Folders

Real project:

```text
/Users/beth/in_progress/inception
```

Learning sandbox:

```text
/Users/beth/in_progress/inception-test
```

The sandbox was used to understand the full flow with official images:

```text
browser -> nginx -> WordPress -> MariaDB
```

Do not treat `inception-test` as the final project.

## Current Real Project Structure

```text
Makefile
PROJECT_CONTEXT.md
.gitignore
README.md              (still needed)
USER_DOC.md            (still needed)
DEV_DOC.md             (still needed)
secrets/
  .gitignore
  MARIADB_PASSWORD      (local only, ignored)
  MARIADB_ROOT_PASSWORD (local only, ignored)
  WP_ADMIN_PASSWORD     (local only, ignored)
  WP_USER_PASSWORD      (local only, ignored)
  SSL_CERTIFICATE       (local only, ignored)
  TLS_PRIVATE_KEY       (local only, ignored)
srcs/
  docker-compose.yml
  .env
  requirements/
    mariadb/
      Dockerfile
      .dockerignore
      conf/50-server.cnf
      tools/init.sh
    nginx/
      Dockerfile
      .dockerignore
      conf/default.conf
    wordpress/
      Dockerfile
      .dockerignore
      conf/www.conf
      conf/wp-config.php        (manual reference only; not used by current image)
      tools/init.sh
    tools/site/index.html       (old static nginx test page; not used by final compose)
```

Generated local runtime data:

```text
data/
  mariadb/
  wordpress/
```

`data/`, `tmp/`, and `.DS_Store` are ignored by root `.gitignore`.

`secrets/.gitignore` ignores all files in `secrets/` except `.gitignore` itself:

```gitignore
*
!.gitignore
```

## Current Architecture

The root `srcs/docker-compose.yml` is the main integration file.

It defines:

- `mariadb`
- `wordpress`
- `nginx`
- named volumes:
  - `mariadb_data`
  - `wordpress_data`
- explicit Docker network:
  - `inception`
- Compose secrets for database, WordPress, and TLS credentials

Current root Compose behavior:

- nginx is the only public entrypoint.
- nginx publishes `443:443`.
- nginx mounts `wordpress_data` read-only at `/var/www/html`.
- WordPress mounts `wordpress_data` read-write at `/var/www/html`.
- MariaDB mounts `mariadb_data` at `/var/lib/mysql`.
- all services use `restart: on-failure`.
- all services use image names matching service names: `nginx`, `wordpress`, `mariadb`.

Current named volume paths are hardcoded for local macOS testing:

```yaml
device: /Users/beth/in_progress/inception/data/mariadb
device: /Users/beth/in_progress/inception/data/wordpress
```

The final 42 VM paths are left as comments in `srcs/docker-compose.yml`:

```yaml
# device: /home/belinore/data/mariadb
# device: /home/belinore/data/wordpress
```

Before final VM submission, switch the active `device:` values to `/home/belinore/data/...`.

## Root Makefile

The root `Makefile` wraps the main compose file:

- `make up`
- `make down`
- `make build`
- `make ps`
- `make logs`
- `make clean`
- `make fclean`
- `make cert`

Current local macOS setting:

```make
DATA_DIR = /Users/beth/in_progress/inception/data
```

Final 42 VM setting is commented above it:

```make
# DATA_DIR = /home/belinore/data
```

Before final VM submission, switch `DATA_DIR` to `/home/belinore/data`.

`make fclean` removes Compose volumes and local runtime data:

```make
docker compose -f srcs/docker-compose.yml down -v
rm -rf $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress
```

`make cert` creates local self-signed TLS files in `secrets/` if they do not already exist.

## Environment And Secrets

`srcs/.env` now contains non-secret configuration:

```env
MARIADB_DATABASE=inception_db
MARIADB_USER=belinore_db
DOMAIN_NAME=belinore.42.fr
WP_TITLE=Inception
WP_ADMIN_USER=belinore_wp
WP_ADMIN_EMAIL=belinore@student.42lisboa.com
WP_USER=blogger123
WP_USER_EMAIL=blogger123@student.42lisboa.com
```

Passwords and TLS material are stored as local ignored secret files:

```text
secrets/MARIADB_ROOT_PASSWORD
secrets/MARIADB_PASSWORD
secrets/WP_ADMIN_PASSWORD
secrets/WP_USER_PASSWORD
secrets/SSL_CERTIFICATE
secrets/TLS_PRIVATE_KEY
```

Compose exposes these inside containers under `/run/secrets/...` using lowercase secret names, for example:

```text
/run/secrets/mariadb_password
/run/secrets/wp_admin_password
/run/secrets/ssl_certificate
/run/secrets/tls_private_key
```

This keeps real passwords out of `.env`, Dockerfiles, and git.

## MariaDB State

`srcs/requirements/mariadb/Dockerfile`:

- uses `debian:bookworm`
- installs `mariadb-server`
- removes package cache and `/var/lib/mysql/*`
- copies `conf/50-server.cnf`
- copies `tools/init.sh`
- makes the init script executable
- exposes `3306`
- runs `CMD ["init.sh"]`

`srcs/requirements/mariadb/conf/50-server.cnf`:

```ini
[mysqld]
user = mysql
pid-file = /run/mysqld/mysqld.pid
socket = /run/mysqld/mysqld.sock
port = 3306
datadir = /var/lib/mysql
bind-address = 0.0.0.0
```

`bind-address = 0.0.0.0` allows WordPress to connect over the Docker network.

`srcs/requirements/mariadb/tools/init.sh`:

- reads root and WordPress database passwords from Docker secrets
- creates `/run/mysqld`
- fixes ownership for `/run/mysqld` and `/var/lib/mysql`
- checks whether `/var/lib/mysql/mysql` exists
- if empty, runs `mariadb-install-db`
- starts a temporary local MariaDB server with `--skip-networking`
- waits for `mariadb-admin ping`
- sets the root password
- deletes anonymous users
- drops the default `test` database
- creates `${MARIADB_DATABASE}`
- creates `${MARIADB_USER}` for both `%` and `localhost`
- grants privileges on `${MARIADB_DATABASE}`
- shuts down the temporary server
- finally runs `exec mariadbd --user=mysql --datadir=/var/lib/mysql`

MariaDB has been validated with:

```sql
SELECT CURRENT_USER(), VERSION(), DATABASE();
SHOW TABLES;
SHOW GRANTS FOR CURRENT_USER();
```

Expected result:

- the configured database user can connect
- `inception_db` exists
- grants include all privileges on `inception_db.*`

## WordPress State

`srcs/requirements/wordpress/Dockerfile`:

- uses `debian:bookworm`
- installs PHP-FPM, PHP extensions, MariaDB client, curl, ca-certificates, and tar
- downloads WordPress from `https://wordpress.org/latest.tar.gz`
- copies WordPress files to `/var/www/html`
- installs `wp-cli` as `/usr/local/bin/wp`
- copies `conf/www.conf`
- copies `tools/init.sh`
- exposes `9000`
- runs `CMD ["init.sh"]`

`srcs/requirements/wordpress/conf/www.conf` makes php-fpm listen on TCP:

```ini
listen = 0.0.0.0:9000
```

This allows nginx to use:

```nginx
fastcgi_pass wordpress:9000;
```

`srcs/requirements/wordpress/tools/init.sh`:

- reads database and WordPress passwords from Docker secrets
- creates `/run/php`
- fixes ownership for `/run/php` and `/var/www/html`
- waits until MariaDB accepts connections
- creates `wp-config.php` with `wp config create` if missing
- installs WordPress with `wp core install` if not already installed
- creates a second WordPress user with role `author`
- fixes ownership again
- finally runs `exec php-fpm8.2 -F`

Using `wp-cli` is acceptable for the subject because it is only a setup tool. The long-running WordPress process is still `php-fpm`, and the container is still a custom Debian-based WordPress/php-fpm image.

`srcs/requirements/wordpress/conf/wp-config.php` is a manual reference file for learning/comparison. It is not copied by the current Dockerfile. It now reads the DB password from the Docker secret path:

```php
define( 'DB_PASSWORD', trim( file_get_contents( '/run/secrets/mariadb_password' ) ) );
```

If this reference config is ever used as the live config, replace the placeholder WordPress salts with real random salts.

## nginx State

`srcs/requirements/nginx/Dockerfile`:

- uses `debian:bookworm`
- installs `nginx` and `openssl`
- changes global nginx SSL protocols to TLSv1.2/TLSv1.3
- copies `conf/default.conf`
- exposes `443`
- runs `CMD ["nginx", "-g", "daemon off;"]`

TLS certificate and private key files are not generated inside the image. They are provided at runtime through Docker secrets:

```text
/run/secrets/ssl_certificate
/run/secrets/tls_private_key
```

`srcs/requirements/nginx/conf/default.conf`:

- listens on `443 ssl`
- uses `server_name belinore.42.fr`
- uses TLS secrets for the certificate and private key
- allows only TLSv1.2 and TLSv1.3
- uses `/var/www/html` as the document root
- forwards PHP requests to `wordpress:9000`
- denies dotfiles

nginx has been validated with:

```sh
curl -k -I --resolve belinore.42.fr:443:127.0.0.1 https://belinore.42.fr
```

Expected result:

```text
HTTP/1.1 200 OK
```

The loaded nginx config showed:

```text
ssl_protocols TLSv1.2 TLSv1.3;
listen 443 ssl;
ssl_certificate /run/secrets/ssl_certificate;
ssl_certificate_key /run/secrets/tls_private_key;
fastcgi_pass wordpress:9000;
```

For final browser access, `/etc/hosts` must point the domain to the local machine or VM:

```text
127.0.0.1 belinore.42.fr
```

On the final VM, use the VM/local IP if different.

Expected final URL:

```text
https://belinore.42.fr
```

Browser certificate warnings are expected because the certificate is self-signed.

## Removed Test Helpers

Temporary service-level test Compose files and Makefiles were removed:

```text
srcs/requirements/mariadb/docker-compose.test.yml
srcs/requirements/mariadb/Makefile
srcs/requirements/wordpress/docker-compose.test.yml
srcs/requirements/wordpress/Makefile
srcs/requirements/nginx/docker-compose.test.yml
srcs/requirements/nginx/Makefile
```

The final/main compose file is:

```text
srcs/docker-compose.yml
```

## Current Validation Status

Completed checks:

- MariaDB user can connect and has grants on the project database.
- WordPress image builds and starts php-fpm.
- WordPress `wp-cli` setup creates `wp-config.php`, installs WordPress, and creates two WordPress users.
- nginx image builds from Debian, not from the ready-made nginx image.
- nginx serves WordPress through TLS and php-fpm.
- root `docker compose -f srcs/docker-compose.yml config` succeeds.
- MariaDB and WordPress init scripts pass shell syntax checks.
- edited reference `wp-config.php` passes PHP syntax check.
- root `.gitignore` ignores generated local `data/`, `tmp/`, and `.DS_Store`.

## Subject Requirements To Remember

- Use Docker Compose.
- A root Makefile is required.
- Files must be under `srcs/`.
- Each service has a dedicated container and Dockerfile.
- Each Docker image must have the same name as its corresponding service.
- Images must be built from the penultimate stable Debian or Alpine.
- Do not use ready-made service images except Debian/Alpine bases.
- Do not use the `latest` tag.
- Required services:
  - nginx with TLSv1.2 or TLSv1.3 only
  - WordPress + php-fpm only, with no nginx or Apache
  - MariaDB only, with no nginx
- nginx must be the only public entrypoint via port `443`.
- Required named volumes:
  - WordPress database
  - WordPress website files
- Named volumes must store data under `/home/<login>/data`.
- A Docker network must connect the containers.
- The `networks:` line must be present in `docker-compose.yml`.
- Containers must restart on crash.
- `network: host`, `--link`, and `links:` are forbidden.
- Avoid infinite-loop hacks such as:
  - `tail -f`
  - `sleep infinity`
  - `while true`
- Also avoid using `bash` or any command/entrypoint script as a fake forever process.
- Containers should run their real foreground daemon as PID 1.
- In the WordPress database, there must be two users, one of them being the administrator.
- The WordPress administrator username must not contain `admin`, `Admin`, `administrator`, or `Administrator`.
- Use `.env`.
- Environment variables are mandatory.
- No passwords in Dockerfiles.
- Docker secrets are strongly recommended.
- Any credentials, API keys, or passwords committed outside properly configured secrets cause project failure.
- Domain must be `belinore.42.fr`.
- The domain must point to the local IP address.

## Remaining Work

The core services are essentially done locally. Remaining submission work:

- Create root `README.md`.
- Create root `USER_DOC.md`.
- Create root `DEV_DOC.md`.
- Move or test the project on the Linux VM.
- On the VM, switch active volume host paths to:
  - `/home/belinore/data/mariadb`
  - `/home/belinore/data/wordpress`
- On the VM, switch the root Makefile `DATA_DIR` to:
  - `/home/belinore/data`
- Recreate local ignored secret files in `secrets/` on the VM.
- Confirm `/etc/hosts` maps `belinore.42.fr` to the VM/local IP.
- Run a final clean build on the target Linux VM.
- Re-check that only nginx publishes a host port and that the published port is `443`.
- Re-check that no generated runtime data, passwords, certificates, private keys, or `.DS_Store` files are staged.

## Required Documentation

The subject requires three Markdown documentation files at the repository root:

- `README.md`
- `USER_DOC.md`
- `DEV_DOC.md`

`README.md` must be written in English.

The first line of `README.md` must be italicized and read exactly:

```md
*This project has been created as part of the 42 curriculum by belinore.*
```

`README.md` must include at least:

- a `Description` section explaining the project goal and overview
- an `Instructions` section for compilation, installation, and/or execution
- a `Resources` section with classic references and a description of how AI was used
- a project description that explains Docker and the sources included in the project
- main design choices
- comparisons between:
  - Virtual Machines vs Docker
  - Secrets vs Environment Variables
  - Docker Network vs Host Network
  - Docker Volumes vs Bind Mounts

`USER_DOC.md` must explain, in clear and simple terms, how an end user or administrator can:

- understand what services are provided by the stack
- start and stop the project
- access the website and administration panel
- locate and manage credentials
- check that the services are running correctly

`DEV_DOC.md` must explain how a developer can:

- set up the environment from scratch, including prerequisites, config files, and secrets
- build and launch the project using the Makefile and Docker Compose
- use relevant commands to manage containers and volumes
- identify where project data is stored and how it persists

## Learning Notes

- A Dockerfile defines how an image is built.
- Compose defines runtime wiring: services, networks, volumes, environment files, secrets, and ports.
- A Makefile is a command menu around Compose.
- Named volumes survive container removal.
- `docker compose down` removes containers and networks but keeps volumes.
- `docker compose down -v` removes volumes too.
- nginx is a TLS entrypoint and FastCGI client in this project.
- WordPress runs behind nginx through php-fpm, usually with `fastcgi_pass wordpress:9000`.
- MariaDB must listen on the Docker network, so `bind-address = 0.0.0.0` matters.
- `wp-cli` is a setup tool; it does not replace WordPress or php-fpm.
- Generated runtime files belong in the Docker volume, not in git.

## Recommended Next Step

Create the required documentation files:

```text
README.md
USER_DOC.md
DEV_DOC.md
```

After that, move to the Linux VM and do the final path, hosts, secrets, and clean-build validation.
