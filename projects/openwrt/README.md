# OpenWrt Project

This project defines a public, source-first OpenWrt image pipeline.

It is intentionally split into:

- public contracts that describe targets, build strategy, kernel capability requirements, and generic package layers
- private local extensions for operator-specific package choices or file overlays that should not be committed

## Why This Project Uses A Hybrid Build

Image Builder can inject packages and filesystem overlays, but it cannot change kernel configuration. Any target that requires custom eBPF-related kernel flags must start from a source build and then optionally use Image Builder style layering or post-processing.

## Public Inputs

- `manifest.yaml`
- `build.profile.yaml`
- `targets/*.yaml`
- `package-sets/*.txt`
- `files/common/`

## Private Extension Points

- `package-sets/private.extra.txt`
- `files/private/`
- `private-plan/private.plan.yaml`

Keep operator-sensitive runtime additions out of git history by using those private paths locally.

## Private Plan Input

`openwrt` consumes the repository-wide `PRIVATE_PLAN` capability with its own schema and its own parser behavior.

You can inject an OpenWrt private plan at runtime without committing it:

- local run: set `PRIVATE_PLAN_PATH`
- GitHub Actions: pass `private_plan_b64` in the `OpenWrt` workflow dispatch form

This is for non-secret operator preferences that should stay out of commit history. GitHub Actions inputs are still visible in run metadata, so do not use this path for credentials or true secrets.

This channel is also not the place for controversial or operator-sensitive runtime selections that should remain outside the public project story. Keep the public contract focused on broadly understandable build intent.

## Execution Modes

The OpenWrt pipeline supports three practical modes:

- planning only: generate plans, manifests, and runnable command scripts
- build execution: set `OPENWRT_EXECUTE_BUILD=true` and provide `OPENWRT_SOURCE_DIR`, or combine it with `OPENWRT_AUTO_FETCH=true`
- artifact collection: set `OPENWRT_EXECUTE_COLLECT=true` after or alongside build execution

The default mode is planning only. This keeps public CI safe by default while still allowing a fully automated source-tree run when the environment is ready.

## Target Selection

Use `OPENWRT_TARGETS` to narrow a run to one or more targets.

- local run: `OPENWRT_TARGETS=qemu-x86-64`
- GitHub Actions: use the `OpenWrt` workflow and its `openwrt_target` dispatch input

For the first real cloud test, prefer `qemu-x86-64`. It produces `ext4-combined.img.gz` first and then converts the raw image into `qcow2` during collection.
