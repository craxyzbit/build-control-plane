#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/errors.sh"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/utils.sh"

require_env PROJECT

PROJECT_DIR="$(project_dir)"
[[ -d "${PROJECT_DIR}" ]] || exit_with PROJECT_NOT_FOUND "Project directory not found: ${PROJECT_DIR}"
[[ -f "${PROJECT_DIR}/manifest.yaml" ]] || exit_with MANIFEST_MISSING "Missing manifest.yaml for ${PROJECT}"
[[ -f "${PROJECT_DIR}/build.profile.yaml" ]] || exit_with BUILD_PROFILE_MISSING "Missing build.profile.yaml for ${PROJECT}"

log_info "Loaded project contract from ${PROJECT_DIR}"
