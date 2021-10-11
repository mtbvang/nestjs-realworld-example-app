#-----------------------------------------------------------------------------------------------------------------------
# This file acts as the commandline tool. These targets act as documentation and live code.
# Instead of writing documentation try and script what is possible. Living code is really the only way
# to get up to date documentation.
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


PROJECT_DIR := $(notdir $(CURDIR))

# Values used by targets that use pattern rules (targets with -% in name) to reduce target code duplication
ENV_NAME_UPPERCASE=$(shell echo '$*' | tr '[:lower:]' '[:upper:]')

# terraform version used
TERRAFORM_VERSION = 0.12.17
TERRAGRUNT_VERSION = 0.21.10

#--------------------------------------------------------
# START TARGETS FOR HEROKU ENV CREATION.
#--------------------------------------------------------

.PHONY: heroku-create-tf-backend-*
heroku-create-tf-backend-%: ## Create the terraform backend environment with postgres DB.
	@export APP_NAME=nestjs-app-tf-backend-$*; \
	heroku create $APP_NAME; \
	heroku addons:create heroku-postgresql:hobby-dev --app $APP_NAME;

.PHONY: terraform-init-backend-%
terraform-init-backend-%: ## Terraform init the terraform backend app.
	@cd heroku/live/eu/$*/
	export DATABASE_URL=`heroku config:get DATABASE_URL --app $APP_NAME`; \
	terragrunt init -backend-config="conn_str=$DATABASE_URL"

.PHONY: heroku-create-env-*
heroku-create-env-%: heroku-create-tf-backend-% terrafrom-init-backend-% ## Create the heroku terraform backend, initialize terraform config and create the heroku pipeline and app.
	@



#-----------------------------------------------------
# END TARGETS FOR HEROKU ENV CREATION
#-----------------------------------------------------

