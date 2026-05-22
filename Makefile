MAKEFLAGS += --silent

define load
bash -c ' \
	set -euo pipefail; \
	source scripts/messaging-lib.sh; \
	$(1) \
'
endef

include .env
export

VERSIONS := 8.2 8.3 8.4 8.5
BASH_HISTORY_FILE := $(CURDIR)/shell/ubuntu/.bash_history
GIT_CONFIG_FILE := $(CURDIR)/shell/ubuntu/.gitconfig

.PHONY: build build-apache build-all-php-fpm build-single-php-fpm up logs down
build: down build-apache build-all-php-fpm

build-apache:
	$(call load, \
		echo-info "Start building image for Apache server"; \
		docker compose down apache; \
		docker build \
			$(PROGRESS) \
			--no-cache \
			--pull \
			--build-arg PHP_VERSION=$(PHP_VERSION) \
			--build-arg HOST_UID=$(HOST_UID) \
			--build-arg HOST_GID=$(HOST_GID) \
			-t apache \
			-f apache/Dockerfile . ; \
	)

build-all-php-fpm:
	$(call load, \
		@touch "$(BASH_HISTORY_FILE)"; \
		@touch "$(GIT_CONFIG_FILE)"; \
		for VERSION in $(VERSIONS); do \
			echo-info "Start building image for PHP version $$VERSION"; \
			docker compose down php; \
			docker build \
				$(PROGRESS) \
				--no-cache \
				--pull \
				--build-arg PHP_VERSION=$$VERSION \
				--build-arg HOST_UID=$(HOST_UID) \
				--build-arg HOST_GID=$(HOST_GID) \
				-t php-fpm:$$VERSION \
				-f php/Dockerfile . ; \
		done; \
	)

build-single-php-fpm:
	$(call load, \
		if [ "$(origin PHP_VERSION)" != "command line" ]; then \
			echo-error "Pass PHP_VERSION on command line"; \
			echo-info "Example: make build-single-php-fpm PHP_VERSION=8.4"; \
			exit 1; \
		fi; \
		\
		if [ -z "$(filter $(PHP_VERSION), $(VERSIONS))" ]; then \
			echo-error "Invalid PHP version $(PHP_VERSION)"; \
			echo-info "Available versions: $(VERSIONS)"; \
			exit 1; \
		fi; \
		echo-info "Building image for PHP version $(PHP_VERSION)"; \
		docker compose down php; \
		docker build \
			$(PROGRESS) \
			--no-cache \
			--pull \
			--build-arg PHP_VERSION=$(PHP_VERSION) \
			--build-arg HOST_UID=$(HOST_UID) \
			--build-arg HOST_GID=$(HOST_GID) \
			-t php-fpm:$(PHP_VERSION) \
			-f php/Dockerfile . ; \
	)

up:
	$(call load, \
		test -n "$$PHP_VERSION" || { echo-error "PHP_VERSION must be set in .env"; exit 1; }; \
		test -n "$$HOST_UID" || { echo-error "HOST_UID must be set in .env"; exit 1; }; \
		test -n "$$HOST_GID" || { echo-error "HOST_GID must be set in .env"; exit 1; }; \
		\
		echo-info "Starting lamp-php-switch with PHP $$PHP_VERSION"; \
		docker compose up -d; \
	)

logs:
	docker compose logs -f

down:
	docker compose down
