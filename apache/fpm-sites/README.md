# apache/fpm-sites

This directory holds ```VirtualHost``` configurations for vhosts inside directory ```./vhosts``` on the host which is mounted onto ```/srv/apache2/vhosts/``` in the php-fpm container.

The directory is monitored by watchmedo and will trigger a graceful restart of the fronting apache container.

