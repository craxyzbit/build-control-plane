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

rm -rf "${OVERLAY_STAGING}"
mkdir -p "${OVERLAY_STAGING}"

if [[ -d "$(openwrt_public_files_dir)" ]]; then
  cp -R "$(openwrt_public_files_dir)"/. "${OVERLAY_STAGING}/"
fi

if [[ -d "$(openwrt_private_files_dir)" ]]; then
  cp -R "$(openwrt_private_files_dir)"/. "${OVERLAY_STAGING}/"
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
  command_file="$(openwrt_command_file "build-${target_name}.sh")"

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

  sort -u -o "${pkg_manifest}" "${pkg_manifest}"

  : >"${kernel_fragment}"
  while IFS= read -r cfg; do
    cfg="$(trim "${cfg}")"
    [[ -n "${cfg}" ]] || continue
    printf '%s\n' "${cfg}" >>"${kernel_fragment}"
  done < <(openwrt_yaml_list "${target_file}" "required_config")

  {
    printf '#!/usr/bin/env bash\n'
    printf 'set -euo pipefail\n\n'
    printf 'SOURCE_DIR="${1:-%s}"\n' "${OPENWRT_EFFECTIVE_SOURCE_DIR:-}"
    printf 'if [[ -z "${SOURCE_DIR}" || ! -d "${SOURCE_DIR}" ]]; then\n'
    printf '  echo "OpenWrt source directory is required." >&2\n'
    printf '  exit 1\n'
    printf 'fi\n\n'
    printf 'cp "%s" "${SOURCE_DIR}/.config.control-plane.%s"\n' "${kernel_fragment}" "${target_name}"
    printf 'cp "%s" "${SOURCE_DIR}/files-overlay.tgz"\n' "$(openwrt_overlay_archive_path)"
    printf 'cat <<'"'"'EOF'"'"'\n'
    printf 'Next steps inside the source tree:\n'
    printf '1. Select target/profile for %s\n' "${target_name}"
    printf '2. Merge package list from %s\n' "${pkg_manifest}"
    printf '3. Merge kernel config fragment from .config.control-plane.%s\n' "${target_name}"
    printf '4. Run feeds update/install, then make defconfig, then build\n'
    printf '5. Place produced images under dist/openwrt/artifacts/%s/\n' "${target_name}"
    printf 'EOF\n'
  } >"${command_file}"
  chmod +x "${command_file}"

  {
    printf '\n[%s]\n' "${target_name}"
    printf 'packages=%s\n' "${pkg_manifest}"
    printf 'kernel_fragment=%s\n' "${kernel_fragment}"
    printf 'command=%s\n' "${command_file}"
  } >>"${BUILD_PLAN}"
done < <(openwrt_target_names)

log_info "Prepared OpenWrt build inputs and per-target command scripts"
