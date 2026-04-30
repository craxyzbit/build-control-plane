# Scope

## What Problems This Repo Solves

This repository exists for source-first delivery work where upstream does not already provide the exact artifact you need.

Typical fits:

- open-source projects whose official mobile app distribution is paid
- upstreams that publish source code but no prebuilt release artifacts
- builds that require custom flags, feature gates, or local patches
- workflows that manually track latest or beta upstream versions
- upstreams that need local adaptation for a specific platform
- projects that need a personalized Dockerfile and image packaging path

## What This Repo Is Not

This is not meant to be:

- a generic CI template for every software project
- a monorepo for unrelated product code
- a place where runtime-specific hacks leak back into build orchestration
- a substitute for upstream release engineering when upstream already ships exactly what you need

## Decision Rule

Use this control plane when contract clarity and artifact ownership matter more than minimizing repository ceremony.
