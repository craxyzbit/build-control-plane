# Contracts

## Contract Types

### Project Identity Contract

File: `projects/<name>/manifest.yaml`

Purpose:

- defines project identity
- defines upstream source and resolver
- stays mostly static

### Build Profile Contract

File: `projects/<name>/build.profile.yaml`

Purpose:

- defines build command and output
- defines ABI profiles
- defines delivery targets
- changes with build strategy

## Bootstrap DSL

```yaml
project_request:
  name: example-tool
  upstream: https://github.com/example/tool
  resolver: github-release
  build:
    command: make build
    output: bin/tool
  targets:
    - debian-systemd
    - docker-scratch
```

## Error Contract

All hard failures should exit through `exit_with CODE "message"` and emit a stable error token.

Examples:

- `LOAD_PROJECT_UNSET`
- `FETCH_STRATEGY_UNSUPPORTED`
- `VERIFY_OUTPUT_MISSING`
