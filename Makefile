-include .env

# BuildKit enables higher performance docker builds and caching possibility
# to decrease build times and increase productivity for free.
export DOCKER_BUILDKIT ?= 1
export COMPOSE_DOCKER_CLI_BUILD ?= 1

# Binary to use, when executing docker-compose tasks
DOCKER_COMPOSE ?= docker-compose

# Support image with all needed binaries, like envsubst, mkcert, wait4x
SUPPORT_IMAGE ?= wayofdev/build-deps:alpine-latest

BUILDER_PARAMS ?= docker run --rm -i \
	--env-file ./.env \
	--env APP_NAME=$(APP_NAME)

BUILDER ?= $(BUILDER_PARAMS) $(SUPPORT_IMAGE)

# Shorthand envsubst command, executed through build-deps
ENVSUBST ?= $(BUILDER) envsubst


# Self documenting Makefile code
# ------------------------------------------------------------------------------------
ifneq ($(TERM),)
	BLACK := $(shell tput setaf 0)
	RED := $(shell tput setaf 1)
	GREEN := $(shell tput setaf 2)
	YELLOW := $(shell tput setaf 3)
	LIGHTPURPLE := $(shell tput setaf 4)
	PURPLE := $(shell tput setaf 5)
	BLUE := $(shell tput setaf 6)
	WHITE := $(shell tput setaf 7)
	RST := $(shell tput sgr0)
else
	BLACK := ""
	RED := ""
	GREEN := ""
	YELLOW := ""
	LIGHTPURPLE := ""
	PURPLE := ""
	BLUE := ""
	WHITE := ""
	RST := ""
endif
MAKE_LOGFILE = /tmp/py-gpt-slack-bot.log
MAKE_CMD_COLOR := $(BLUE)

default: all

help: ## Show this menu
	@echo 'Management commands for package:'
	@echo 'Usage:'
	@echo '    ${MAKE_CMD_COLOR}make${RST}                       Prepares and spins up project with default settings'
	@grep -E '^[a-zA-Z_0-9%-]+:.*?## .*$$' Makefile | awk 'BEGIN {FS = ":.*?## "}; {printf "    ${MAKE_CMD_COLOR}make %-21s${RST} %s\n", $$1, $$2}'
	@echo
	@echo '    📑 Logs are stored in      $(MAKE_LOGFILE)'
	@echo
	@echo '    📦 Package                 py-gpt-slack-bot (github.com/wayofdev/py-gpt-slack-bot)'
	@echo '    🤠 Author                  Andrij Orlenko (github.com/lotyp)'
	@echo '    🏢 ${YELLOW}Org                     wayofdev (github.com/wayofdev)${RST}'
.PHONY: help

.EXPORT_ALL_VARIABLES:


# Default action
# Defines default command when `make` is executed without additional parameters
# ------------------------------------------------------------------------------------
all: install hooks
.PHONY: all


# System Actions
# ------------------------------------------------------------------------------------
env: ## Generate .env file from example, use `make env force=true`, to force re-create file
ifeq ($(FORCE),true)
	@echo "${YELLOW}Force re-creating .env file from example...${RST}"
	$(ENVSUBST) < ./.env.example > ./.env
else ifneq ("$(wildcard ./.env)","")
	@echo ""
	@echo "${YELLOW}The .env file already exists! Use FORCE=true to re-create.${RST}"
else
	@echo "Creating .env file from example"
	$(ENVSUBST) < ./.env.example > ./.env
endif
.PHONY: env

i: ## Install dependencies
	poetry install
.PHONY: i

install: i ## Same as `make i`
.PHONY: install


# Docker Actions
# ------------------------------------------------------------------------------------
up: ## Spin up this project using docker
	$(DOCKER_COMPOSE) up --remove-orphans
	@echo "🚀 Started and available at https://$(APP_NAME).$(PROJECT_SERVICES_NAMESPACE).docker"
.PHONY: up

down: ## Stops and removes all project containers
	$(DOCKER_COMPOSE) down --remove-orphans
.PHONY: down

restart: down up ## Removes containers and stops, then starts new instances
.PHONY: restart

ps: ## Show running containers
	$(DOCKER_COMPOSE) ps
.PHONY: ps

logs: ## Show all project docker logs
	$(DOCKER_COMPOSE) logs -f
.PHONY: logs

ssh: ## Login into running app container
	$(DOCKER_COMPOSE) run --rm -it app sh
.PHONY: ssh

pull: ## Pull latest docker image from docker hub for app container
	$(DOCKER_COMPOSE) pull app
.PHONY: pull

build: ## Build docker image
	$(DOCKER_COMPOSE) build app --pull
.PHONY: build


# Git Actions
# ------------------------------------------------------------------------------------
hooks: ## Install git hooks from husky
	poetry run pre-commit install
	poetry run pre-commit autoupdate
.PHONY: hooks
