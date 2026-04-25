# Architecture

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

- Cognitive: README, AGENTS, docs, project contracts
- Delivery: packaging metadata, runtime hooks, container templates
- Orchestration: GitHub Actions dispatch, matrix, artifact upload
- Execution: shell pipeline, resolvers, fetch, build, verify

## Repository Mapping

- Cognitive: `README.md`, `AGENTS.md`, `docs/`, `projects/`
- Delivery: `delivery/`, `scripts/hooks/`
- Orchestration: `.github/workflows/`, `workflows/`
- Execution: `scripts/run.sh`, `scripts/pipeline/`, `scripts/lib/`

## Practical Note

The executable GitHub Actions workflow lives in `.github/workflows/` because that is what GitHub Actions requires. The logical orchestration contract is mirrored in `workflows/` for human and agent readability.
