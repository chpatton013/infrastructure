#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id --user)" -ne "0" ]]; then
  echo Rerunning as root... >&2
  exec sudo "$0" "$@"
fi

dnf install --assumeyes python
