# Glossary

- control plane: the repo that defines what to build and how to deliver it
- contract: a declarative file that agents and humans can both read safely
- artifact: the verified output delivered to an end environment
- execution layer: the shell pipeline that performs work
- orchestration layer: the CI system that dispatches the pipeline
- delivery layer: packaging and runtime integration metadata
- cognitive layer: repository documents that explain intent and boundaries
- build once -> package many: compile core output once, then adapt packaging per target
