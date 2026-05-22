# docker-lamp-php-switch

My personal Docker LAMP container drafted to easily test a website under all currently supported PHP versions starting by PHP 8.2 up to 8.5

The stack serves virtual hosts on the domain ```lamp.localhost```. The PHP version under which a site should be tested, can be chosen in the ```./env``` file.

Data for a virtual host or development site are placed in ```./vhosts```. A corresponding Apache configuration file must be added in ```./apache/fpm-sites```. The configured virtual host will proxy-pass requests for PHP files to a PHP-FPM server that runs under the chosen PHP version.

## How to use

```
$ git clone https://github.com/martinschumann/docker-lamp-php-switch
```
```
$ cd docker-lamp-php-switch
```
```
$ cp .env-example .env
```
```
$ make build && make up
```

Root-Certificate has to be imported. On MacOS that may be done by:
```
$ sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ./apache/ssl/certs/lamp.localhost-rootCA.crt
```
Or by dropping the cert file into Keychain Access and setting it trusted.

Log into the php-fpm container.
```
$ ./shell.sh
```
```
[ubuntu@php-8.3]:~$ cd /srv/apache2/vhosts/examplehost
```
```
[ubuntu@php-8.3]:~$ composer update -vv
```
