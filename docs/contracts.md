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

### Target Contract

File: `projects/<name>/targets/<target>.yaml`

Purpose:

- defines platform-specific build backend
- defines required kernel capabilities
- defines target artifact expectations

### Package Set Contract

File: `projects/<name>/package-sets/*.txt`

Purpose:

- keeps package layering readable
- allows public and private package separation
- avoids mixing operator-specific runtime choices into shared history

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
