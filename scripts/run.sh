#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=scripts/lib/errors.sh
source "${ROOT_DIR}/scripts/lib/errors.sh"
# shellcheck source=scripts/lib/log.sh
source "${ROOT_DIR}/scripts/lib/log.sh"

PROJECT_NAME="${PROJECT:-unknown}"
LOG_DIR="${ROOT_DIR}/dist/${PROJECT_NAME}/logs"
rm -rf "${LOG_DIR}"
mkdir -p "${LOG_DIR}"

log_info "Starting pipeline for project=${PROJECT:-<unset>}"

for step in "${ROOT_DIR}"/scripts/pipeline/*.sh; do
  step_name="$(basename "$step" .sh)"
  step_log="${LOG_DIR}/${step_name}.log"
  log_info "Running stage=${step_name}"
  if bash "$step" 2>&1 | tee "${step_log}"; then
    log_info "Completed stage=${step_name}"
  else
    exit_with PIPELINE_STAGE_FAILED "Stage failed: ${step_name}. See ${step_log}"
  fi
done

log_info "Pipeline finished"
