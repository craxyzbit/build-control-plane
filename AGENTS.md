# AGENTS.md

## Purpose

This repository is an AI-native software delivery control plane.

## Safe Modification Rules

- Never mix lifecycle hooks into pipeline scripts.
- Never place target-specific logic into orchestration.
- Prefer overlays or target files over editing shared templates.
- Keep contracts small and explicit.

## Architecture Boundaries

- Cognitive = documentation and operator contracts
- Execution = build and verification stages
- Orchestration = CI dispatch and job wiring
- Delivery = package metadata and runtime integration

## Adding A Project

Required inputs:

- upstream URL
- resolver strategy
- build command
- output artifact path
- delivery targets

Generate:

- `projects/<name>/manifest.yaml`
- `projects/<name>/build.profile.yaml`

## Guardrails

- Structured error codes are mandatory for failures.
- Stage order is fixed unless the repository contract changes.
- GitHub Actions should only dispatch, never absorb build logic.
