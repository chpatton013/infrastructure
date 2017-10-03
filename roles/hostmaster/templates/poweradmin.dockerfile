FROM fedora:latest

# Install packages.
RUN dnf --assumeyes install nginx pdns-tools php-fpm poweradmin \
 && dnf clean all

# Create config files.
COPY config.inc.php /usr/share/poweradmin/inc/config.inc.php
COPY poweradmin.nginx.conf /etc/nginx/nginx.conf
COPY poweradmin.sh /root/poweradmin.sh
RUN chmod +x /root/poweradmin.sh

# Link logs to stdout/stderr so docker can pick them up.
RUN mkdir --parents /var/log/nginx /var/log/php-fpm \
 && ln --symbolic --force /dev/stdout /var/log/nginx/access.log \
 && ln --symbolic --force /dev/stderr /var/log/nginx/error.log \
 && ln --symbolic --force /dev/stderr /var/log/php-fpm/error.log \
 && ln --symbolic --force /dev/stderr /var/log/php-fpm/www-error.log

EXPOSE 80
STOPSIGNAL SIGTERM
CMD ["/root/poweradmin.sh"]
