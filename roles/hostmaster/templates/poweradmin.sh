#!/usr/bin/env bash
set -euo pipefail

php_fpm_pid=0
nginx_pid=0

function on_exit() {
  if [ "$php_fpm_pid" -ne 0 ]; then
    kill -SIGINT "$php_fpm_pid"
  fi

  if [ "$nginx_pid" -ne 0 ]; then
    kill -SIGINT "$nginx_pid"
  fi

  wait
}
trap on_exit EXIT

php-fpm --nodaemonize &
php_fpm_pid="$!"

nginx -g 'daemon off;' &
php_fpm_pid="$!"

wait
