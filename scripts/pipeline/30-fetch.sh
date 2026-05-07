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
FETCH_DIR="$(state_dir)/fetch/openwrt"
FETCH_COMMAND="$(openwrt_fetch_command_file)"

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
  done < <(openwrt_selected_target_names)
} >"${FETCH_PLAN}"

{
  printf '#!/usr/bin/env bash\n'
  printf 'set -euo pipefail\n\n'
  printf 'SOURCE_DIR="${1:-%s}"\n' "${FETCH_DIR}"
  printf 'GIT_URL="%s"\n' "${SOURCE_GIT_URL}"
  printf 'GIT_REF="%s"\n\n' "${SOURCE_REF}"
  printf 'if [[ ! -d "${SOURCE_DIR}/.git" ]]; then\n'
  printf '  mkdir -p "$(dirname "${SOURCE_DIR}")"\n'
  printf '  git clone "${GIT_URL}" "${SOURCE_DIR}"\n'
  printf 'fi\n'
  printf 'git -C "${SOURCE_DIR}" fetch --tags origin\n'
  printf 'git -C "${SOURCE_DIR}" checkout "${GIT_REF}"\n'
  printf 'git -C "${SOURCE_DIR}" pull --ff-only origin "${GIT_REF}" || true\n'
  printf 'echo "OpenWrt source ready at ${SOURCE_DIR}"\n'
} >"${FETCH_COMMAND}"
chmod +x "${FETCH_COMMAND}"

if source_dir="$(openwrt_source_dir 2>/dev/null)"; then
  persist_env OPENWRT_EFFECTIVE_SOURCE_DIR "${source_dir}"
  log_info "Using OpenWrt source directory at ${source_dir}"
elif [[ "${OPENWRT_AUTO_FETCH:-false}" == "true" || "${OPENWRT_AUTO_FETCH:-0}" == "1" ]]; then
  "${FETCH_COMMAND}"
  source_dir="$(openwrt_source_dir)"
  persist_env OPENWRT_EFFECTIVE_SOURCE_DIR "${source_dir}"
  log_info "Fetched OpenWrt source directory at ${source_dir}"
else
  log_warn "No local OpenWrt source tree found. Generated fetch plan only."
fi
