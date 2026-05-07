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

state_dir() {
  printf '%s/dist/%s\n' "${ROOT_DIR}" "${PROJECT}"
}

runtime_env_file() {
  printf '%s/runtime.env\n' "$(state_dir)"
}

ensure_dir() {
  mkdir -p "$1"
}

init_runtime_state() {
  ensure_dir "$(state_dir)"
  rm -rf "$(state_dir)/resolve"
  rm -rf "$(state_dir)/build"
  rm -rf "$(state_dir)/package"
  rm -rf "$(state_dir)/artifacts"
  rm -rf "$(state_dir)/plans"
  rm -rf "$(state_dir)/commands"
  rm -rf "$(state_dir)/tmp"
  rm -rf "$(state_dir)/private"
  rm -rf "$(state_dir)/public-diagnostics"
  rm -rf "$(state_dir)/releases"
  ensure_dir "$(state_dir)/resolve"
  ensure_dir "$(state_dir)/fetch"
  ensure_dir "$(state_dir)/build"
  ensure_dir "$(state_dir)/package"
  ensure_dir "$(state_dir)/artifacts"
  ensure_dir "$(state_dir)/plans"
  ensure_dir "$(state_dir)/commands"
  ensure_dir "$(state_dir)/tmp"
  : >"$(runtime_env_file)"
}

persist_env() {
  local name="$1"
  local value="$2"
  printf 'export %s=%q\n' "${name}" "${value}" >>"$(runtime_env_file)"
}

source_runtime_env() {
  local env_file
  env_file="$(runtime_env_file)"
  if [[ -f "${env_file}" ]]; then
    # shellcheck disable=SC1090
    source "${env_file}"
  fi
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "${value}"
}

copy_tree_into() {
  local src="$1"
  local dst="$2"
  [[ -d "${src}" ]] || return 0
  mkdir -p "${dst}"
  tar -C "${src}" -cf - . | tar -C "${dst}" -xf -
}
