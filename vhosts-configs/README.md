# Apache vhost configuration

This directory holds ```VirtualHost``` configurations for vhosts inside directory ```./vhosts``` which is mounted onto ```/srv/apache2/vhosts/``` in the php-fpm containers.

The directory is monitored by watchmedo and will trigger a graceful restart of the fronting apache container on editing files.

