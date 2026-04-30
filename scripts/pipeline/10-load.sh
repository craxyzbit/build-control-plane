#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/errors.sh"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/utils.sh"
source "${ROOT_DIR}/scripts/lib/openwrt.sh"

require_env PROJECT

PROJECT_DIR="$(project_dir)"
[[ -d "${PROJECT_DIR}" ]] || exit_with PROJECT_NOT_FOUND "Project directory not found: ${PROJECT_DIR}"
[[ -f "${PROJECT_DIR}/manifest.yaml" ]] || exit_with MANIFEST_MISSING "Missing manifest.yaml for ${PROJECT}"
[[ -f "${PROJECT_DIR}/build.profile.yaml" ]] || exit_with BUILD_PROFILE_MISSING "Missing build.profile.yaml for ${PROJECT}"

init_runtime_state
persist_env ROOT_DIR "${ROOT_DIR}"
persist_env PROJECT "${PROJECT}"
persist_env PROJECT_DIR "${PROJECT_DIR}"
persist_env STATE_DIR "$(state_dir)"

if [[ "${PROJECT}" == "openwrt" ]]; then
  if private_plan_file="$(openwrt_materialize_private_plan 2>/dev/null)"; then
    openwrt_private_plan_validate "${private_plan_file}"
    persist_env OPENWRT_PRIVATE_PLAN_FILE "${private_plan_file}"
    log_info "Loaded OpenWrt private plan into runtime state"
  fi
fi

log_info "Loaded project contract from ${PROJECT_DIR}"
