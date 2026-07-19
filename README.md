*This project has been created as part of the 42 curriculum by belinore.*

# Inception

## Description

Inception is a system administration project that builds a small production-style web stack with Docker Compose.

The goal is to run a WordPress website over HTTPS using three separate custom containers:

- `nginx`: the public TLS entrypoint
- `wordpress`: WordPress running with PHP-FPM
- `mariadb`: the database used by WordPress

The services are connected through a private Docker network. Only nginx exposes a host port, and it serves the site on port `443` with TLSv1.2/TLSv1.3.

The final website is available at:

```text
https://belinore.42.fr
```

## Project Description

The project uses Docker to package each service into a reproducible container image. Docker Compose is used to define how the containers are built, connected, configured, and persisted.

All source files are located under `srcs/`, as required by the subject:

```text
srcs/
  docker-compose.yml
  .env
  requirements/
    mariadb/
      Dockerfile
      conf/50-server.cnf
      tools/init.sh
    nginx/
      Dockerfile
      conf/default.conf
    tools/
      setup.sh
    wordpress/
      Dockerfile
      conf/www.conf
      tools/init.sh
```

The root `Makefile` is the main interface for building, starting, stopping, and cleaning the project.

Persistent data is stored on the host under:

```text
/home/belinore/data
```

The project creates two persistent storage areas:

- `/home/belinore/data/mariadb` for the database
- `/home/belinore/data/wordpress` for WordPress files

Passwords and TLS keys are provided through Docker secrets from local files in `secrets/`. These files are ignored by git.

## Design

Each service has its own container and Dockerfile. This keeps service responsibilities clear:

- nginx handles HTTPS and forwards PHP requests to WordPress
- WordPress runs PHP-FPM and owns the WordPress application files
- MariaDB stores the database and is reachable only inside the Docker network

The images are built from Debian and do not use ready-made nginx, WordPress, or MariaDB images.

The WordPress container uses `wp-cli` during startup to generate `wp-config.php`, install the site, and create the required users. `wp-cli` is only a setup tool; the long-running process is still PHP-FPM.

nginx uses Docker secrets for the TLS certificate and private key. MariaDB and WordPress also read passwords from Docker secrets rather than storing them in `.env`.

## Technical Comparisons

### Virtual Machines vs Docker

A virtual machine runs a full guest operating system with its own kernel. It is powerful and strongly isolated, but heavier to start, store, and manage.

Docker containers share the host kernel while isolating processes, filesystems, networks, and runtime configuration. Containers are lighter and faster to rebuild, which makes them well suited for separating services such as nginx, WordPress, and MariaDB.

In this project, the host VM provides the Linux environment, while Docker provides service-level isolation inside that VM.

### Secrets vs Environment Variables

Environment variables are convenient for non-sensitive configuration such as service names, usernames, database names, domains, and emails.

Secrets are better for passwords, private keys, and certificates because they are mounted as files at runtime and can be kept out of Dockerfiles, Compose variables, and git history.

This project uses `.env` for non-secret settings and `secrets/` files for passwords and TLS keys.

### Docker Network vs Host Network

With a Docker bridge network, containers can communicate by service name while remaining isolated from the host network. This lets WordPress connect to `mariadb:3306` and nginx connect to `wordpress:9000`.

Host networking would remove that isolation and expose more of the stack directly to the host.

This project uses a dedicated Docker network named `inception`.

### Docker Volumes vs Bind Mounts

Docker volumes provide managed persistent storage for container data. They survive container removal and are the standard Docker mechanism for durable service data.

Bind mounts map a specific host path directly into a container. They are useful for development, but they couple the container strongly to the host filesystem layout.

This project uses named Docker volumes configured to store their data under `/home/belinore/data`.

## Instructions

### Prerequisites

The final environment must provide:

- a Linux VM
- Docker
- Docker Compose
- `make`
- `openssl`

The domain `belinore.42.fr` must point to the VM or local machine. For local VM testing, `/etc/hosts` can contain:

```text
127.0.0.1 belinore.42.fr
```
Where IP matches that of localhost.

### Build And Start

From the repository root:

```sh
make
```

This creates the required data directories, generates secrets, builds the images, and starts the stack.

### Stop

```sh
make down
```

### Clean

```sh
make clean
```

### Full Clean

```sh
make fclean
```

This stops the stack, removes Compose volumes.

### FULL Full Clean

```sh
make fclean_data
```

This also deletes the local data directories.

### Check The Stack

Show containers:

```sh
make ps
```

Check HTTPS:

```sh
curl -k -I https://belinore.42.fr
```

Expected response:

```text
HTTP/1.1 200 OK
```

## Additional Documentation

More detailed documentation is available in:

- `USER_DOC.md`: user and administrator guide
- `DEV_DOC.md`: developer setup, architecture, and validation notes

## Resources

References used for this project:

- Docker documentation: https://docs.docker.com/
- nginx documentation: https://nginx.org/en/docs/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/
- WordPress developer documentation: https://developer.wordpress.org/
- PHP-FPM documentation: https://www.php.net/manual/en/install.fpm.php
- WP-CLI documentation: https://wp-cli.org/
- OpenSSL documentation: https://www.openssl.org/docs/

AI assistance was used as a learning tool for:
- comparing architecture options and Docker concepts
- explaining MariaDB, nginx, WordPress, TLS, secrets, and Compose syntax
- reviewing Dockerfiles, init scripts, Compose configuration, and Makefile targets
- debugging local container startup and validation commands
- drafting project documentation
