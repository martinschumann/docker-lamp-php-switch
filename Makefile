ESC   := $(shell printf '\033')
BLUE  := $(ESC)[36m
RESET := $(ESC)[0m

define BANNER
$(BLUE)  ┌─────────────────────────────────────────────┐$(RESET)
$(BLUE)  │ ┬  ┌─┐┌┬┐┌─┐   ┌─┐┬ ┬┌─┐   ┌─┐┬ ┬┬┌┬┐┌─┐┬ ┬ │$(RESET)
$(BLUE)  │ │  ├─┤│││├─┘───├─┘├─┤├─┘───└─┐││││ │ │  ├─┤ │$(RESET)
$(BLUE)  │ ┴─┘┴ ┴┴ ┴┴     ┴  ┴ ┴┴     └─┘└┴┘┴ ┴ └─┘┴ ┴ │$(RESET)
$(BLUE)  └─────────────────────────────────────────────┘$(RESET)
endef

SHELL       := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS   += --silent

# Load settings
ifneq ($(wildcard .env),)
    include .env
endif

# Translate DB usage flags into profile arguments
DB_PROFILES := \
    $(if $(filter 1,$(USE_MARIADB)),--profile mariadb) \
    $(if $(filter 1,$(USE_POSTGRES)),--profile pgsql)

ROOT_CA_CERT = ./pki/ca/root-ca.lamp-php-switch.crt
CA_WAIT_TIMEOUT ?= 30
CACHE_BUST := $(shell date +%s)

define BASH_LIB
echo_info()    { echo -e "\033[1;34m[INFO]\033[0m    $$*"; }; \
echo_success() { echo -e "\033[1;32m[SUCCESS]\033[0m $$*"; }; \
echo_warn()    { echo -e "\033[1;33m[WARN]\033[0m    $$*"; }; \
echo_error()   { echo -e "\033[1;31m[ERROR]\033[0m   $$*"; };
endef

# Available php versions
PHP_VERSIONS := 8.2 8.3 8.4 8.5

.DEFAULT_GOAL := help

help: ## Display this help
	$(info $(BANNER))
	echo "Available targets:"
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(ESC)[36m%-25s\033[0m %s\n", $$1, $$2}' | grep -E -v 'build-ssl-cert|build-apache|build-php'

build: ## Build the container stack
	$(BASH_LIB) echo_info "Start building lamp-php-switch";
	docker compose build pki apache mariadb postgres

	$(BASH_LIB) for VERSION in $(PHP_VERSIONS); do \
		echo_info "Image for PHP $$VERSION | Building"; \
		PHP_VERSION=$$VERSION docker compose build php-fpm --no-cache; \
	done

up: ## Start the container stack
	$(BASH_LIB) if [ "$(CHAINED)" != "1" ]; then \
		echo_info "Starting lamp-php-switch with PHP $(PHP_VERSION)"; \
	fi

	docker compose $(DB_PROFILES) up -d --remove-orphans

down: ## Stop the container stack
	$(BASH_LIB) echo_info "Stopping lamp-php-switch with PHP $(PHP_VERSION)";
	docker compose --profile '*' down

logs: ## Tail logs
	docker compose logs -f

update-composer: ## Update Composer in PHP-FPM images
	$(BASH_LIB) echo_info "Updating Composer in lamp-php-switch"; \
	for VERSION in $(PHP_VERSIONS); do \
		image="martinschumann/docker-lamp-php-switch-php-fpm:$$VERSION"; \
		if ! docker image inspect "$$image" >/dev/null; then \
			echo_error "Cannot inspect local image: $$image"; \
			exit 1; \
		fi; \
	done

	docker compose down

	$(BASH_LIB) for VERSION in $(PHP_VERSIONS); do \
		image="martinschumann/docker-lamp-php-switch-php-fpm:$$VERSION"; \
		current=$$(docker run --rm --pull=never --entrypoint composer \
			"$$image" --no-ansi --version 2>/dev/null \
			| grep -Eo '^Composer version [^[:space:]]+') || current="not available"; \
		current="$${current#Composer version }"; \
		echo_info "Image for PHP $$VERSION | Composer installed at version: $$current"; \
		echo_info "Image for PHP $$VERSION | Building"; \
		PHP_VERSION="$$VERSION" docker compose build \
			--build-arg "COMPOSER_CACHE_BUST=$(CACHE_BUST)" php-fpm; \
		update=$$(docker run --rm --pull=never --entrypoint composer \
			"$$image" --no-ansi --version \
			| grep -Eo '^Composer version [^[:space:]]+') || { \
			echo_error "Image for PHP $$VERSION | Cannot determine Composer version after build"; \
			exit 1; \
		}; \
		update="$${update#Composer version }"; \
		if [[ "$$current" == "not available" ]]; then \
			echo_info "Image for PHP $$VERSION | Composer after build: $$update"; \
		elif [[ "$$current" == "$$update" ]]; then \
			echo_info "Image for PHP $$VERSION | Composer stayed at: $$update"; \
		else \
			echo_success "Image for PHP $$VERSION | Composer changed: $$current -> $$update"; \
		fi; \
		echo; \
	done

	$(MAKE) up

generate-ca-cert: ## Restart the container and generate a Root-CA certificate at boot time
	$(BASH_LIB) echo_info "Generate a Root-CA certificate";
	docker compose down && \
	RENEW_SSL_CA=1 docker compose up -d

backup-mariadb: ## Not implemented
	$(BASH_LIB) echo_error "Next target to be added"; \
	exit 1

wait-for-root-ca:
	$(BASH_LIB) cert="$(ROOT_CA_CERT)"; \
	deadline=$$((SECONDS + $(CA_WAIT_TIMEOUT))); \
	until [[ -f "$$cert" && -r "$$cert" && -s "$$cert" ]] \
		&& details=$$(openssl x509 -in "$$cert" -noout -text 2>/dev/null) \
		&& [[ "$$details" == *"CA:TRUE"* ]] \
		&& openssl verify -check_ss_sig -CAfile "$$cert" "$$cert" >/dev/null 2>&1; do \
		if (( SECONDS >= deadline )); then \
			echo_error "No readable, valid Root CA after $(CA_WAIT_TIMEOUT)s: $$cert" >&2; \
			exit 1; \
		fi; \
		sleep 1; \
	done

cert-import-macos: ## Import the Root CA certificate into macOS Keychain Access
	$(BASH_LIB) echo_info "Restarting the container stack"
	docker compose down
	$(MAKE) up CHAINED=1
	$(MAKE) wait-for-root-ca

	$(BASH_LIB) echo_info "Importing the Root CA into the macOS system keychain"
	sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$(ROOT_CA_CERT)"

cert-import-linux: ## Import the Root CA certificate into the Linux system trust store
	$(BASH_LIB) echo_info "Restarting the container stack"
	docker compose down
	$(MAKE) up CHAINED=1
	$(MAKE) wait-for-root-ca

	$(BASH_LIB) if [ ! -f /etc/os-release ]; then \
		echo_error "No os-release standard file found"; \
		exit 1; \
	fi

	$(BASH_LIB) if grep -qiE "ubuntu|debian|suse" /etc/os-release; then \
		echo_info "Debian/Ubuntu/SuSE ecosystem detected"; \
		# \
		if [ -d /etc/pki/trust/anchors ]; then \
			sudo cp "$(ROOT_CA_CERT)" /etc/pki/trust/anchors/; \
		else \
			sudo cp "$(ROOT_CA_CERT)" /usr/local/share/ca-certificates/; \
		fi; \
		# \
		sudo update-ca-certificates; \
	elif grep -qiE "rhel|centos|fedora|rocky|alma" /etc/os-release; then \
		echo_info "RedHat/Fedora ecosystem detected"; \
		sudo cp "$(ROOT_CA_CERT)" /etc/pki/ca-trust/source/anchors/; \
		sudo update-ca-trust; \
	else \
		echo_error "Unsupported Linux distribution"; \
		exit 1; \
	fi

cert-import-windows: ## Not implemented
	$(BASH_LIB) echo_error "Not implemented"; \
	exit 1
