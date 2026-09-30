# Workspace docs index

This repo (`mfe-workspace`) is the **orchestrator shell** only. Docs are split by ownership:

| Layer | Lives in | Contents |
|-------|----------|----------|
| Onboarding + mesh index | **this repo** — `README.md`, `docs/`, `plans/` | Clone/bootstrap, make targets, cross-cutting workspace plans |
| Platform / local mesh runbooks | `mfe-gateway/docs/` (after bootstrap) | Local development, architecture, e2e, Helm, deployment |
| Backend | `mfe-backend/docs/`, `mfe-backend/README.md` | API, DB, security, backend conventions |
| Feature / app plans | each `mfe-* /plans/` | Specs owned by that product repo |

## After bootstrap

- [Local development guide](../mfe-gateway/docs/local-development-guide.md)
- [System architecture](../mfe-gateway/docs/system-architecture.md)
- [Backend README](../mfe-backend/README.md)

Paths above resolve only once siblings are cloned (`./bootstrap.sh`).

## Writing new docs

- Mesh-wide “how do I run the polyrepo?” → root `README` / `docs/` / `plans/`
- nginx, e2e, Helm, standing platform guide → `mfe-gateway`
- One app or package feature → that app’s repo
