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

You can also inject a private plan at runtime without committing it:

- local run: set `OPENWRT_PRIVATE_PLAN_PATH`
- GitHub Actions: pass `openwrt_private_plan_b64` in `workflow_dispatch`

This is for non-secret operator preferences that should stay out of commit history. GitHub Actions inputs are still visible in run metadata, so do not use this path for credentials or true secrets.
