# Human Onboarding

## Goal

Understand the product, decide whether a target upstream belongs here, and add a new project safely.

## Mental Model

- the repo is the control plane
- the project contract tells the system what to build
- the pipeline executes deterministic stages
- GitHub Actions is the remote execution environment
- the artifact, not the repo, is the delivered result

## First Read

1. `README.md`
2. `docs/scope.md`
3. `docs/architecture.md`
4. `docs/contracts.md`

## Core Loop

1. Create `projects/<name>/manifest.yaml`
2. Create `projects/<name>/build.profile.yaml`
3. Add any required patches or delivery overlays
4. Run `PROJECT=<name> ./scripts/run.sh`
5. Push and trigger the GitHub Actions workflow

After a GitHub Actions run, inspect the uploaded `dist/<project>/` artifact first. It is the structured diagnostic surface for later debugging.

## Where To Change What

- change docs and meaning in `docs/`
- change build stage behavior in `scripts/pipeline/`
- change packaging semantics in `delivery/`
- change runtime integration hooks in `scripts/hooks/`
- change per-upstream configuration in `projects/<name>/`
