#!/usr/bin/env bash
set -euo pipefail

if rpm --query --quiet python; then
  echo python already installed. Exiting. >&2
  exit 0
fi

if [[ "$(id --user)" -ne "0" ]]; then
  echo Rerunning as root... >&2
  exec sudo "$0" "$@"
fi

dnf install --assumeyes python
