COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/$(USER)/data
COMPOSE = docker compose -f $(COMPOSE_FILE)

all: up

setup:
	./srcs/requirements/tools/setup.sh
	
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
	rm -f secrets/MARIADB_PASSWORD secrets/MARIADB_ROOT_PASSWORD secrets/WP_ADMIN_PASSWORD secrets/WP_USER_PASSWORD
	rm -f secrets/TLS_PRIVATE_KEY secrets/SSL_CERTIFICATE

fclean_data: fclean
	sudo rm -rf $(DATA_DIR)/mariadb $(DATA_DIR)/wordpress

.PHONY: all setup up down build ps logs clean fclean fclean_data
