# AGENTS.md

## Purpose

This repository is an AI-native software delivery control plane.

It should be treated as a product with explicit cognitive structure, not as an undifferentiated shell repo.

## Safe Modification Rules

- Never mix lifecycle hooks into pipeline scripts.
- Never place target-specific logic into orchestration.
- Prefer overlays or target files over editing shared templates.
- Keep contracts small and explicit.
- Preserve onboarding quality for both human and agent readers.

## Architecture Boundaries

- Cognitive = documentation and operator contracts
- Execution = build and verification stages
- Orchestration = CI dispatch and job wiring
- Delivery = package metadata and runtime integration

## Task Fit

Prefer this repo for upstreams where artifact generation needs operator control:

- source available, but no usable upstream release artifacts
- manual latest or beta tracking
- custom build flags or feature gates
- platform-specific adaptation
- personalized container image packaging
- commercial distribution exists upstream, but source remains buildable

Avoid stretching the repo into a general-purpose CI template. The focus is controlled artifact production from source contracts.

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

## Onboarding Contract

When adding or reshaping repository structure, keep these entry paths intact:

- human entry: `README.md` -> `docs/scope.md` -> `docs/onboarding-human.md`
- agent entry: `AGENTS.md` -> `docs/contracts.md` -> `docs/onboarding-agent.md`

## Guardrails

- Structured error codes are mandatory for failures.
- Stage order is fixed unless the repository contract changes.
- GitHub Actions should only dispatch, never absorb build logic.
