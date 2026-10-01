# mfe-workspace

Thin orchestrator for the VuThanhThien99 MFE polyrepo. **This repo versions only the shell** (`Makefile`, `bootstrap.sh`, docs index). Sibling apps are separate git repos cloned beside it.

| Path | Owns |
|------|------|
| `mfe-backend` | Postgres, Redis, API, optional MinIO |
| `mfe-shell` | Authenticated Vite host app |
| `mfe-gateway` | nginx edge, platform docs, Helm, Playwright e2e |
| `mfe-landing`, `mfe-remote-*` | Each app’s image / `pnpm\|npm` dev |
| `mfe-shared` | Packages only (no compose) |

You can skip this repo and clone any `mfe-*` alone — each still runs per its own README.

## Quick start

```bash
git clone https://github.com/VuThanhThien99/mfe-workspace.git
cd mfe-workspace
./bootstrap.sh            # or: make bootstrap
make up                   # full Docker mesh → http://localhost:8080
make -C mfe-backend seed  # first boot / empty DB
```

Optional pin: `MFE_REF=v0.2.0 ./bootstrap.sh` (tag or sha). Default branch: `main`.

```bash
make down
make dev                  # hybrid: infra + gateway → host.docker.internal
```

If old `mfe-platform-*` containers still hold ports: `make legacy-down` (if present) or stop them manually.

Assets default to whatever `ASSETS_S3_*` is in `mfe-backend/.env` (e.g. R2). Local MinIO is opt-in: `make assets-local-up` (`:9000` / console `:9001`, bucket `mfe-assets`; stop with `make assets-local-down`). Admin image previews use build-time `VITE_ASSET_BASE_URL` (set in `mfe-remote-admin/.env` for R2 custom domain; rebuild after change).  
E2e (mesh up): `make -C mfe-gateway e2e`

## Docs

- Doc ownership index: [`docs/README.md`](./docs/README.md)
- Workspace plans: [`plans/`](./plans/)
- Standing local guide (after bootstrap): [`mfe-gateway/docs/local-development-guide.md`](./mfe-gateway/docs/local-development-guide.md)
- Backend: [`mfe-backend/README.md`](./mfe-backend/README.md)

## Network

Shared Docker network **`mfe-net`** (aliases `backend`, `shell`, `gateway`, `landing`, …).  
`make clean-network` only when no containers are attached.
