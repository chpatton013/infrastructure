FROM fedora:latest

# Install packages.
RUN dnf --assumeyes install nginx pdns-tools php-fpm poweradmin \
 && dnf clean all

# Create config files.
COPY config.inc.php /usr/share/poweradmin/inc/config.inc.php
COPY poweradmin.nginx.conf /etc/nginx/nginx.conf
COPY poweradmin.sh /root/poweradmin.sh
RUN chmod +x /root/poweradmin.sh

EXPOSE 80
STOPSIGNAL SIGTERM
CMD ["/root/poweradmin.sh"]
