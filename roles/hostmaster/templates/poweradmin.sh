#!/usr/bin/env bash
set -euo pipefail

php-fpm --nodaemonize &
php_fpm_pid="$!"

function on_exit() {
  kill -SIGINT "$php_fpm_pid"
  wait
}
trap on_exit EXIT

nginx
