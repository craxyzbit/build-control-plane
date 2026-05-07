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
RELEASE_DIR="$(openwrt_release_artifact_dir)"
COLLECT_PIPELINE_COMMAND="$(openwrt_collect_pipeline_command_file)"

{
  printf 'OpenWrt packaging plan\n'
  printf 'artifact_root=%s\n' "$(state_dir)/artifacts"
  printf 'release_artifact_dir=%s\n' "${RELEASE_DIR}"
} >"${PACKAGE_PLAN}"

while IFS= read -r target_name; do
  target_file="$(openwrt_target_file "${target_name}")"
  artifact_manifest="$(openwrt_artifact_manifest_path "${target_name}")"
  target_artifact_dir="$(state_dir)/artifacts/${target_name}"
  collect_command="$(openwrt_collect_command_file "${target_name}")"
  collect_log="$(openwrt_collect_log_path "${target_name}")"
  artifact_report="$(openwrt_artifact_report_path "${target_name}")"
  # shellcheck disable=SC1090
  source "$(openwrt_target_plan_path "${target_name}")"

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
    printf '#!/usr/bin/env bash\n'
    printf 'set -euo pipefail\n\n'
    printf 'SOURCE_DIR="${1:-%s}"\n' "${OPENWRT_EFFECTIVE_SOURCE_DIR:-}"
    printf 'ARTIFACT_DIR="%s"\n' "${target_artifact_dir}"
    printf 'LOG_FILE="%s"\n' "${collect_log}"
    printf 'REPORT_FILE="%s"\n' "${artifact_report}"
    printf 'TARGET_BIN="${SOURCE_DIR}/bin/targets/%s/%s"\n' "${OPENWRT_TARGET}" "${OPENWRT_SUBTARGET}"
    printf 'mkdir -p "$(dirname "${LOG_FILE}")"\n'
    printf 'exec > >(tee -a "${LOG_FILE}") 2>&1\n'
    printf 'mkdir -p "${ARTIFACT_DIR}"\n'
    printf 'if [[ ! -d "${TARGET_BIN}" ]]; then\n'
    printf '  echo "Target output directory not found: ${TARGET_BIN}" >&2\n'
    printf '  exit 1\n'
    printf 'fi\n'
    printf 'while IFS= read -r artifact_name; do\n'
    printf '  match="$(find "${TARGET_BIN}" -maxdepth 1 -type f -name "*${artifact_name}" | head -n 1 || true)"\n'
    printf '  if [[ -n "${match}" ]]; then\n'
    printf '    cp "${match}" "${ARTIFACT_DIR}/"\n'
    printf '  fi\n'
    printf 'done < "%s"\n' "${artifact_manifest}"
    if [[ "${target_name}" == "qemu-x86-64" ]]; then
      printf 'RAW_IMAGE="$(find "${ARTIFACT_DIR}" -maxdepth 1 -type f \\( -name "*combined*.img" -o -name "*combined*.img.gz" \\) | head -n 1 || true)"\n'
      printf 'if [[ -n "${RAW_IMAGE}" && "${RAW_IMAGE}" == *.gz ]]; then\n'
      printf '  gunzip -kf "${RAW_IMAGE}"\n'
      printf '  RAW_IMAGE="${RAW_IMAGE%%.gz}"\n'
      printf 'fi\n'
      printf 'if [[ -n "${RAW_IMAGE}" ]]; then\n'
      printf '  "%s" "${RAW_IMAGE}" "${ARTIFACT_DIR}/%s.qcow2"\n' "${command_file}" "${target_name}"
      printf 'fi\n'
    fi
    printf ': > "${REPORT_FILE}"\n'
    printf 'for artifact in "${ARTIFACT_DIR}"/*; do\n'
    printf '  [[ -f "${artifact}" ]] || continue\n'
    printf '  echo "file=$(basename "${artifact}")" >> "${REPORT_FILE}"\n'
    printf '  echo "size_bytes=$(wc -c < "${artifact}" | tr -d \" \")" >> "${REPORT_FILE}"\n'
    printf '  if command -v sha256sum >/dev/null 2>&1; then\n'
    printf '    echo "sha256=$(sha256sum "${artifact}" | awk '"'"'{print $1}'"'"')" >> "${REPORT_FILE}"\n'
    printf '  elif command -v shasum >/dev/null 2>&1; then\n'
    printf '    echo "sha256=$(shasum -a 256 "${artifact}" | awk '"'"'{print $1}'"'"')" >> "${REPORT_FILE}"\n'
    printf '  fi\n'
    printf '  echo >> "${REPORT_FILE}"\n'
    printf 'done\n'
  } >"${collect_command}"
  chmod +x "${collect_command}"

  {
    printf '\n[%s]\n' "${target_name}"
    printf 'artifact_manifest=%s\n' "${artifact_manifest}"
    printf 'collect=%s\n' "${collect_command}"
    printf 'collect_log=%s\n' "${collect_log}"
    printf 'artifact_report=%s\n' "${artifact_report}"
    if [[ "${target_name}" == "qemu-x86-64" ]]; then
      printf 'qcow2_conversion=%s\n' "${command_file}"
    fi
  } >>"${PACKAGE_PLAN}"
done < <(openwrt_selected_target_names)

{
  printf '#!/usr/bin/env bash\n'
  printf 'set -euo pipefail\n\n'
  printf 'SOURCE_DIR="${1:-%s}"\n' "${OPENWRT_EFFECTIVE_SOURCE_DIR:-}"
  printf 'if [[ -z "${SOURCE_DIR}" || ! -d "${SOURCE_DIR}" ]]; then\n'
  printf '  echo "OpenWrt source directory is required." >&2\n'
  printf '  exit 1\n'
  printf 'fi\n\n'
  while IFS= read -r target_name; do
    printf '"%s" "${SOURCE_DIR}"\n' "$(openwrt_collect_command_file "${target_name}")"
  done < <(openwrt_selected_target_names)
} >"${COLLECT_PIPELINE_COMMAND}"
chmod +x "${COLLECT_PIPELINE_COMMAND}"

if openwrt_should_execute_collect; then
  if ! source_dir="$(openwrt_source_dir 2>/dev/null)"; then
    exit_with OPENWRT_SOURCE_DIR_REQUIRED "OPENWRT_EXECUTE_COLLECT requires OPENWRT_SOURCE_DIR or OPENWRT_AUTO_FETCH=true"
  fi

  log_info "Collecting OpenWrt build artifacts from ${source_dir}"
  "${COLLECT_PIPELINE_COMMAND}" "${source_dir}"
fi

log_info "Prepared OpenWrt packaging and conversion plans"
