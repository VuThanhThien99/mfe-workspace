# Phase 07 — E2E

## Context

- [design-spec.md](./design-spec.md)
- Auth helper: `mfe-gateway/e2e/lib/auth.ts`
- Một luồng, không cover từng button.

## Overview

- Priority: P1
- Status: Done
- Effort: 3h
- Chứng minh hide, Forbidden, 403, rồi grant và 200. Admin bypass không cần row grant.
- **Note**: Spec passed on local mesh (`pnpm exec playwright test e2e/permission-grants.spec.ts` — 5/5). Requires sdk@0.5.3 (setFromMe hydrates permissions) + remotes seeded to `http://localhost:8080`.

## Key Insights

- Dùng một route product làm đại diện: `categories` / `product.categories.read`.
- Tạo user qua API admin cho ổn định hơn click cây. UI cây được phase 3 test ở mức component; e2e không phụ thuộc animation tree.

## Requirements

- User `DASHBOARD` không có `product.categories.read`: nav không có categories, mở URL → Forbidden, API liên quan → 403.
- PATCH grant permission đó, reload để `/users/me` về slice mới: page mở, API 200.
- User `ADMIN` không có row `user_permission` vẫn mở page và API 200.

## Architecture

E2E trong `mfe-gateway` chống mesh đang chạy. Không thêm harness mới.

## Related Code Files

Modify or create next to existing e2e:

- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-gateway/e2e/lib/auth.ts` (helper tạo user + set permissions nếu chưa có)
- Một spec mới dưới `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-gateway/e2e/` theo convention thư mục hiện có.

Không sửa file phase 1–6.

## Implementation Steps

1. Đọc spec e2e hiện có, thêm case vào đúng chỗ (setup admin token, tạo dashboard user).
2. Assert nav, deep link, API trước và sau grant.
3. Assert admin bypass.
4. Chạy spec đó khi mesh up. Không yêu cầu full suite trong definition of done của phase nếu suite hiện đã có flake riêng; spec mới phải pass.

## Todo List

- [x] Cover one grant, deny, and admin-bypass journey
- [x] Run spec on local mesh: `make up && pnpm exec playwright test e2e/permission-grants.spec.ts`

## Success Criteria

- Spec e2e mới pass trên mesh local.
- Không có row grant cho admin user trong assertion bypass.

## Risk Assessment

- `/me` chưa hydrate thì assert nav sai. Đợi request `/users/me` xong rồi mới assert.
- Data test sót user. Dùng username unique và xóa cuối test nếu helper hiện hỗ trợ delete.

## Security Considerations

- Test dùng tài khoản admin seed, không in token ra log.

## Next Steps

- Hết plan. Cook theo thứ tự dependency trong `plan.md`.
