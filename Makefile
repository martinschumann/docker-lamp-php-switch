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

SSL_ROOT_CA_CERT = ./pki/ssl/certs/root-ca-lamp-php-switch.crt

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
	echo "Avalailabe targets:"
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(ESC)[36m%-25s\033[0m %s\n", $$1, $$2}' | grep -E -v 'build-ssl-cert|build-apache|build-php'

build: ## Build the container stack
	$(BASH_LIB) echo_info "Start building lamp-php-switch";
	docker compose build pki apache --no-cache

	for VERSION in $(PHP_VERSIONS); do \
		$(BASH_LIB) echo_info "Building image for PHP version $$VERSION"; \
		PHP_VERSION=$$VERSION docker compose build php --no-cache; \
	done

up: ## Start the container stack
	if [ "$(CHAINED)" != "1" ]; then \
		$(BASH_LIB) echo_info "Starting lamp-php-switch with PHP $(PHP_VERSION)"; \
	fi

	docker compose up apache php mariadb -d --no-build --remove-orphans

down: ## Stop the container stack
	$(BASH_LIB) echo_info "Stopping lamp-php-switch with PHP $(PHP_VERSION)";
	docker compose down

logs: ## Tail logs
	docker compose logs -f

cert-import-macos: ## Import the Root CA certificate into macOS Keychain Access
	$(BASH_LIB) echo_info "Ensuring that container stack is running and certificates are present."
	$(MAKE) up CHAINED=1

	if [ ! -f "$(SSL_ROOT_CA_CERT)" ]; then \
		$(BASH_LIB) echo_error "Root CA certificate not found: $(SSL_ROOT_CA_CERT)"; \
		exit 1; \
	fi

	$(BASH_LIB) echo_info "Calling system keychain."
	sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$(SSL_ROOT_CA_CERT)"

cert-import-linux: up ## Import the Root CA certificate into the Linux system trust store
	$(BASH_LIB) echo_info "Ensuring that container stack is running and certificates are present."
	$(MAKE) up CHAINED=1

	if [ ! -f "$(SSL_ROOT_CA_CERT)" ]; then \
		$(BASH_LIB) echo_error "Root CA certificate not found: $(SSL_ROOT_CA_CERT)"; \
		exit 1; \
	fi

	if [ ! -f /etc/os-release ]; then \
		$(BASH_LIB) echo_error "No os-release standard file found."; \
		exit 1; \
	fi

	if grep -qiE "ubuntu|debian|suse" /etc/os-release; then \
		$(BASH_LIB) echo_info "Debian/Ubuntu/SuSE ecosystem detected."; \
		# \
		if [ -d /etc/pki/trust/anchors ]; then \
			sudo cp "$(SSL_ROOT_CA_CERT)" /etc/pki/trust/anchors/; \
		else \
			sudo cp "$(SSL_ROOT_CA_CERT)" /usr/local/share/ca-certificates/; \
		fi; \
		# \
		sudo update-ca-certificates; \
	elif grep -qiE "rhel|centos|fedora|rocky|alma" /etc/os-release; then \
		$(BASH_LIB) echo_info "RedHat/Fedora ecosystem detected."; \
		sudo cp "$(SSL_ROOT_CA_CERT)" /etc/pki/ca-trust/source/anchors/; \
		sudo update-ca-trust; \
	else \
		$(BASH_LIB) echo_error "Unsupported Linux distribution."; \
		exit 1; \
	fi

cert-import-windows: ## Not implemented
	$(BASH_LIB) echo_error "Not implemented."; \
	exit 1
