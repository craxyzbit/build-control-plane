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
PUBLIC_DIAGNOSTICS_DIR="$(openwrt_public_diagnostics_dir)"
PUBLIC_SUMMARY_FILE="${PUBLIC_DIAGNOSTICS_DIR}/summary.txt"
PUBLIC_README_FILE="${PUBLIC_DIAGNOSTICS_DIR}/README.txt"
PUBLIC_LOGS_DIR="${PUBLIC_DIAGNOSTICS_DIR}/logs"

mkdir -p "${PUBLIC_DIAGNOSTICS_DIR}"
mkdir -p "${PUBLIC_LOGS_DIR}"

{
  printf 'OpenWrt pipeline summary\n'
  printf 'project=%s\n' "${PROJECT}"
  printf 'version=%s\n' "${OPENWRT_VERSION:-<unset>}"
  printf 'channel=%s\n' "${OPENWRT_CHANNEL:-<unset>}"
  printf 'selected_targets=%s\n' "$(openwrt_selected_target_names | paste -sd ',' -)"
  printf 'auto_fetch=%s\n' "${OPENWRT_AUTO_FETCH:-false}"
  printf 'execute_build=%s\n' "${OPENWRT_EXECUTE_BUILD:-false}"
  printf 'execute_collect=%s\n' "${OPENWRT_EXECUTE_COLLECT:-false}"
  printf 'runtime_state_root=dist/%s\n' "${PROJECT}"
  printf 'resolve_plan=dist/%s/plans/resolved.env\n' "${PROJECT}"
  printf 'fetch_plan=dist/%s/plans/fetch-plan.txt\n' "${PROJECT}"
  printf 'build_plan=dist/%s/plans/build-plan.txt\n' "${PROJECT}"
  printf 'package_plan=dist/%s/plans/package-plan.txt\n' "${PROJECT}"
  printf 'public_diagnostics=dist/%s/public-diagnostics\n' "${PROJECT}"
} >"${SUMMARY_FILE}"

cp "${SUMMARY_FILE}" "${PUBLIC_SUMMARY_FILE}"

{
  printf 'Public diagnostics bundle\n'
  printf '\n'
  printf 'This bundle is intentionally minimal for public repositories.\n'
  printf 'It excludes private plan materializations, generated package manifests,\n'
  printf 'generated command scripts, private runtime files, and full local state.\n'
  printf '\n'
  printf 'Use the local dist tree or a private environment for deeper debugging.\n'
} >"${PUBLIC_README_FILE}"

for stage_log in 20-resolve 30-fetch 60-verify 90-summary; do
  log_path="$(state_dir)/logs/${stage_log}.log"
  if [[ -f "${log_path}" ]]; then
    cp "${log_path}" "${PUBLIC_LOGS_DIR}/${stage_log}.log"
  fi
done

log_info "Wrote OpenWrt summary to ${SUMMARY_FILE}"
