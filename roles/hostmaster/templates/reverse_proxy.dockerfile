FROM fedora:latest

# Install packages.
RUN dnf --assumeyes install nginx \
 && dnf clean all

# Create config files.
COPY reverse_proxy.nginx.conf /etc/nginx/nginx.conf
COPY reverse_proxy.ssl.conf /etc/nginx/ssl.conf
RUN mkdir --parents /etc/nginx/certs \
 && chmod u=rwx,g=,o= /etc/nginx/certs \
 && ln --symbolic --force /etc/nginx/certs/default.crt /etc/nginx/ssl.crt \
 && ln --symbolic --force /etc/nginx/certs/default.key /etc/nginx/ssl.key

# Link logs to stdout/stderr so docker can pick them up.
RUN mkdir --parents /var/log/nginx \
 && ln --symbolic --force /dev/stdout /var/log/nginx/access.log \
 && ln --symbolic --force /dev/stderr /var/log/nginx/error.log

EXPOSE 80 443
STOPSIGNAL SIGTERM
CMD ["nginx"]
