# Private Plan

## Purpose

`PRIVATE_PLAN` is a repository-wide runtime injection capability.

It exists to let an operator pass non-secret, non-committed customization into a pipeline run without changing tracked contracts.

## What It Is For

Good uses:

- extra public packages that are optional for one run
- target-specific operator preferences that are not worth committing
- temporary runtime customization for testing or one-off packaging

## What It Is Not For

Do not use `PRIVATE_PLAN` for:

- credentials, tokens, keys, or secrets
- legally or socially sensitive runtime selections
- controversial plugin choices that should stay outside the public project story
- long-lived project behavior that should really become a tracked contract

## Scope

The capability is global to the repository, but the schema is project-defined.

That means:

- the runtime channel is shared: `PRIVATE_PLAN_PATH` or `PRIVATE_PLAN_B64`
- the content schema belongs to the selected project
- `openwrt` is only the first concrete example, not the definition of the feature

## Delivery Paths

- local run: set `PRIVATE_PLAN_PATH`
- GitHub Actions: pass `private_plan_b64` in `workflow_dispatch`

## Safety Note

`workflow_dispatch` inputs do not affect commit history, but they are still visible in GitHub Actions run metadata. Treat this as a convenience channel for non-secret operator preferences, not a secret transport.
