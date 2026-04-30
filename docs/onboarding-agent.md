# Agent Onboarding

## Goal

Acquire enough context to make safe repository changes without collapsing layer boundaries.

## Required Read Order

1. `AGENTS.md`
2. `docs/contracts.md`
3. `docs/architecture.md`
4. target files under `projects/<name>/`

## Working Rules

- preserve semantic directory intent
- prefer small contract edits over broad shared-template edits
- keep orchestration thin
- keep target-specific behavior out of execution and orchestration
- use structured errors for new failure paths

## Default Change Heuristics

- if the change affects meaning, scope, or onboarding, edit `docs/` or top-level entry files
- if the change affects build sequencing, edit `scripts/pipeline/`
- if the change affects packaging targets, edit `delivery/`
- if the change affects one upstream only, prefer `projects/<name>/`

## Minimum Safe Path For A New Upstream

1. add `manifest.yaml`
2. add `build.profile.yaml`
3. add patches only if the upstream contract requires them
4. verify local pipeline entry with `PROJECT=<name> ./scripts/run.sh`
