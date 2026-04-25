# Build Control Plane

An AI-native personal software delivery control plane.

This repository turns upstream projects into verified, installable artifacts through a contract-first workflow. The repo is the control plane. The artifact is the delivery unit.

## What This Repo Is

- Cognitive layer for humans and agents
- Execution layer for deterministic build steps
- Orchestration layer for GitHub Actions dispatch
- Delivery layer for packaging and runtime integration

## Core Principles

- build once -> package many
- contracts are first-class
- repo is control plane, not the collaboration surface
- artifact is the only delivery object
- keep structure explicit even when it costs some duplication

## Repository Layout

- `docs/`: architecture, contracts, glossary
- `scripts/`: pipeline, hooks, shared shell libs
- `delivery/`: nfpm and container delivery templates
- `projects/`: per-project contracts and overlays
- `.github/workflows/`: executable GitHub Actions workflows
- `workflows/`: orchestration contracts for humans and agents

## Operator Loop

1. Add `projects/<name>/manifest.yaml`
2. Add `projects/<name>/build.profile.yaml`
3. Run `scripts/run.sh`
4. Trigger GitHub Actions with the target project name

## Local Bootstrap

```bash
git init -b main
git add .
git commit -m "✨ feat: bootstrap build control plane"
```

## Next Remote Step

Create a same-name GitHub repository, add `origin`, and push `main` after local review.
