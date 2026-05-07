#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/errors.sh"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/utils.sh"
source "${ROOT_DIR}/scripts/lib/openwrt.sh"

source_runtime_env

if [[ "${PROJECT}" != "openwrt" ]]; then
  log_info "Verify stage placeholder: validate artifact integrity and metadata"
  exit 0
fi

[[ -f "$(openwrt_plan_file resolved.env)" ]] || exit_with VERIFY_RESOLVE_PLAN_MISSING "Missing resolve plan"
[[ -f "$(openwrt_plan_file fetch-plan.txt)" ]] || exit_with VERIFY_FETCH_PLAN_MISSING "Missing fetch plan"
[[ -f "$(openwrt_plan_file build-plan.txt)" ]] || exit_with VERIFY_BUILD_PLAN_MISSING "Missing build plan"
[[ -f "$(openwrt_plan_file package-plan.txt)" ]] || exit_with VERIFY_PACKAGE_PLAN_MISSING "Missing package plan"
[[ -f "$(openwrt_overlay_archive_path)" ]] || exit_with VERIFY_OVERLAY_ARCHIVE_MISSING "Missing overlay archive"

if openwrt_should_execute_build && ! openwrt_should_execute_collect; then
  log_warn "Build execution was enabled without artifact collection"
fi

while IFS= read -r target_name; do
  [[ -f "$(openwrt_package_manifest_path "${target_name}")" ]] || exit_with VERIFY_PACKAGE_MANIFEST_MISSING "Missing package manifest for ${target_name}"
  [[ -f "$(openwrt_kernel_fragment_path "${target_name}")" ]] || exit_with VERIFY_KERNEL_FRAGMENT_MISSING "Missing kernel fragment for ${target_name}"
  [[ -f "$(openwrt_artifact_manifest_path "${target_name}")" ]] || exit_with VERIFY_ARTIFACT_MANIFEST_MISSING "Missing artifact manifest for ${target_name}"

  artifact_dir="$(state_dir)/artifacts/${target_name}"
  if [[ ! -d "${artifact_dir}" ]]; then
    log_warn "Artifact directory not found for ${target_name}: ${artifact_dir}"
    continue
  fi

  while IFS= read -r artifact_name; do
    artifact_name="$(trim "${artifact_name}")"
    [[ -n "${artifact_name}" ]] || continue
    if ! find "${artifact_dir}" -maxdepth 1 -type f -name "*${artifact_name}" | grep -q .; then
      if openwrt_should_execute_collect; then
        exit_with VERIFY_ARTIFACT_MISSING "Expected artifact missing after collection for ${target_name}: ${artifact_name}"
      fi
      log_warn "Expected artifact not present yet for ${target_name}: ${artifact_name}"
    fi
  done <"$(openwrt_artifact_manifest_path "${target_name}")"
done < <(openwrt_selected_target_names)

log_info "Verified OpenWrt pipeline plans and generated inputs"
