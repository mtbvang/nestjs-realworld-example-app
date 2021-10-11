#-----------------------------------------------------------------------------------------------------------------------
# This file acts as the top most level of control in the code base and stores configuration details that are passed
# down to tools like docker compose and application configuration files. The most common form of all commands run
# are captured here. Instead of writing documentation try and script what is possible. Living code is really the only way
# to get up to date documentation. It's also faster in the long run.
#-----------------------------------------------------------------------------------------------------------------------

SHELL = /bin/bash

help: ## This help dialog.
	@IFS=$$'\n' ; \
	help_lines=(`fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##/:/'`); \
	printf "%-30s %s\n" "target" "help" ; \
	printf "%-30s %s\n" "------" "----" ; \
	for help_line in $${help_lines[@]}; do \
		IFS=$$':' ; \
		help_split=($$help_line) ; \
		help_command=`echo $${help_split[0]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
		help_info=`echo $${help_split[2]} | sed -e 's/^ *//' -e 's/ *$$//'` ; \
		printf '\033[36m'; \
		printf "%-30s %s" $$help_command ; \
		printf '\033[0m'; \
		printf "%s\n" $$help_info; \
	done


define setup_env
	$(eval ENV_FILE := .env.$(1))
	@echo " - setup env $(ENV_FILE)"
	$(eval include .env.$(1))
	$(eval export sed 's/=.*//' .env.$(1))
endef

PROJECT_DIR := $(notdir $(CURDIR))

# Values used by targets that use pattern rules (targets with -% in name) to reduce target code duplication
ENV_NAME_UPPERCASE=$(shell echo '$*' | tr '[:lower:]' '[:upper:]')

# api app node version
NODE_VERSION = 12.14.1

VERSION_API_APP ?= 0.0.1
VERSION_DB_MIGRATION ?= 0

GIT_COMMIT=$(shell git rev-parse HEAD)
GIT_BRANCH=$(shell git name-rev --name-only HEAD)
GIT_BRANCH_SHORT=$(shell echo ${GIT_BRANCH} | tr -cd '[a-zA-Z0-9]')

#--------------------------------------------------------
# START TARGETS FOR DOCKER COMPOSE FOR LOCAL DEVELOPMENT
#--------------------------------------------------------

COMPOSE_HTTP_TIMEOUT=600
API_HOST_PORT_BASE?=20000
BUILD_NUMBER?=0
COMPOSE_BASENAME=nestjsexampleapp_api
# COMPOSE_PROJECT_NAME e.g. nestjsexampleapp_api_0_featurevang. Name the project to allow multiple docker compose stacks
COMPOSE_PROJECT_NAME?=${COMPOSE_BASENAME}_${BUILD_NUMBER}_${GIT_BRANCH_SHORT}
# e.g. 23000
API_PORT?=$$((${BUILD_NUMBER} + ${API_HOST_PORT_BASE} + 3000))
# e.g. 29229
API_DEBUG_PORT?=$$((${API_HOST_PORT_BASE} + 9229))
# e.g. 39239
API_TESTS_DEBUG_PORT?=$$((${API_HOST_PORT_BASE} + 10000 + 9229))
# e.g. 25432
DATABASE_PORT?=$$((${API_HOST_PORT_BASE} + ${TYPEORM_PORT}))

DOCKER_COMPOSE_ENV_VARS_BACKEND=API_PORT=${API_PORT} API_DEBUG_PORT=${API_DEBUG_PORT} API_TESTS_DEBUG_PORT=${API_TESTS_DEBUG_PORT} API_CYPRESS_PORT=${API_CYPRESS_PORT} DATABASE_PORT=${DATABASE_PORT}
DOCKER_COMPOSE_ENV_VARS_DATABASE=DATABASE_PORT=${DATABASE_PORT}
DOCKER_COMPOSE_ENV_VARS_LOCALDEV=NODE_VERSION=${NODE_VERSION} CURRENT_UID=$(CURRENT_UID) CURRENT_GID=$(CURRENT_GID) CURRENT_USERNAME=$(CURRENT_USERNAME) CURRENT_GROUPNAME=$(CURRENT_GROUPNAME)
DOCKER_COMPOSE_ENV_VARS=COMPOSE_HTTP_TIMEOUT=${COMPOSE_HTTP_TIMEOUT} COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME} ${DOCKER_COMPOSE_ENV_VARS_LOCALDEV} ${DOCKER_COMPOSE_ENV_VARS_BACKEND} ${DOCKER_COMPOSE_ENV_VARS_DATABASE}
DOCKER_COMPOSE_ALIAS=docker-compose

.PHONY: ports
ports: ## Print the port numbers used for the docker compose container services
	@echo "BUILD_NUMBER: ${BUILD_NUMBER}"; \
	echo "COMPOSE_PROJECT_NAME: ${COMPOSE_PROJECT_NAME}"; \
	echo "API_PORT: ${API_PORT}"; \
	echo "API_DEBUG_PORT: ${API_DEBUG_PORT}"; \
	echo "DATABASE_PORT: ${DATABASE_PORT}";

.PHONY: set-env-file-*
set-env-file-%: ## db-set-env-file-(local|docker|stage|prod) Set the environment variables in this makefile session and copy the specific environment specific file as the default .env.
	@echo "Including .env.$*"; \
	$(call setup_env,$*) \
	cp -f .env.$* .env && chmod 0777 .env;

.PHONY: up
up: set-env-file-docker ports ## Bring up the database, and api containers.
	@${DOCKER_COMPOSE_ENV_VARS} API_COMMAND='TODO' ${DOCKER_COMPOSE_ALIAS} up --build --no-recreate -d; \


.PHONY: down
down: set-env-file-docker ## Stop and remove containers, networks, images, and volumes
	${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} down -v

.PHONY: recreate
recreate: down up ## Down and up the containers to clear networks and rebuild the containers.

.PHONY: stop
stop: set-env-file-docker ## Stop services
	@${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} stop

.PHONY: logs
logs: set-env-file-docker ## Show container logs
	@${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} logs -f -t

.PHONY: logs-*
logs-%: set-env-file-docker ## logs-(api|database). Show logs for the service name specified.
	@${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} logs -f -t $*

.PHONY: up-*
up-%: set-env-file-docker ## up-(api|database) Bring up only the an in container. Run this to recreate the container.
	@API_COMMAND='TODO' ${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} up --build -d $*

.PHONY: start-*
start-%: set-env-file-docker ## start-(api|database). Start the container specified by the docker compose service name.
	@${DOCKER_COMPOSE_ENV_VARS} API_COMMAND='TODO' ${DOCKER_COMPOSE_ALIAS} start $*

.PHONY: stop-*
stop-%: set-env-file-docker ## stop-(api|database). Stop the container specified by the docker compose service name.
	@${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} stop $*

.PHONY: restart-*
restart-%: stop-% start-% ## restart-(api|database). Stop and start the container specified by the docker compose service name.

.PHONY: recreate-*
recreate-%: up-% ## recreate-(api|database). Recreate (by calling up-%) the container specified by the docker compose service name.

.PHONY: attach-*
attach-%: ## attach-(api_n|database_n) Docker attach to the running database container. There can be n instance so you must specify which instance.
	@${DOCKER_COMPOSE_ENV_VARS} docker exec -it ${COMPOSE_PROJECT_NAME}_$* /bin/bash

#-----------------------------------------------------
# END TARGETS FOR DOCKER COMPOSE FOR LOCAL DEVELOPMENT
#-----------------------------------------------------

.PHONY: build
build: ## build typescript to js files in dist dir.
	@npm install; \
	npm run build; \
	chmod -R 0777 dist

.PHONY: test
test: set-env-file-local ## set the .env file and run tests
	@npm run test

.PHONY: db-migration-generate
db-migration-generate: set-env-file-local ## Generate the db migrations from the entities.
	@if [[ -z "${NEWVERSION}" ]]; then \
		read -r -p "The current db migration version is ${VERSION_DB_MIGRATION} enter the new version: " NEWVERSION; \
		export MIGRATION_NAME="v$${NEWVERSION}_"; \
	fi; \
	echo "MIGRATION_NAME=$$MIGRATION_NAME"; \
	sed -i.bak "s/^VERSION_DB_MIGRATION ?= ${VERSION_DB_MIGRATION}/VERSION_DB_MIGRATION ?= $$NEWVERSION/g" Makefile; \
	npm i; \
	npm run typeorm -- migration:generate -n $$MIGRATION_NAME

.PHONY: db-migration-run-*
db-migration-run-%: set-env-file-local build ## db-migration-run-(local|stage|prod) Run the typeorm db migrations ordered by their dates.
	@echo "Updating .env TYPEORM_ENTITIES TYPEORM_ENTITIES_DIR to include dist dir for migration:run command"; \
	sed -i.bak "s~=src/~=dist/~g" .env; \
	sed -i.bak "s~\.ts~\.js~g" .env; \
	npm run typeorm -- migration:run -t=each

.PHONY: db-load-fixtures-*
db-load-fixtures-%: ## db-load-fixtures-(local|stage) docker=database running in docker, stage=staging environment. Run typeorm-fixtures load fixtures in database.
	@npm run fixtures -- --config tests/ormconfig-$*.yml

.PHONE: db-drop-*
db-drop-%: set-env-file-% ## db-drop-(local|stage|prod) Drop the api database
	@echo "Calling script to drop database on $* env"; \
	export POSTGRES_HOST=$(TYPEORM_HOST); \
	export POSTGRES_USER=$(POSTGRES_USER); \
	export POSTGRES_DB=$(POSTGRES_DB); \
	export APP_DATABASE=$(TYPEORM_DATABASE); \
	export APP_USER=$(TYPEORM_USERNAME); \
	export DB_PORT=$(TYPEORM_PORT); \
	./bin/db-drop.sh

.PHONY: db-ceate-*
db-create-%: set-env-file-% ## db-create-(local|stage|prod). Create the api database on the specified environment.
	@echo "Calling script to create database on $* env"; \
	export POSTGRES_HOST=$(TYPEORM_HOST); \
	export POSTGRES_USER=$(POSTGRES_USER); \
	export POSTGRES_DB=$(POSTGRES_DB); \
	export APP_DATABASE=$(TYPEORM_DATABASE); \
	export APP_USER=$(TYPEORM_USERNAME); \
	export DB_PORT=$(TYPEORM_PORT); \
	./bin/db-create.sh;

.PHONY: db-restore-*
db-restore-%: ## db-restore-(local|docker|docker-cypress|dev|stage|prod). Recreate database,run migrations and load fixtures.
	$(MAKE)	db-drop-$* || (exit 1) && \
	$(MAKE)	db-create-$* || (exit 1) && \
	$(MAKE)	db-migration-run-$* || (exit 1) && \
	$(MAKE)	db-load-fixtures-$* || (exit 1) && \
	$(MAKE) set-env-file-local;  \
	echo 'Database recreated and migrations applied.'

.PHONY: clean-bak-files
clean-bak-files: ## Remove all .bak files create by sed -i.bak option
	@rm -f .*.bak || true; \
	rm -f *.bak || true;

docker-clean: docker-rm-all docker-rm-dangling-volumes docker-rmi-untagged docker-rmi ## Remove dangling volumes and untagged images and stopped containers.
	@docker container prune -f; \
	docker network prune -f; \
	echo "Removed dangling volumes and untagged images and pruned stopped containers and networks"

.PHONY:	docker-rm-all
docker-rm-all: ## remove all containers
	docker rm $$(docker ps -a -q) || true

.PHONY:	docker-rm-dangling-volumes
docker-rm-dangling-volumes: ## Delete the orphaned volumes in Docker
		docker volume rm $$(docker volume ls -qf dangling=true) || true

.PHONY:	docker-ls-dangling-volumes
docker-ls-dangling-volumes: ## List dangling volumes
	docker volume ls -qf dangling=true

.PHONY: docker-rmi
docker-rmi: ## remove docker images. Those images still in use will not be removed.
	docker rmi $$(docker images | grep ${COMPOSE_BASENAME}) || true

.PHONY:	docker-rmi-untagged
docker-rmi-untagged: ## remove untagged images to reclaim space
	docker rmi $$(docker images | grep "<none>" | awk "{print \$$3}") || true

.PHONY: docker-stop-all
docker-stop-all: ## stop all container
	@docker container stop $$(docker container ls -aq)