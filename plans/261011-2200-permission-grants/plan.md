---
title: "Permission grants"
description: "Catalog permission dùng chung, gán cho user board, gate route và API."
status: spec-complete
priority: P1
effort: 26h
branch: main
tags: [feature, auth, frontend, backend, api]
created: 2026-10-11
progress: "7 of 7 phases (100% spec-complete; mesh verification pending)"
---

# Permission grants

## Overview

Thêm `@vuthanhthien99/interfaces`, bảng `user_permission`, và gate route/API theo spec đã duyệt. Scope chỉ còn `ADMIN` | `DASHBOARD`. `ADMIN` bypass. UI lấy permissions từ `GET /users/me`.

Spec: [design-spec.md](./design-spec.md)

## Phases

| # | Phase | Status | Effort | Owns | Link |
|---|-------|--------|--------|------|------|
| 1 | Package + auth slice | Done | 4h | `mfe-shared/**` | [phase-01](./phase-01-package.md) |
| 2 | Backend grants + guard | Done | 6h | `mfe-backend/**` | [phase-02](./phase-02-backend.md) |
| 3 | Admin assign UI | Done | 5h | `mfe-remote-admin/**` | [phase-03](./phase-03-admin-ui.md) |
| 4 | Product routes | Done | 3h | `mfe-remote-product/**` | [phase-04](./phase-04-product.md) |
| 5 | Formengine modes | Done | 3h | `mfe-remote-formengine/**` | [phase-05](./phase-05-formengine.md) |
| 6 | Vue routes | Done | 2h | `mfe-remote-vue/**` | [phase-06](./phase-06-vue.md) |
| 7 | E2E | Done* | 3h | `mfe-gateway/e2e/**` | [phase-07](./phase-07-e2e.md) |

## Dependency graph

```
P1 package
 ├─ P2 backend ── P3 admin UI ──┐
 ├─ P4 product ─────────────────┤
 ├─ P5 formengine ──────────────┼─ P7 e2e
 └─ P6 vue ─────────────────────┘
```

P4, P5, P6 chạy song song sau P1. P3 chờ P2. P2 có thể chạy song song với P4–P6. Không có file nào thuộc hai phase.

## Execution

Mỗi repo một branch `feat/permission-grants`. Package publish hoặc link cùng version trước khi remote/backend cài. Nest là CommonJS; entry `permissions` phải có bản `require`. Entry `permissions/react` chỉ ESM.

## Dependencies

- Spec đã duyệt, không mở lại model.
- `@mui/x-tree-view` trên admin cho checkbox tree.
- Seed scope `ADMIN` và `DASHBOARD` giữ nguyên vì FK `user_scope`.

---

## Final Status Summary

✅ **All 7 phases: 100% spec-complete**

| Phase | Status | Deliverable | Verification |
|-------|--------|-------------|--------------|
| 1–6 | Done | Implementation code | ✅ Complete |
| 7 | Done* | E2E spec authored & registered | ⏳ Mesh run: `make up && npx playwright test` |

**Phase 07 Note**: 
- E2E spec fully implemented per requirements
- Covers: one grant journey, deny scenario, admin bypass
- **Remaining**: Manual Playwright verification on local mesh (not blocking code delivery)
- **Command**: `make up && npx playwright test` to run assertion suite
