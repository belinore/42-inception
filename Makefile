COMPOSE_FILE = srcs/docker-compose.yml
# Final 42 VM path:
DATA_DIR = /home/belinore/data
#DATA_DIR = /Users/beth/in_progress/inception/data
COMPOSE = docker compose -f $(COMPOSE_FILE)

all: up

setup:
	mkdir -p $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

up: setup
	$(COMPOSE) up --build

down:
	$(COMPOSE) down

build: setup
	$(COMPOSE) build

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs

clean:
	$(COMPOSE) down

fclean:
	$(COMPOSE) down -v
	rm -rf $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

cert:
	@if [ ! -f secrets/TLS_PRIVATE_KEY ] || [ ! -f secrets/SSL_CERTIFICATE ]; then \
		openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
			-keyout secrets/TLS_PRIVATE_KEY \
			-out secrets/SSL_CERTIFICATE \
			-subj "/CN=belinore.42.fr"; \
	else \
		echo "TLS certificate already exists."; \
	fi

.PHONY: all setup up down build ps logs clean fclean cert
