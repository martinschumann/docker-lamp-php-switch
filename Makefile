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

MAKEFLAGS += --silent

define load
bash -c ' \
	set -euo pipefail; \
	source scripts/messaging-lib.sh; \
	$(1) \
'
endef

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
	@echo "Avalailabe targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(ESC)[36m%-25s\033[0m %s\n", $$1, $$2}'

build: down build-cert build-apache build-php ## Build all necessary images

# up: ## Start the container stack
# 	$(call load, \
# 		/bin/bash <<'EOF'
# 		test -n "$$PHP_VERSION" || { echo-error "PHP_VERSION must be set in .env"; exit 1; }
# 		test -n "$$HOST_UID" || { echo-error "HOST_UID must be set in .env"; exit 1; }
# 		test -n "$$HOST_GID" || { echo-error "HOST_GID must be set in .env"; exit 1; }

# 		echo-info "Starting lamp-php-switch with PHP $$PHP_VERSION"
# 		docker compose up -d
# 		EOF
# 	)

down: ## Stop the container stack
	docker compose down

build-cert: ## Build the init-cert-generator image
	$(call load, echo-info "Start building image for initial cert generation")
	docker compose down init-cert-generator
	docker build \
		$$(TAIL_BUILD_LOG) \
		--pull \
		--build-arg SSL_BUILD_STAMP=$(SSL_BUILD_STAMP) \
		--target init-cert-generator \
		-t init-cert-generator:latest \
		-f apache/Dockerfile .


# build-apache: ## Build the fronting apache image
# 	$(call load, \
# 		/bin/bash <<'EOF'
# 		echo-info "Start building image for Apache server"
# 		docker compose down apache
# 		docker build \
# 			$(TAIL_BUILD_LOG) \
# 			--pull \
# 			--build-arg SSL_BUILD_STAMP=$(SSL_BUILD_STAMP) \
# 			--build-arg PHP_VERSION=$(PHP_VERSION) \
# 			--build-arg HOST_UID=$(HOST_UID) \
# 			--build-arg HOST_GID=$(HOST_GID) \
# 			-t apache:latest \
# 			-f apache/Dockerfile .
# 		EOF
# 	)

# build-php: ## Build all php images (PHP-FPM server)
# 	$(call load, \
# 		/bin/bash <<'EOF'
# 		for VERSION in $(PHP_VERSIONS); do
# 			echo-info "Start building image for PHP version $$VERSION"
# 			docker compose down php
# 			docker build \
# 				$(TAIL_BUILD_LOG) \
# 				--pull \
# 				--build-arg PHP_VERSION=$$VERSION \
# 				--build-arg HOST_UID=$(HOST_UID) \
# 				--build-arg HOST_GID=$(HOST_GID) \
# 				-t php-fpm:$$VERSION \
# 				-f php/Dockerfile .
# 		done
# 		EOF
# 	)

# build-single-php: ## Build a specific php image (PHP-FPM server) only
# 	$(call load, \
# 		/bin/bash <<'EOF'
# 		if [ "$(origin PHP_VERSION)" != "command line" ]; then
# 			echo-error "Pass PHP_VERSION on command line"
# 			echo-info "Example: make build-single-php PHP_VERSION=8.4"
# 			exit 1
# 		fi;

# 		if [ -z "$(filter $(PHP_VERSION), $(PHP_VERSIONS))" ]; then
# 			echo-error "Invalid PHP version $(PHP_VERSION)"
# 			echo-info "Available PHP_VERSIONS: $(PHP_VERSIONS)"
# 			exit 1
# 		fi

# 		echo-info "Building image for PHP version $(PHP_VERSION)"
# 		docker compose down php
# 		docker build \
# 			$(TAIL_BUILD_LOG) \
# 			--pull \
# 			--build-arg PHP_VERSION=$(PHP_VERSION) \
# 			--build-arg HOST_UID=$(HOST_UID) \
# 			--build-arg HOST_GID=$(HOST_GID) \
# 			-t php-fpm:$(PHP_VERSION) \
# 			-f php/Dockerfile .
# 		EOF
# 	)


# logs: ## Tail logs
# 	docker compose logs -f

# cert-import-macos: ## Import the Root CA certificate into macOS Keychain Access
# 	$(call load, \
# 		/bin/bash <<'EOF'
# 		[ -f $(SSL_ROOT_CA_CERT) ] || { echo-error "Root CA certificate not found: $(SSL_ROOT_CA_CERT)"; exit 1; }
# 		sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./apache/ssl/certs/lamp.localhost-rootCA.crt
# 		EOF
# 	)

# cert-import-linux: ## Import the Root CA certificate into the Linux system trust store
# 	$(call load, \
# 		/bin/bash <<'EOF'
# 		[ -f $(SSL_ROOT_CA_CERT) ] || { echo-error "Root CA certificate not found: $(SSL_ROOT_CA_CERT)"; exit 1; }
# 		[ -f /etc/os-release ] || { echo "No os-release standard file found."; exit 1; }

# 		if grep -qiE "ubuntu|debian|suse" /etc/os-release; then
# 			echo "Debian/Ubuntu/SuSE ecosystem detected."

# 			if [ -d /etc/pki/trust/anchors ]; then
# 				sudo cp $(SSL_ROOT_CA_CERT) /etc/pki/trust/anchors/
# 			else
# 				sudo cp $(SSL_ROOT_CA_CERT) /usr/local/share/ca-certificates/
# 			fi

# 			sudo update-ca-certificates
# 		elif grep -qiE "rhel|centos|fedora|rocky|alma" /etc/os-release; then
# 			echo "RedHat/Fedora ecosystem detected."
# 			sudo cp $(SSL_ROOT_CA_CERT) /etc/pki/ca-trust/source/anchors/
# 			sudo update-ca-trust
# 		else
# 			echo "Unsupported Linux distribution."
# 			exit 1
# 		fi
# 		EOF
# 	)

# cert-import-windows: ## Not implemented
# 	$(call load, \
# 		/bin/bash <<'EOF'
# 		echo-error "Not implemented."

# 		exit 1
# 		EOF
# 	)
