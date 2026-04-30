#!/usr/bin/env bash

openwrt_project_dir() {
  printf '%s/projects/openwrt\n' "${ROOT_DIR}"
}

openwrt_targets_dir() {
  printf '%s/targets\n' "$(openwrt_project_dir)"
}

openwrt_package_sets_dir() {
  printf '%s/package-sets\n' "$(openwrt_project_dir)"
}

openwrt_public_files_dir() {
  printf '%s/files/common\n' "$(openwrt_project_dir)"
}

openwrt_private_files_dir() {
  printf '%s/files/private\n' "$(openwrt_project_dir)"
}

openwrt_private_plan_schema_path() {
  printf '%s/private-plan/schema.yaml\n' "$(openwrt_project_dir)"
}

openwrt_private_plan_example_path() {
  printf '%s/private-plan/example.yaml\n' "$(openwrt_project_dir)"
}

openwrt_private_plan_repo_path() {
  printf '%s/private-plan/private.plan.yaml\n' "$(openwrt_project_dir)"
}

openwrt_yaml_scalar() {
  local file="$1"
  local key="$2"
  awk -F':' -v key="${key}" '
    $1 ~ "^[[:space:]]*" key "$" {
      sub(/^[[:space:]]+/, "", $2)
      sub(/[[:space:]]+$/, "", $2)
      gsub(/^"/, "", $2)
      gsub(/"$/, "", $2)
      print $2
      exit
    }
  ' "${file}"
}

openwrt_yaml_list() {
  local file="$1"
  local key="$2"
  awk -v key="${key}" '
    $0 ~ "^[[:space:]]*" key ":[[:space:]]*$" { in_list=1; next }
    in_list == 1 {
      if ($0 ~ "^[[:space:]]*-[[:space:]]*") {
        sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
        print $0
        next
      }
      if ($0 ~ "^[[:space:]]*$") next
      exit
    }
  ' "${file}"
}

openwrt_target_files() {
  find "$(openwrt_targets_dir)" -maxdepth 1 -type f -name '*.yaml' | sort
}

openwrt_target_names() {
  local file
  while IFS= read -r file; do
    basename "${file}" .yaml
  done < <(openwrt_target_files)
}

openwrt_target_file() {
  printf '%s/%s.yaml\n' "$(openwrt_targets_dir)" "$1"
}

openwrt_release_channel() {
  printf '%s' "${OPENWRT_CHANNEL:-stable}"
}

openwrt_release_version() {
  printf '%s' "${OPENWRT_VERSION:-}"
}

openwrt_release_series() {
  local version
  version="$(openwrt_release_version)"
  printf '%s' "${version%.*}"
}

openwrt_release_base_url() {
  local mirror channel version
  mirror="${OPENWRT_MIRROR:-https://downloads.openwrt.org}"
  channel="$(openwrt_release_channel)"
  version="$(openwrt_release_version)"
  case "${channel}" in
    stable)
      printf '%s/releases/%s\n' "${mirror}" "${version}"
      ;;
    snapshot)
      printf '%s/snapshots\n' "${mirror}"
      ;;
    *)
      exit_with OPENWRT_CHANNEL_UNSUPPORTED "Unsupported OPENWRT_CHANNEL=${channel}"
      ;;
  esac
}

openwrt_source_git_url() {
  printf '%s\n' "${OPENWRT_SOURCE_GIT_URL:-https://git.openwrt.org/openwrt/openwrt.git}"
}

openwrt_source_ref() {
  local channel series
  channel="$(openwrt_release_channel)"
  series="$(openwrt_release_series)"
  case "${channel}" in
    stable)
      printf 'openwrt-%s\n' "${series}"
      ;;
    snapshot)
      printf 'main\n'
      ;;
  esac
}

openwrt_plan_file() {
  printf '%s/plans/%s\n' "$(state_dir)" "$1"
}

openwrt_command_file() {
  printf '%s/commands/%s\n' "$(state_dir)" "$1"
}

openwrt_build_dir() {
  printf '%s/build\n' "$(state_dir)"
}

openwrt_package_set_paths() {
  local file
  while IFS= read -r file; do
    printf '%s/%s\n' "$(openwrt_project_dir)" "$(trim "${file}")"
  done < <(openwrt_yaml_list "$(openwrt_project_dir)/build.profile.yaml" "public_sets")
}

openwrt_private_package_set_path() {
  printf '%s/%s\n' "$(openwrt_project_dir)" "$(openwrt_yaml_scalar "$(openwrt_project_dir)/build.profile.yaml" "private_optional_set")"
}

openwrt_host_tools() {
  openwrt_yaml_list "$(openwrt_project_dir)/build.profile.yaml" "host_tools"
}

openwrt_kernel_fragment_path() {
  printf '%s/kernel-config-%s.fragment\n' "$(openwrt_build_dir)" "$1"
}

openwrt_package_manifest_path() {
  printf '%s/packages-%s.txt\n' "$(openwrt_build_dir)" "$1"
}

openwrt_target_plan_path() {
  printf '%s/resolve/target-%s.env\n' "$(state_dir)" "$1"
}

openwrt_artifact_manifest_path() {
  printf '%s/artifacts/manifest-%s.txt\n' "$(state_dir)" "$1"
}

openwrt_overlay_archive_path() {
  printf '%s/files-overlay.tgz\n' "$(openwrt_build_dir)"
}

openwrt_runtime_private_dir() {
  printf '%s/private\n' "$(state_dir)"
}

openwrt_runtime_private_plan_path() {
  printf '%s/private/private-plan.yaml\n' "$(state_dir)"
}

openwrt_source_dir() {
  if [[ -n "${OPENWRT_SOURCE_DIR:-}" ]]; then
    printf '%s\n' "${OPENWRT_SOURCE_DIR}"
    return 0
  fi

  if [[ -d "$(state_dir)/fetch/openwrt" ]]; then
    printf '%s/fetch/openwrt\n' "$(state_dir)"
    return 0
  fi

  return 1
}

openwrt_target_expected_artifacts() {
  local file="$1"
  awk '
    $0 ~ "^[[:space:]]*artifacts:[[:space:]]*$" { in_artifacts=1; next }
    in_artifacts == 1 && $0 ~ "^[[:space:]]*notes:[[:space:]]*$" { exit }
    in_artifacts == 1 && $0 ~ "^[[:space:]]*(primary|optional|derived):[[:space:]]*$" { in_list=1; next }
    in_artifacts == 1 && in_list == 1 {
      if ($0 ~ "^[[:space:]]*-[[:space:]]*") {
        sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
        print $0
        next
      }
      if ($0 ~ "^[[:space:]]*$") next
      if ($0 ~ "^[[:space:]]*(primary|optional|derived):[[:space:]]*$") next
      if ($0 !~ "^[[:space:]]") exit
    }
  ' "${file}"
}

openwrt_private_plan_source_path() {
  if [[ -n "${OPENWRT_PRIVATE_PLAN_PATH:-}" ]]; then
    printf '%s\n' "${OPENWRT_PRIVATE_PLAN_PATH}"
    return 0
  fi

  if [[ -f "$(openwrt_private_plan_repo_path)" ]]; then
    printf '%s\n' "$(openwrt_private_plan_repo_path)"
    return 0
  fi

  return 1
}

openwrt_decode_private_plan_b64() {
  local output_path="$1"
  [[ -n "${OPENWRT_PRIVATE_PLAN_B64:-}" ]] || return 1

  if command -v base64 >/dev/null 2>&1; then
    printf '%s' "${OPENWRT_PRIVATE_PLAN_B64}" | base64 --decode >"${output_path}" 2>/dev/null \
      || printf '%s' "${OPENWRT_PRIVATE_PLAN_B64}" | base64 -D >"${output_path}" 2>/dev/null
    return $?
  fi

  exit_with PRIVATE_PLAN_BASE64_UNAVAILABLE "base64 command is required to decode OPENWRT_PRIVATE_PLAN_B64"
}

openwrt_materialize_private_plan() {
  local runtime_dir runtime_file source_path
  runtime_dir="$(openwrt_runtime_private_dir)"
  runtime_file="$(openwrt_runtime_private_plan_path)"
  mkdir -p "${runtime_dir}"

  if [[ -n "${OPENWRT_PRIVATE_PLAN_B64:-}" ]]; then
    openwrt_decode_private_plan_b64 "${runtime_file}" \
      || exit_with PRIVATE_PLAN_DECODE_FAILED "Failed to decode OPENWRT_PRIVATE_PLAN_B64"
    printf '%s\n' "${runtime_file}"
    return 0
  fi

  if source_path="$(openwrt_private_plan_source_path 2>/dev/null)"; then
    [[ -f "${source_path}" ]] || exit_with PRIVATE_PLAN_MISSING "Private plan not found: ${source_path}"
    cp "${source_path}" "${runtime_file}"
    printf '%s\n' "${runtime_file}"
    return 0
  fi

  return 1
}

openwrt_private_plan_validate() {
  local file="$1"
  local version kind
  version="$(openwrt_yaml_scalar "${file}" "version")"
  kind="$(openwrt_yaml_scalar "${file}" "kind")"
  [[ "${version}" == "1" ]] || exit_with PRIVATE_PLAN_VERSION_UNSUPPORTED "Unsupported private plan version: ${version:-<unset>}"
  [[ "${kind}" == "openwrt-private-plan" ]] || exit_with PRIVATE_PLAN_KIND_INVALID "Unexpected private plan kind: ${kind:-<unset>}"
}

openwrt_private_plan_global_extra_packages() {
  local file="$1"
  awk '
    $0 ~ "^[[:space:]]*global:[[:space:]]*$" { in_global=1; next }
    in_global == 1 && $0 ~ "^[[:space:]]*targets:[[:space:]]*$" { exit }
    in_global == 1 && $0 ~ "^[[:space:]]*extra_packages:[[:space:]]*$" { in_list=1; next }
    in_global == 1 && in_list == 1 {
      if ($0 ~ "^[[:space:]]*-[[:space:]]*") {
        sub(/^[[:space:]]*-[[:space:]]*/, "", $0)
        print $0
        next
      }
      if ($0 ~ "^[[:space:]]*$") next
      if ($0 !~ "^[[:space:]]{4}") exit
    }
  ' "${file}"
}

openwrt_private_plan_target_extra_packages() {
  local file="$1"
  local target_name="$2"
  awk -v target="${target_name}" '
    $0 ~ "^[[:space:]]*targets:[[:space:]]*$" { in_targets=1; next }
    in_targets == 1 && $0 ~ "^[[:space:]]{2}" target ":[[:space:]]*$" { in_target=1; next }
    in_targets == 1 && in_target == 1 && $0 ~ "^[[:space:]]{2}[A-Za-z0-9_.-]+:[[:space:]]*$" { exit }
    in_target == 1 && $0 ~ "^[[:space:]]{4}extra_packages:[[:space:]]*$" { in_list=1; next }
    in_target == 1 && in_list == 1 {
      if ($0 ~ "^[[:space:]]{6}-[[:space:]]*") {
        sub(/^[[:space:]]{6}-[[:space:]]*/, "", $0)
        print $0
        next
      }
      if ($0 ~ "^[[:space:]]*$") next
      if ($0 !~ "^[[:space:]]{6}") exit
    }
  ' "${file}"
}
