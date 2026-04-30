#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/utils.sh"
source "${ROOT_DIR}/scripts/lib/openwrt.sh"

source_runtime_env

if [[ "${PROJECT}" != "openwrt" ]]; then
  log_info "Summary stage placeholder: emit structured build summary"
  exit 0
fi

SUMMARY_FILE="$(openwrt_plan_file summary.txt)"

{
  printf 'OpenWrt pipeline summary\n'
  printf 'project=%s\n' "${PROJECT}"
  printf 'version=%s\n' "${OPENWRT_VERSION:-<unset>}"
  printf 'channel=%s\n' "${OPENWRT_CHANNEL:-<unset>}"
  printf 'auto_fetch=%s\n' "${OPENWRT_AUTO_FETCH:-false}"
  printf 'execute_build=%s\n' "${OPENWRT_EXECUTE_BUILD:-false}"
  printf 'execute_collect=%s\n' "${OPENWRT_EXECUTE_COLLECT:-false}"
  printf 'state_dir=%s\n' "$(state_dir)"
  printf 'resolve_plan=%s\n' "$(openwrt_plan_file resolved.env)"
  printf 'fetch_plan=%s\n' "$(openwrt_plan_file fetch-plan.txt)"
  printf 'build_plan=%s\n' "$(openwrt_plan_file build-plan.txt)"
  printf 'package_plan=%s\n' "$(openwrt_plan_file package-plan.txt)"
  printf 'overlay_archive=%s\n' "$(openwrt_overlay_archive_path)"
} >"${SUMMARY_FILE}"

log_info "Wrote OpenWrt summary to ${SUMMARY_FILE}"
