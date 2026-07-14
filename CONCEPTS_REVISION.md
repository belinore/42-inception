# Inception Concepts Revision

## Defense Flow To Expect

The evaluator will clone the repository into an empty directory, inspect files, clean Docker, run `make`, then check the running stack.

Useful final-test commands on the VM:

```sh
docker compose -f srcs/docker-compose.yml config
make
docker compose -f srcs/docker-compose.yml ps
docker network ls
docker volume ls
docker volume inspect srcs_mariadb_data
docker volume inspect srcs_wordpress_data
curl -k -I https://belinore.42.fr
curl -I http://belinore.42.fr
```

Expected results:

- `https://belinore.42.fr` works.
- `http://belinore.42.fr` does not work.
- Only nginx publishes host port `443`.
- WordPress is installed; the installation page must not appear.
- WordPress admin username is `belinore_wp`, which does not contain `admin`.
- Docker volumes point to `/home/belinore/data/...`.
- Changes in WordPress survive container rebuilds and VM reboot.

## Docker

A Docker image is a read-only template built from a Dockerfile. It contains the filesystem, packages, copied config files, and default command for a service.

A Docker container is a running instance of an image. It has its own process space, filesystem layer, network interfaces, and mounted volumes, but it shares the host kernel.

Docker is lighter than a VM because containers do not boot a full guest operating system or kernel. A VM virtualizes hardware and runs a full OS. Docker isolates processes on the same host kernel.

In this project, each service has its own image and container:

- `nginx`: TLS entrypoint
- `wordpress`: WordPress with PHP-FPM only
- `mariadb`: database only

## Docker Compose

Docker Compose describes a multi-container application in one YAML file.

Without Compose, you would build images and run containers manually with separate `docker build`, `docker run`, network, volume, env, and secret commands.

With Compose, `docker compose up --build` builds images, creates containers, creates networks, mounts volumes, injects env vars/secrets, and starts everything together.

Each image name must match the service name in this project:

- service `nginx` uses image `nginx`
- service `wordpress` uses image `wordpress`
- service `mariadb` uses image `mariadb`

## Dockerfile Rules

Each service has its own Dockerfile. The images are built from Debian, not ready-made service images from Docker Hub.

Long-running processes must run in the foreground:

- nginx: `nginx -g "daemon off;"`
- WordPress: `php-fpm8.2 -F`
- MariaDB: `mariadbd`

Avoid forbidden hacks:

- no `tail -f`
- no `sleep infinity`
- no `while true`
- no `network: host`
- no `links:` or `--link`

## NGINX And TLS

nginx is the only public entrypoint. It listens on port `443` with TLS.

It serves static WordPress files from the WordPress volume and forwards PHP requests to:

```text
wordpress:9000
```

TLSv1.2/TLSv1.3 are configured in nginx. The certificate may be self-signed; the evaluator only needs to see that HTTPS is used and HTTP is not available.

## WordPress And PHP-FPM

WordPress runs without nginx in its container. PHP-FPM listens on port `9000` inside the Docker network.

The WordPress init script waits for MariaDB, creates `wp-config.php`, installs WordPress, creates the administrator user, creates a second user, then starts PHP-FPM in the foreground.

The admin username must not contain `admin` or `administrator`. This project uses:

```text
belinore_wp
```

## MariaDB

MariaDB stores the WordPress database.

The init script initializes `/var/lib/mysql` only if the database directory is empty. It creates:

- the WordPress database
- the database user
- grants for that user

To explain database login:

```sh
docker compose -f srcs/docker-compose.yml exec mariadb sh
mariadb -u belinore_db -p inception_db
```

Use the password from:

```text
secrets/MARIADB_PASSWORD
```

Then useful SQL:

```sql
SHOW DATABASES;
USE inception_db;
SHOW TABLES;
SELECT user_login, user_email FROM wp_users;
```

## Networks

The project uses a Docker bridge network named `inception`.

Containers can reach each other by service name:

- WordPress connects to `mariadb:3306`
- nginx connects to `wordpress:9000`

The database and PHP-FPM ports are internal to the Docker network. They are not published to the host.

Host networking is forbidden because it removes container network isolation and bypasses the Compose network model.

## Volumes And Persistence

The project uses named Docker volumes:

- `mariadb_data` mounted at `/var/lib/mysql`
- `wordpress_data` mounted at `/var/www/html`

The volume data is stored on the host under:

```text
/home/belinore/data/mariadb
/home/belinore/data/wordpress
```

This is why WordPress pages, comments, users, and database data survive container removal, rebuilds, and VM reboot.

Difference:

- Docker volume: managed by Docker and referenced by name.
- Bind mount: direct host path mounted into a container.

In this project, the Compose file defines named volumes with local driver options that store data under the required `/home/login/data` path.

## Environment Variables And Secrets

`.env` stores non-secret configuration:

- domain name
- database name
- usernames
- emails
- WordPress title

Secrets store sensitive values:

- database root password
- database user password
- WordPress admin password
- WordPress user password
- TLS certificate/key

Custom passwords must be created in `secrets/` before the first `make`. If the files do not exist, `setup.sh` auto-generates them.

Changing secret files after the database already exists may not update stored MariaDB or WordPress credentials. Use `make fclean_data` for a fresh install with new passwords.

## Make Targets

```text
make          setup + docker compose up --build
make down     stop/remove containers, keep volumes and data
make clean    same as down
make fclean   down -v, remove Compose volume objects, keep host data and secrets
make fclean_data
              remove Compose volumes, generated secrets, and /home/belinore/data
```

## Live Modification Practice

The evaluator may ask for a small config change. Be ready to edit one service config, rebuild, and restart.

Likely examples:

- Change nginx host port from `443:443` to another available host port, then access `https://belinore.42.fr:<port>`.
- Change nginx `server_name`.
- Change PHP-FPM listen port from `9000` to another port and update nginx `fastcgi_pass`.
- Change MariaDB port inside the Docker network and update WordPress `--dbhost`.

After a change:

```sh
make down
make
docker compose -f srcs/docker-compose.yml ps
```

Be able to explain exactly which files you changed and why both sides of a connection must match.

## Quick Explanation Scripts

Docker vs VM:

> A VM runs a full guest OS with its own kernel. Docker containers share the host kernel and isolate processes, filesystems, networking, and configuration. That makes containers lighter and faster for separating services.

Docker Compose:

> Compose is a declarative way to run a multi-container application. Instead of manually running each container, it builds images, creates the network, mounts volumes, injects environment variables and secrets, and starts all services together.

Docker network:

> The bridge network gives the containers a private network where they can resolve each other by service name. nginx can call `wordpress`, and WordPress can call `mariadb`, while only nginx is exposed to the host.

Volumes:

> Containers are disposable, but the database and website files must persist. Named volumes keep that data outside the container lifecycle and store it under `/home/belinore/data` as required.

Secrets vs env:

> `.env` is fine for non-sensitive settings. Passwords and TLS keys are secrets because they are sensitive and should not be stored directly in Compose, Dockerfiles, or git-tracked configuration.
