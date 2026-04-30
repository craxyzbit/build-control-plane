# Architecture

## Philosophy To Structure

This repository uses semantic structure on purpose. The directory tree is not only for file placement. It is the cognitive map of the product.

The goal is that a human operator and an AI agent can both infer:

- what this repo does
- what layer a change belongs to
- where to start onboarding
- how a project contract becomes an artifact

## Four Layers

```text
┌──────────────────────────────┐
│ 4. Cognitive Layer          │
├──────────────────────────────┤
│ 3. Delivery Layer           │
├──────────────────────────────┤
│ 2. Orchestration Layer      │
├──────────────────────────────┤
│ 1. Execution Layer          │
└──────────────────────────────┘
```

## Layer Boundaries

- Cognitive: meaning, scope, onboarding, glossary, contracts
- Delivery: packaging metadata, runtime hooks, image templates
- Orchestration: GitHub Actions dispatch, matrix, artifact upload
- Execution: shell pipeline, resolvers, fetch, build, verify

## Repository Mapping

- Cognitive: `README.md`, `AGENTS.md`, `docs/`, `projects/`
- Delivery: `delivery/`, `scripts/hooks/`
- Orchestration: `.github/workflows/`, `workflows/`
- Execution: `scripts/run.sh`, `scripts/pipeline/`, `scripts/lib/`

## Audience-Specific Entry Points

- Humans begin from product meaning, task fit, and step-by-step operation.
- Agents begin from constraints, contracts, and modification boundaries.

That is why this repo keeps both `README.md` and `AGENTS.md`, and why `docs/` should contain explicit onboarding for both audiences.

## Practical Note

The executable GitHub Actions workflow lives in `.github/workflows/` because GitHub requires it there. The logical orchestration contract is mirrored in `workflows/` so the orchestration layer remains readable as architecture, not just CI syntax.
