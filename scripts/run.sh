#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=scripts/lib/errors.sh
source "${ROOT_DIR}/scripts/lib/errors.sh"
# shellcheck source=scripts/lib/log.sh
source "${ROOT_DIR}/scripts/lib/log.sh"

log_info "Starting pipeline for project=${PROJECT:-<unset>}"

for step in "${ROOT_DIR}"/scripts/pipeline/*.sh; do
  bash "$step"
done

log_info "Pipeline finished"
