#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "${ROOT_DIR}/scripts/lib/errors.sh"
source "${ROOT_DIR}/scripts/lib/log.sh"
source "${ROOT_DIR}/scripts/lib/utils.sh"
source "${ROOT_DIR}/scripts/lib/openwrt.sh"

source_runtime_env

if [[ "${PROJECT}" != "openwrt" ]]; then
  log_info "Package stage placeholder: map the core artifact to delivery targets"
  exit 0
fi

PACKAGE_PLAN="$(openwrt_plan_file package-plan.txt)"

{
  printf 'OpenWrt packaging plan\n'
  printf 'artifact_root=%s\n' "$(state_dir)/artifacts"
} >"${PACKAGE_PLAN}"

while IFS= read -r target_name; do
  target_file="$(openwrt_target_file "${target_name}")"
  artifact_manifest="$(openwrt_artifact_manifest_path "${target_name}")"
  target_artifact_dir="$(state_dir)/artifacts/${target_name}"

  mkdir -p "${target_artifact_dir}"
  : >"${artifact_manifest}"
  while IFS= read -r artifact_name; do
    artifact_name="$(trim "${artifact_name}")"
    [[ -n "${artifact_name}" ]] || continue
    printf '%s\n' "${artifact_name}" >>"${artifact_manifest}"
  done < <(openwrt_target_expected_artifacts "${target_file}")

  if [[ "${target_name}" == "qemu-x86-64" ]]; then
    command_file="$(openwrt_command_file "convert-${target_name}-qcow2.sh")"
    {
      printf '#!/usr/bin/env bash\n'
      printf 'set -euo pipefail\n\n'
      printf 'RAW_IMAGE="${1:-}"\n'
      printf 'QCOW2_IMAGE="${2:-}"\n'
      printf 'if [[ -z "${RAW_IMAGE}" || -z "${QCOW2_IMAGE}" ]]; then\n'
      printf '  echo "Usage: %s <raw-image> <qcow2-image>" >&2\n' "convert-${target_name}-qcow2.sh"
      printf '  exit 1\n'
      printf 'fi\n'
      printf 'qemu-img convert -f raw -O qcow2 "${RAW_IMAGE}" "${QCOW2_IMAGE}"\n'
    } >"${command_file}"
    chmod +x "${command_file}"
  fi

  {
    printf '\n[%s]\n' "${target_name}"
    printf 'artifact_manifest=%s\n' "${artifact_manifest}"
    if [[ "${target_name}" == "qemu-x86-64" ]]; then
      printf 'qcow2_conversion=%s\n' "${command_file}"
    fi
  } >>"${PACKAGE_PLAN}"
done < <(openwrt_target_names)

log_info "Prepared OpenWrt packaging and conversion plans"
