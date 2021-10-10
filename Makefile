########################################################################################################################
# This file acts as the top most level of control in the code base and stores configuration details that are passed
# down to tools like docker compose and application configuration files. The most common form of all commands run
# are captured here. Instead of writing documentation try and script what is possible. Living code is really the only way
# to get up to date documentation. It's also faster in the long run.
########################################################################################################################
.PHONY:


help:
	@grep -E '^[%0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

ifneq (,$(wildcard ./.env))
    include .env
    export
endif

SHELL = /bin/bash

PROJECT_DIR := $(notdir $(CURDIR))

# Values used by targets that use pattern rules (targets with -% in name) to reduce target code duplication
ENV_NAME_UPPERCASE=$(shell echo '$*' | tr '[:lower:]' '[:upper:]')

#########################################################
## START TARGETS FOR DOCKER COMPOSE FOR LOCAL DEVELOPMENT
#########################################################

COMPOSE_HTTP_TIMEOUT=600
API_HOST_PORT_BASE?=20000
BUILD_NUMBER?=0
# COMPOSE_PROJECT_NAME e.g. nestjsexampleapp_api_0_featurevang. Name the project to allow multiple docker compose stacks
COMPOSE_PROJECT_NAME?=nestjsexampleapp_api_${BUILD_NUMBER}_${GIT_BRANCH_SHORT}
# e.g. 23000
API_PORT?=$$((${BUILD_NUMBER} + ${API_HOST_PORT_BASE} + 3000))
# e.g. 29229
API_DEBUG_PORT?=$$((${API_HOST_PORT_BASE} + 9229))
# e.g. 39239
API_TESTS_DEBUG_PORT?=$$((${API_HOST_PORT_BASE} + 10000 + 9229))
# e.g. 25432
DATABASE_PORT?=$$((${API_HOST_PORT_BASE} + ${TYPEORM_PORT}))

DOCKER_COMPOSE_ENV_VARS_BACKEND=API_PORT=${API_PORT} API_DEBUG_PORT=${API_DEBUG_PORT} API_TESTS_DEBUG_PORT=${API_TESTS_DEBUG_PORT} API_CYPRESS_PORT=${API_CYPRESS_PORT} API_AWS_PORT=${API_AWS_PORT} DATABASE_PORT=${DATABASE_PORT}
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
set-env-file-%: ## db-set-env-file-(local|docker|stage|prod) Set the
	@echo "Writing .env file for $* env"; \
	cp .env.$* .env && chmod 0777 .env;

.PHONY: up
up: set-env-file-docker ports ## Bring up the database, and api containers.
	@${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} up --build --no-recreate -d;

.PHONY: down
down: ## Stop and remove containers, networks, images, and volumes
	${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} down -v

.PHONY: recreate
recreate: down up ## Down and up the containers to clear networks and rebuild the containers.

.PHONY: stop
stop: ## Stop services
	@${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} stop

.PHONY: logs
logs: ## Show container logs
	@${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} logs -f -t

.PHONY: logs-*
logs-%:  ## logs-(api|database). Show logs for the service name specified.
	@${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} logs -f -t $*

.PHONY: up-*
up-%: set-env-file-docker ## up-(api|database) Bring up only the an in container. Run this to recreate the container.
	@API_COMMAND='npm run serve' ${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} up --build -d $*

.PHONY: debug
debug: stop-api ## Run the api container in debug mode.
	@API_COMMAND='npm run debug' ${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} up --build -d api

.PHONY: debug-tests
debug-tests: up-database ## Run the api tests in debug mode in docker.
	${DOCKER_COMPOSE_ENV_VARS} API_TEST_COMMAND='npm run debug-tests' ${DOCKER_COMPOSE_ALIAS} run -p ${API_TESTS_DEBUG_PORT}:${API_DOCKER_DEBUG_PORT} api-tests;

.PHONY: start-*
start-%: set-env-file-docker ## start-(api|database). Start the container specified by the docker compose service name.
	@${DOCKER_COMPOSE_ENV_VARS} API_COMMAND='npm run serve' ${DOCKER_COMPOSE_ALIAS} start $*

.PHONY: stop-*
stop-%: ## stop-(api|database). Stop the container specified by the docker compose service name.
	@${DOCKER_COMPOSE_ENV_VARS} ${DOCKER_COMPOSE_ALIAS} stop $*

.PHONY: restart-*
restart-%: stop-% start-% ## restart-(api|database). Stop and start the container specified by the docker compose service name.

.PHONY: recreate-*
recreate-%: up-% ## recreate-(api|database). Recreate (by calling up-%) the container specified by the docker compose service name.

.PHONY: attach-*
attach-%: ## attach-(api_n|database_n) Docker attach to the running database container. There can be n instance so you must specify which instance.
	@${DOCKER_COMPOSE_ENV_VARS} docker exec -it ${COMPOSE_PROJECT_NAME}_$* /bin/bash

#########################################################
## END TARGETS FOR DOCKER COMPOSE FOR LOCAL DEVELOPMENT
#########################################################
