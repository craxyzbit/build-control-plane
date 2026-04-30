# Build Control Plane

An AI-native personal software delivery control plane.

This repository is a product, not just a pile of build scripts. It exists to turn upstream source code into verified artifacts when the upstream project does not cleanly ship what you need.

## What This Repo Is For

This framework is a good fit when one or more of these are true:

- the upstream project is open source but the distributed mobile app is paid
- upstream ships source code but does not ship prebuilt releases
- upstream requires special build flags or feature toggles
- you want to track latest or beta builds manually
- you need to adapt upstream for a specific platform yourself
- you want a personalized Dockerfile or image packaging path

## Product Model

The whole repository should be understandable as one product with two operator audiences:

- humans need a clear onboarding path, stable concepts, and explicit operating steps
- agents need small contracts, strict boundaries, and a directory layout that maps to system intent

The directory structure follows a cognitive architecture so both audiences can answer the same questions:

- what problem does this repo solve
- where does a decision belong
- where should a new project definition be added
- how does a contract flow into a delivered artifact

## Architecture

- Cognitive layer: repo meaning, onboarding, contracts, glossary
- Execution layer: deterministic build stages
- Orchestration layer: GitHub Actions as the execution environment
- Delivery layer: package and image outputs for target environments

Read [architecture.md](/Users/lixo/projects/build-control-plane/docs/architecture.md), [scope.md](/Users/lixo/projects/build-control-plane/docs/scope.md), and [onboarding-human.md](/Users/lixo/projects/build-control-plane/docs/onboarding-human.md) first.

## Shared Runtime Capabilities

- `PRIVATE_PLAN` is a repo-wide runtime injection channel for non-secret, non-committed customization.
- schemas are project-defined, not repo-global.
- `openwrt` is the first example consumer of this capability.
- `dist/<project>/` is runtime state, and GitHub Actions should publish it as a diagnostic artifact.

Read [private-plan.md](/Users/lixo/projects/build-control-plane/docs/private-plan.md) and [runtime-state.md](/Users/lixo/projects/build-control-plane/docs/runtime-state.md) for the runtime boundary.

## Repository Layout

- `docs/`: cognitive layer and onboarding
- `projects/`: per-project identity and build contracts
- `scripts/pipeline/`: execution-stage scripts
- `scripts/lib/`: shared execution helpers
- `scripts/hooks/`: target runtime integration hooks
- `delivery/`: delivery templates and packaging metadata
- `.github/workflows/`: executable GitHub Actions workflows
- `workflows/`: human-readable orchestration contracts

## Human Start Here

1. Read [scope.md](/Users/lixo/projects/build-control-plane/docs/scope.md)
2. Read [architecture.md](/Users/lixo/projects/build-control-plane/docs/architecture.md)
3. Follow [onboarding-human.md](/Users/lixo/projects/build-control-plane/docs/onboarding-human.md)

## Agent Start Here

1. Read [AGENTS.md](/Users/lixo/projects/build-control-plane/AGENTS.md)
2. Read [contracts.md](/Users/lixo/projects/build-control-plane/docs/contracts.md)
3. Follow [onboarding-agent.md](/Users/lixo/projects/build-control-plane/docs/onboarding-agent.md)
