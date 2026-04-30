# Runtime State

## What Lives In `dist/`

Files under `dist/` are runtime state, not repository contracts.

Examples:

- `dist/openwrt/plans/*.txt`
- `dist/openwrt/build/*.txt`
- `dist/openwrt/runtime.env`

These files are:

- generated per run
- safe to overwrite
- intentionally ignored by git
- allowed to differ between local test runs and GitHub Actions runs

Runtime state can also include materialized private plan files decoded or copied for one run. Those are execution artifacts, not repository contracts.

## What Counts As Real Contract

Long-lived project meaning belongs in tracked files such as:

- `projects/<name>/manifest.yaml`
- `projects/<name>/build.profile.yaml`
- `projects/<name>/targets/*.yaml`
- `projects/<name>/package-sets/*.txt`

## Version Example

If a local test run used `OPENWRT_VERSION=24.10.2`, that only describes that run. It does not redefine the repository's supported or preferred release line unless you update tracked project contracts.
