#!/usr/bin/env bash

exit_with() {
  local code="$1"
  shift
  echo "[E-${code}] $*" >&2
  exit 1
}
