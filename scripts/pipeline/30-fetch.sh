#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/errors.sh"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/utils.sh"
source "${ROOT_DIR}/scripts/lib/openwrt.sh"

source_runtime_env

if [[ "${PROJECT}" != "openwrt" ]]; then
  log_info "Fetch stage placeholder: download or clone upstream source"
  exit 0
fi

FETCH_PLAN="$(openwrt_plan_file fetch-plan.txt)"
SOURCE_GIT_URL="${OPENWRT_SOURCE_GIT_URL}"
SOURCE_REF="${OPENWRT_SOURCE_REF}"

{
  printf 'OpenWrt source fetch plan\n'
  printf 'git_url=%s\n' "${SOURCE_GIT_URL}"
  printf 'git_ref=%s\n' "${SOURCE_REF}"
  printf 'preferred_checkout_dir=%s\n' "$(state_dir)/fetch/openwrt"
  printf '\n'
  printf 'Target release bases:\n'
  while IFS= read -r target_name; do
    # shellcheck disable=SC1090
    source "$(openwrt_target_plan_path "${target_name}")"
    printf '%s -> %s\n' "${TARGET_NAME}" "${TARGET_RELEASE_URL}"
  done < <(openwrt_target_names)
} >"${FETCH_PLAN}"

if source_dir="$(openwrt_source_dir 2>/dev/null)"; then
  persist_env OPENWRT_EFFECTIVE_SOURCE_DIR "${source_dir}"
  log_info "Using OpenWrt source directory at ${source_dir}"
else
  log_warn "No local OpenWrt source tree found. Generated fetch plan only."
fi
