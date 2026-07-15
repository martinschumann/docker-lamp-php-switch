ESC := $(shell printf '\033')
BLUE := $(ESC)[36m
RESET := $(ESC)[0m

define BANNER
$(BLUE)  ┌─────────────────────────────────────────────┐$(RESET)
$(BLUE)  │ ┬  ┌─┐┌┬┐┌─┐   ┌─┐┬ ┬┌─┐   ┌─┐┬ ┬┬┌┬┐┌─┐┬ ┬ │$(RESET)
$(BLUE)  │ │  ├─┤│││├─┘───├─┘├─┤├─┘───└─┐││││ │ │  ├─┤ │$(RESET)
$(BLUE)  │ ┴─┘┴ ┴┴ ┴┴     ┴  ┴ ┴┴     └─┘└┴┘┴ ┴ └─┘┴ ┴ │$(RESET)
$(BLUE)  └─────────────────────────────────────────────┘$(RESET)
endef

$(info $(BANNER))

SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
MAKEFLAGS += --silent

ifneq ($(wildcard .env),)
    include .env
    export
endif

SSL_ROOT_CA_CERT = ./apache/ssl/certs/lamp.localhost-rootCA.crt
SSL_BUILD_FILE = ./apache/ssl/conf/.ssl_build_stamp
_init := $(shell [ ! -f $(SSL_BUILD_FILE) ] && echo 0 > $(SSL_BUILD_FILE))
SSL_BUILD_STAMP := $(shell cat $(SSL_BUILD_FILE))
RENEW_SSL_CERT_ON_BUILD ?= 0
SSL_BUILD_STAMP := $(if $(filter 1,$(RENEW_SSL_CERT_ON_BUILD)),$(shell date +%s),$(SSL_BUILD_STAMP))

TAIL_BUILD_LOG ?= 0
TAIL_BUILD_LOG := $(if $(filter 0,$(TAIL_BUILD_LOG)),'','--progress=plain')

PHP_VERSIONS := 8.2 8.3 8.4 8.5

.DEFAULT_GOAL := help
.PHONY: build build-cert build-apache build-php build-single-php up logs down

help: ## Display this help
	echo "Avalailabe targets:"
	grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(ESC)[36m%-25s\033[0m %s\n", $$1, $$2}'

build: down build-cert build-apache build-php ## Build all necessary images

up: ## Start the container stack
	source scripts/messaging-lib.sh; \
	if [ -z "$${PHP_VERSION:-}" ]; then \
		echo_error "PHP_VERSION must be set in .env"; \
		exit 1; \
	fi

	source scripts/messaging-lib.sh; \
	if [ -z "$${HOST_UID:-}" ]; then \
		echo_error "HOST_UID must be set in .env"; \
		exit 1; \
	fi

	source scripts/messaging-lib.sh; \
	if [ -z "$${HOST_GID:-}" ]; then \
		echo_error "HOST_GID must be set in .env"; \
		exit 1; \
	fi

	source scripts/messaging-lib.sh; \
	echo_info "Starting lamp-php-switch with PHP $$PHP_VERSION"
	
	docker compose up -d

down: ## Stop the container stack
	docker compose down

build-cert: ## Build the init-cert-generator image
	source scripts/messaging-lib.sh; \
	echo_info "Start building image for initial cert generation"; \
	docker compose down init-cert-generator; \
	BUILD_LOG=$(TAIL_BUILD_LOG); \
	docker build \
		$$BUILD_LOG \
		--pull \
		--build-arg SSL_BUILD_STAMP=$(SSL_BUILD_STAMP) \
		--target init-cert-generator \
		-t init-cert-generator:latest \
		-f apache/Dockerfile .

build-apache: ## Build the fronting apache image
	source scripts/messaging-lib.sh; \
	echo_info "Start building image for Apache server"; \
	docker compose down apache; \
	BUILD_LOG=$(TAIL_BUILD_LOG); \
	docker build \
		$$BUILD_LOG \
		--pull \
		--build-arg SSL_BUILD_STAMP=$(SSL_BUILD_STAMP) \
		--build-arg PHP_VERSION=$(PHP_VERSION) \
		--build-arg HOST_UID=$(HOST_UID) \
		--build-arg HOST_GID=$(HOST_GID) \
		-t apache:latest \
		-f apache/Dockerfile .

build-php: ## Build all php images (PHP-FPM server)
	source scripts/messaging-lib.sh; \
	for VERSION in $(PHP_VERSIONS); do \
		echo_info "Start building image for PHP version $$VERSION"; \
		docker compose down php; \
		BUILD_LOG=$(TAIL_BUILD_LOG); \
		docker build \
			$$BUILD_LOG \
			--pull \
			--build-arg PHP_VERSION=$$VERSION \
			--build-arg HOST_UID=$(HOST_UID) \
			--build-arg HOST_GID=$(HOST_GID) \
			-t php-fpm:$$VERSION \
			-f php/Dockerfile . ; \
	done

build-single-php: ## Build a specific php image (PHP-FPM server) only
	source scripts/messaging-lib.sh; \
	if [ "$(origin PHP_VERSION)" != "command line" ]; then \
		echo_error "Pass PHP_VERSION on command line"; \
		echo_info "Example: make build-single-php PHP_VERSION=8.4"; \
		exit 1; \
	fi

	source scripts/messaging-lib.sh; \
	if [ -z "$(filter $(PHP_VERSION), $(PHP_VERSIONS))" ]; then \
		echo_error "Invalid PHP version $(PHP_VERSION)"; \
		echo_info "Available PHP_VERSIONS: $(PHP_VERSIONS)"; \
		exit 1; \
	fi

	source scripts/messaging-lib.sh; \
	echo_info "Building image for PHP version $(PHP_VERSION)"; \
	docker compose down php; \
	BUILD_LOG=$(TAIL_BUILD_LOG); \
	docker build \
		$$BUILD_LOG \
		--pull \
		--build-arg PHP_VERSION=$(PHP_VERSION) \
		--build-arg HOST_UID=$(HOST_UID) \
		--build-arg HOST_GID=$(HOST_GID) \
		-t php-fpm:$(PHP_VERSION) \
		-f php/Dockerfile .

logs: ## Tail logs
	docker compose logs -f

cert-import-macos: ## Import the Root CA certificate into macOS Keychain Access
	source scripts/messaging-lib.sh; \

	if [ ! -f "$(SSL_ROOT_CA_CERT)" ]; then \
		echo_error "Root CA certificate not found: $(SSL_ROOT_CA_CERT)"; \
		exit 1; \
	fi

	sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$(SSL_ROOT_CA_CERT)"

cert-import-linux: ## Import the Root CA certificate into the Linux system trust store
	source scripts/messaging-lib.sh; \

	if [ ! -f "$(SSL_ROOT_CA_CERT)" ]; then \
		echo_error "Root CA certificate not found: $(SSL_ROOT_CA_CERT)"; \
		exit 1; \
	fi

	source scripts/messaging-lib.sh; \

	if [ ! -f /etc/os-release ]; then \
		echo_error "No os-release standard file found."; \
		exit 1; \
	fi

	source scripts/messaging-lib.sh; \

	if grep -qiE "ubuntu|debian|suse" /etc/os-release; then \
		echo_info "Debian/Ubuntu/SuSE ecosystem detected."; \
		# \
		if [ -d /etc/pki/trust/anchors ]; then \
			sudo cp "$(SSL_ROOT_CA_CERT)" /etc/pki/trust/anchors/; \
		else \
			sudo cp "$(SSL_ROOT_CA_CERT)" /usr/local/share/ca-certificates/; \
		fi; \
		# \
		sudo update-ca-certificates; \
	elif grep -qiE "rhel|centos|fedora|rocky|alma" /etc/os-release; then \
		echo_info "RedHat/Fedora ecosystem detected."; \
		sudo cp "$(SSL_ROOT_CA_CERT)" /etc/pki/ca-trust/source/anchors/; \
		sudo update-ca-trust; \
	else \
		echo_error "Unsupported Linux distribution."; \
		exit 1; \
	fi

cert-import-windows: ## Not implemented
	source scripts/messaging-lib.sh; \
	echo_error "Not implemented."; \
	exit 1
