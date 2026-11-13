<p align="left">
<a href="https://github.com/martinschumann/docker-lamp-php-switch/actions"><img src="https://github.com/martinschumann/docker-lamp-php-switch/actions/workflows/ci.yaml/badge.svg" alt></a>
</p>

# docker-lamp-php-switch

My personal Docker LAMP container built to easily develop and test websites locally with Apache and PHP 8.2, 8.3, 8.4, or 8.5. Each PHP version has its own PHP-FPM image so different system packages and PHP extensions for each version can be installed. MariaDB and PostgreSQL are both optional.

## Quick start

Requires Docker with the Compose plugin and Make.

```sh
git clone https://github.com/martinschumann/docker-lamp-php-switch
```

```sh
cd docker-lamp-php-switch
```

```sh
cp .env.example .env
```

```sh
docker compose up -d --build
```

Root-Certificate has to be imported. Use one of these:
```sh
make cert-import-macos
```

```sh
make cert-import-linux
```

```sh
make cert-import-windows
```
Last one is not yet implemented.

Log into the php-fpm container:
```sh
./shell.sh
```

```sh
[ubuntu@php-8.4]:~$ cd vhosts/examplehost/
```

```
[ubuntu@php-8.4]:~$ composer update -vv
```
