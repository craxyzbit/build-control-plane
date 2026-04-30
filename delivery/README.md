# Delivery Layer

The delivery layer is a set of optional backends, not a mandatory single tool.

Choose a delivery backend based on the artifact you want to ship:

- `nfpm/` for Linux package formats such as `.deb`, `.rpm`, or `.apk`
- `docker/` for container image packaging
- direct image outputs when the project itself already produces firmware or disk images

## About nFPM

`nFPM` is useful when a project's final output should become a Linux package.

It is not required for every project in this repository.

Examples:

- `openwrt` does not need `nFPM` for its main path because its primary outputs are firmware and disk images
- a standalone CLI binary project might use `nFPM` as its default delivery backend
