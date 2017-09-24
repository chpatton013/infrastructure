FROM fedora:latest

# Install packages.
RUN dnf --assumeyes install nginx \
 && dnf clean all

# Create config files.
COPY reverse_proxy.nginx.conf /etc/nginx/nginx.conf
COPY reverse_proxy.ssl.conf /etc/nginx/ssl.conf
RUN mkdir --parents /etc/nginx/certs \
 && chmod u=rwx,g=,o= /etc/nginx/certs
RUN ln --symbolic --force /etc/nginx/certs/default.crt /etc/nginx/ssl.crt \
 && ln --symbolic --force /etc/nginx/certs/default.key /etc/nginx/ssl.key

EXPOSE 80 443
STOPSIGNAL SIGTERM
CMD ["nginx"]
