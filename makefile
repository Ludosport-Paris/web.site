.PHONY: up down build

# Docker compose UP
up:
	@docker volume inspect ludosport_db_data > /dev/null 2>&1 || docker volume create ludosport_db_data
	@docker volume inspect ludosport_solr_data > /dev/null 2>&1 || docker volume create ludosport_solr_data
	@docker volume inspect ludosport_www > /dev/null 2>&1 || docker volume create ludosport_www
	@docker volume inspect ludosport_public_files > /dev/null 2>&1 || docker volume create ludosport_public_files
	@docker volume inspect ludosport_private_files > /dev/null 2>&1 || docker volume create ludosport_private_files
	@docker network inspect ludosport > /dev/null 2>&1 || docker network create ludosport
	@docker network inspect services > /dev/null 2>&1 || docker network create services
	@docker compose up --build --remove-orphans -d

down:
	@docker compose down --remove-orphans

ci:
	@docker compose exec -ti -u deploy php-fpm composer install

dcr:
	@docker compose exec -ti -u www-data php-fpm drush cr

ssh:
	@docker compose exec -ti php-fpm /bin/bash

REV := $(shell date +%s)
build:
	@mkdir -p ./build/$(REV)
	@git clone git@github.com:Zlika666/ludosport.paris.git ./build/clone
	@cp -r ./build/clone/web ./build/$(REV)
	@cp -r ./build/clone/config ./build/$(REV)
	@cp ./build/clone/composer.* ./build/$(REV)
	@sudo chown -R root:www-data ./build/$(REV)
	@tar -cf ./artefacts/$(REV).tar -C ./build/$(REV) .
	@sudo rm -rf ./build