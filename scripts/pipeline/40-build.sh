#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/errors.sh"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/utils.sh"
source "${ROOT_DIR}/scripts/lib/openwrt.sh"

source_runtime_env

if [[ "${PROJECT}" != "openwrt" ]]; then
  log_info "Build stage placeholder: compile or assemble the core artifact"
  exit 0
fi

BUILD_PLAN="$(openwrt_plan_file build-plan.txt)"
OVERLAY_STAGING="$(state_dir)/tmp/files-overlay"
PIPELINE_COMMAND="$(openwrt_pipeline_command_file)"

rm -rf "${OVERLAY_STAGING}"
mkdir -p "${OVERLAY_STAGING}"

if [[ -d "$(openwrt_public_files_dir)" ]]; then
  copy_tree_into "$(openwrt_public_files_dir)" "${OVERLAY_STAGING}"
fi

if [[ -d "$(openwrt_private_files_dir)" ]]; then
  copy_tree_into "$(openwrt_private_files_dir)" "${OVERLAY_STAGING}"
fi

tar -C "${OVERLAY_STAGING}" -czf "$(openwrt_overlay_archive_path)" .

{
  printf 'OpenWrt build plan\n'
  printf 'overlay_archive=%s\n' "$(openwrt_overlay_archive_path)"
  printf 'host_tools=%s\n' "$(openwrt_host_tools | tr '\n' ',' | sed 's/,$//')"
} >"${BUILD_PLAN}"

while IFS= read -r target_name; do
  target_file="$(openwrt_target_file "${target_name}")"
  pkg_manifest="$(openwrt_package_manifest_path "${target_name}")"
  kernel_fragment="$(openwrt_kernel_fragment_path "${target_name}")"
  seed_config="$(openwrt_target_seed_config_path "${target_name}")"
  prepare_command="$(openwrt_prepare_command_file "${target_name}")"
  command_file="$(openwrt_command_file "build-${target_name}.sh")"
  # shellcheck disable=SC1090
  source "$(openwrt_target_plan_path "${target_name}")"
  target_family="$(openwrt_yaml_scalar "${target_file}" "openwrt_target")"
  subtarget="$(openwrt_yaml_scalar "${target_file}" "openwrt_subtarget")"
  profile="$(openwrt_yaml_scalar "${target_file}" "profile")"

  : >"${pkg_manifest}"
  while IFS= read -r package_set; do
    package_set="$(trim "${package_set}")"
    [[ -n "${package_set}" ]] || continue
    [[ -f "${package_set}" ]] || exit_with PACKAGE_SET_MISSING "Missing package set: ${package_set}"
    awk 'NF > 0 && $1 !~ /^#/' "${package_set}" >>"${pkg_manifest}"
  done < <(openwrt_package_set_paths)

  private_set="$(openwrt_private_package_set_path)"
  if [[ -f "${private_set}" ]]; then
    awk 'NF > 0 && $1 !~ /^#/' "${private_set}" >>"${pkg_manifest}"
  fi

  if [[ -n "${OPENWRT_PRIVATE_PLAN_FILE:-}" && -f "${OPENWRT_PRIVATE_PLAN_FILE}" ]]; then
    openwrt_private_plan_global_extra_packages "${OPENWRT_PRIVATE_PLAN_FILE}" >>"${pkg_manifest}" || true
    openwrt_private_plan_target_extra_packages "${OPENWRT_PRIVATE_PLAN_FILE}" "${target_name}" >>"${pkg_manifest}" || true
  fi

  sort -u -o "${pkg_manifest}" "${pkg_manifest}"

  : >"${kernel_fragment}"
  while IFS= read -r cfg; do
    cfg="$(trim "${cfg}")"
    [[ -n "${cfg}" ]] || continue
    printf '%s\n' "${cfg}" >>"${kernel_fragment}"
  done < <(openwrt_yaml_list "${target_file}" "required_config")

  {
    printf 'CONFIG_TARGET_%s=y\n' "${target_family}"
    printf 'CONFIG_TARGET_%s_%s=y\n' "${target_family}" "${subtarget}"
    openwrt_target_device_symbol "${target_family}" "${subtarget}" "${profile}"
    while IFS= read -r package_name; do
      package_name="$(trim "${package_name}")"
      [[ -n "${package_name}" ]] || continue
      openwrt_package_symbol "${package_name}"
    done <"${pkg_manifest}"
  } >"${seed_config}"

  {
    printf '#!/usr/bin/env bash\n'
    printf 'set -euo pipefail\n\n'
    printf 'SOURCE_DIR="${1:-%s}"\n' "${OPENWRT_EFFECTIVE_SOURCE_DIR:-}"
    printf 'if [[ -z "${SOURCE_DIR}" || ! -d "${SOURCE_DIR}" ]]; then\n'
    printf '  echo "OpenWrt source directory is required." >&2\n'
    printf '  exit 1\n'
    printf 'fi\n\n'
    printf 'cd "${SOURCE_DIR}"\n'
    printf 'rm -rf files\n'
    printf 'mkdir -p files\n'
    printf 'tar -C files -xzf "%s"\n' "$(openwrt_overlay_archive_path)"
    printf 'cat "%s" "%s" > .config\n' "${seed_config}" "${kernel_fragment}"
    printf './scripts/feeds update -a\n'
    printf './scripts/feeds install -a\n'
    printf 'make defconfig\n'
    printf 'echo "Prepared source tree for %s"\n' "${target_name}"
  } >"${prepare_command}"
  chmod +x "${prepare_command}"

  {
    printf '#!/usr/bin/env bash\n'
    printf 'set -euo pipefail\n\n'
    printf 'SOURCE_DIR="${1:-%s}"\n' "${OPENWRT_EFFECTIVE_SOURCE_DIR:-}"
    printf 'if [[ -z "${SOURCE_DIR}" || ! -d "${SOURCE_DIR}" ]]; then\n'
    printf '  echo "OpenWrt source directory is required." >&2\n'
    printf '  exit 1\n'
    printf 'fi\n\n'
    printf 'BUILD_JOBS="${BUILD_JOBS:-$(getconf _NPROCESSORS_ONLN 2>/dev/null || echo 4)}"\n'
    printf '"%s" "${SOURCE_DIR}"\n' "${prepare_command}"
    printf 'cd "${SOURCE_DIR}"\n'
    printf 'make -j"${BUILD_JOBS}"\n'
    printf 'echo "Build complete for %s"\n' "${target_name}"
  } >"${command_file}"
  chmod +x "${command_file}"

  {
    printf '\n[%s]\n' "${target_name}"
    printf 'release_url=%s\n' "${TARGET_RELEASE_URL:-unknown}"
    printf 'packages=%s\n' "${pkg_manifest}"
    printf 'kernel_fragment=%s\n' "${kernel_fragment}"
    printf 'seed_config=%s\n' "${seed_config}"
    printf 'prepare=%s\n' "${prepare_command}"
    printf 'command=%s\n' "${command_file}"
  } >>"${BUILD_PLAN}"
done < <(openwrt_target_names)

{
  printf '#!/usr/bin/env bash\n'
  printf 'set -euo pipefail\n\n'
  printf 'SOURCE_DIR="${1:-%s}"\n' "${OPENWRT_EFFECTIVE_SOURCE_DIR:-}"
  printf 'if [[ -z "${SOURCE_DIR}" || ! -d "${SOURCE_DIR}" ]]; then\n'
  printf '  echo "OpenWrt source directory is required." >&2\n'
  printf '  exit 1\n'
  printf 'fi\n\n'
  while IFS= read -r target_name; do
    printf '"%s" "${SOURCE_DIR}"\n' "$(openwrt_command_file "build-${target_name}.sh")"
  done < <(openwrt_target_names)
} >"${PIPELINE_COMMAND}"
chmod +x "${PIPELINE_COMMAND}"

log_info "Prepared OpenWrt build inputs and per-target command scripts"
