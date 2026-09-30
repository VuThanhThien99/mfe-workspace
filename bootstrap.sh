#!/usr/bin/env bash
#
# bootstrap.sh — clone sibling MFE repos into this workspace root.
#
# Lives in mfe-workspace (git: VuThanhThien99/mfe-workspace). Sibling dirs are
# gitignored here; each product repo stays independently owned.
# Orchestration: `make up` / `make dev`.
#
#   mfe-workspace/               <- this repo (script + Makefile)
#   ├── mfe-shell/               <- authenticated Vite host app
#   ├── mfe-gateway/             <- nginx edge + docs + Helm + Playwright e2e
#   ├── mfe-backend/
#   ├── mfe-landing/
#   ├── mfe-remote-product/
#   ├── mfe-remote-admin/
#   ├── mfe-remote-vue/
#   ├── mfe-remote-formengine/
#   └── mfe-shared/              <- @vuthanhthien99/sdk + ui (+ eform)
#
# Usage:
#   ./bootstrap.sh                 # clone whatever is missing, at MFE_REF
#   MFE_REF=v0.2.0 ./bootstrap.sh  # pin every repo to a tag
#   MFE_REF=<sha>  ./bootstrap.sh  # pin to an exact commit
#   MFE_ORG=other-org ./bootstrap.sh
#
# Idempotent: repos that already exist are left untouched. Never pulls/overwrites.

set -euo pipefail

MFE_ORG="${MFE_ORG:-VuThanhThien99}"
MFE_REF="${MFE_REF:-main}"
PARENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REPOS=(
  mfe-shell
  mfe-gateway
  mfe-backend
  mfe-landing
  mfe-remote-product
  mfe-remote-admin
  mfe-remote-vue
  mfe-remote-formengine
  mfe-shared
)

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit 0
fi

echo "org:   $MFE_ORG"
echo "ref:   $MFE_REF"
echo "into:  $PARENT_DIR"
echo

cloned=0
present=0
failed=0

for repo in "${REPOS[@]}"; do
  dest="$PARENT_DIR/$repo"

  if [[ -d "$dest/.git" ]]; then
    printf '  ✓ %-24s already present\n' "$repo"
    present=$((present + 1))
    continue
  fi

  printf '  … %-24s cloning\n' "$repo"

  if command -v gh >/dev/null 2>&1; then
    gh repo clone "$MFE_ORG/$repo" "$dest" -- --quiet || { echo "    ✗ clone failed"; failed=$((failed + 1)); continue; }
  else
    git clone --quiet "https://github.com/$MFE_ORG/$repo.git" "$dest" || { echo "    ✗ clone failed"; failed=$((failed + 1)); continue; }
  fi

  if [[ "$MFE_REF" != "main" ]]; then
    git -C "$dest" checkout --quiet "$MFE_REF" || { echo "    ✗ cannot check out $MFE_REF"; failed=$((failed + 1)); continue; }
  fi

  printf '    ✓ at %s\n' "$(git -C "$dest" rev-parse --short HEAD)"
  cloned=$((cloned + 1))
done

echo
echo "cloned $cloned, already present $present, failed $failed"

if [[ $failed -gt 0 ]]; then
  echo
  echo "Cloning a private repo needs credentials. Run: gh auth status" >&2
  exit 1
fi

echo
echo "Next:"
echo "  make up                 # Docker mesh → http://localhost:8080"
echo "  make -C mfe-backend seed"
echo "Docs: mfe-gateway/docs/local-development-guide.md"
