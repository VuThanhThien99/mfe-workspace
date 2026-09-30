# Spec: mfe-workspace shell repo

**Status:** approved (Approach 1 — minimal)  
**Date:** 2026-09-30

## Problem

Root orchestrator (`Makefile`, `bootstrap.sh`, README) was unversioned ("local, no git"). Newcomers had no single clone entry; workspace docs/links drifted.

## Goals

- Version only the shell at `VuThanhThien99/mfe-workspace`
- Gitignore all sibling `mfe-*/` clones + heavy artifacts
- Onboarding: clone workspace → `./bootstrap.sh` → `make up`
- Independence: any `mfe-*` alone still works without this repo

## Non-goals

- Git submodules / subtrees
- Version lock file (keep `MFE_REF`, default `main`)
- Migrating existing sibling plans into root
- CI that boots full mesh

## Decisions

| Topic | Choice |
|-------|--------|
| Ignore strategy | Hybrid: denylist `mfe-*/` + artifacts |
| Remote | `VuThanhThien99/mfe-workspace` |
| Pinning | `MFE_REF` env only, default `main` |
| Docs ownership | Split: root index; gateway runbooks; apps own feature plans |

## Design

- Tracked: Makefile, bootstrap.sh, README, `.gitignore`, `docs/`, `plans/`, ignore configs useful at root
- Not tracked: `mfe-*/`, `repomix-output.*`, `.DS_Store`, `.env*`, `.vscode/`
- No code coupling from siblings to workspace path

## Success

1. Fresh clone of `mfe-workspace` has no nested product source
2. `./bootstrap.sh` populates siblings; `make check-repos` / `make up` work
3. `git status` at root never lists files inside `mfe-*`
4. Cloning only `mfe-backend` (etc.) unchanged

## Next

Implement files → `git init` → create GitHub repo → initial commit/push.
