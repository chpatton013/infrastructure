#!/usr/bin/env bash
set -euo pipefail

if rpm --query --quiet python; then
  echo python already installed. Exiting. >&2
  exit 0
fi

sudo dnf install --assumeyes python
