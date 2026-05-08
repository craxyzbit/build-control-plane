#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/errors.sh"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/utils.sh"
source "${ROOT_DIR}/scripts/lib/openwrt.sh"

source_runtime_env

if [[ "${PROJECT}" != "openwrt" ]]; then
  log_info "Resolve stage placeholder: select upstream version and source coordinates"
  exit 0
fi

CHANNEL="$(openwrt_release_channel)"
if [[ "${CHANNEL}" == "stable" ]]; then
  require_env OPENWRT_VERSION
fi
VERSION="$(openwrt_release_version)"
BASE_URL="$(openwrt_release_base_url)"
SOURCE_GIT_URL="$(openwrt_source_git_url)"
SOURCE_REF_KIND="$(openwrt_source_ref_kind)"
SOURCE_REF="$(openwrt_source_ref)"

persist_env OPENWRT_CHANNEL "${CHANNEL}"
persist_env OPENWRT_VERSION "${VERSION}"
persist_env OPENWRT_BASE_URL "${BASE_URL}"
persist_env OPENWRT_SOURCE_GIT_URL "${SOURCE_GIT_URL}"
persist_env OPENWRT_SOURCE_REF_KIND "${SOURCE_REF_KIND}"
persist_env OPENWRT_SOURCE_REF "${SOURCE_REF}"

{
  printf 'project=%s\n' "${PROJECT}"
  printf 'openwrt_channel=%s\n' "${CHANNEL}"
  printf 'openwrt_version=%s\n' "${VERSION}"
  printf 'selected_targets=%s\n' "$(openwrt_selected_target_names | paste -sd ',' -)"
  printf 'release_base_url=%s\n' "${BASE_URL}"
  printf 'source_git_url=%s\n' "${SOURCE_GIT_URL}"
  printf 'source_ref_kind=%s\n' "${SOURCE_REF_KIND}"
  printf 'source_ref=%s\n' "${SOURCE_REF}"
} >"$(openwrt_plan_file resolved.env)"

while IFS= read -r target_name; do
  target_file="$(openwrt_target_file "${target_name}")"
  target_family="$(openwrt_yaml_scalar "${target_file}" "openwrt_target")"
  subtarget="$(openwrt_yaml_scalar "${target_file}" "openwrt_subtarget")"
  profile="$(openwrt_yaml_scalar "${target_file}" "profile")"
  arch="$(openwrt_yaml_scalar "${target_file}" "arch")"

  {
    printf 'TARGET_NAME=%q\n' "${target_name}"
    printf 'OPENWRT_TARGET=%q\n' "${target_family}"
    printf 'OPENWRT_SUBTARGET=%q\n' "${subtarget}"
    printf 'OPENWRT_PROFILE=%q\n' "${profile}"
    printf 'OPENWRT_ARCH=%q\n' "${arch}"
    printf 'TARGET_RELEASE_URL=%q\n' "${BASE_URL}/targets/${target_family}/${subtarget}"
  } >"$(openwrt_target_plan_path "${target_name}")"
done < <(openwrt_selected_target_names)

log_info "Resolved OpenWrt release inputs for version=${VERSION} channel=${CHANNEL}"
