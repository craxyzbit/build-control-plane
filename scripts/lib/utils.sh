#!/usr/bin/env bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    exit_with "${name}_UNSET" "Required environment variable '${name}' is not set"
  fi
}

project_dir() {
  printf '%s/projects/%s\n' "${ROOT_DIR}" "${PROJECT}"
}
