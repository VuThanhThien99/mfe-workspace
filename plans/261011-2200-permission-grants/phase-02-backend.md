# Phase 02 — Backend grants + guard

## Context

- [design-spec.md](./design-spec.md)
- [phase-01-package.md](./phase-01-package.md)
- Guard hiện tại: `mfe-backend/src/guards/scopes.guard.ts` (JWT scopes, stale đến refresh)
- User API: `mfe-backend/src/api/user/`
- Constants: `mfe-backend/src/constants/app.constant.ts`

## Overview

- Priority: P1
- Status: Done (guard order fix, package 0.1.1)
- Effort: 6h
- Persist grant, validate theo catalog, enforce API bằng DB. Không cache Redis mới.

**Shipped:** mfe-backend commit cb524ee feat(authz), pinned interfaces@^0.1.1

## Key Insights

- `ScopesGuard` đọc scope từ JWT, hiệu lực sau refresh (≤ 15 phút). Permission guard đọc DB nên grant đổi có hiệu lực ngay.
- Hạ `ADMIN` → `DASHBOARD` vẫn là đổi scope. Bypass còn đến lần refresh token. Không sửa độ trễ đó trong phase này.
- `ADMIN` trên JWT → pass, không query `user_permission`.

## Requirements

- Bảng `user_permission(user_id, permission)` unique cặp.
- `scopeNames` đúng một trong `ADMIN` | `DASHBOARD`.
- Create `DASHBOARD` omit `permissions` → copy `defaultPermissionIds()`.
- `permissions` có mặt → replace full set. `[]` xóa hết.
- `permissions` kèm kết quả scope `ADMIN` → 400.
- Id lạ → 400, body có danh sách id.
- Create/update + ghi grant trong một transaction.
- `GET /users/me` trả `permissions`. Admin → `[]`. Id không còn trong catalog bị bỏ và log warning.
- Đổi sang `ADMIN` giữ row. Đổi về `DASHBOARD` row cũ có hiệu lực.
- Scope create/update/delete → 403.
- `@RequirePermissions` AND. Thiếu user → 401. Thiếu quyền → 403.
- Gắn decorator lên handler đã có của các route seed (user, scope read, mfe-config, files, form, product nếu controller đã tồn tại). Không bịa endpoint mới.

## Architecture

```
PATCH /users/:id
  → validate scope + permission ids
  → transaction: user_scope replace (1 scope) + user_permission replace

PermissionsGuard (sau AuthGuard)
  → JWT scopes contains ADMIN → pass
  → else load grants by user id, isAllowed
```

## Related Code Files

Create:

- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/src/api/user/entities/user-permission.entity.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/src/database/migrations/*-create-user-permission-table.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/src/decorators/require-permissions.decorator.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/src/guards/permissions.guard.ts`

Modify:

- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/src/api/user/user.service.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/src/api/user/user.service.spec.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/src/api/user/dto/user.res.dto.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/src/api/user/dto/create-user.req.dto.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/src/api/user/dto/update-user.req.dto.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/src/api/scope/scope.controller.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/src/constants/app.constant.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/src/utils/configure-app.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/package.json` (dependency interfaces)
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-backend/CLAUDE.md`

Controllers hiện có của form/product/files/mfe-config: thêm decorator, không đổi nghiệp vụ.

## Implementation Steps

1. Cài `@vuthanhthien99/interfaces` bản đã build CJS. Import `permissions` bằng require/resolve mà Nest dùng được.
2. Migration + entity. Không bảng master.
3. Sửa DTO và `UserService.create` / `update` đúng bảng case trong spec. Transaction.
4. `findOne` load grants, lọc id lạ lúc serialize `/me`.
5. Guard + decorator + đăng ký global sau `AuthGuard`, cạnh `ScopesGuard`.
6. Scope create/update/delete trả 403. GET list giữ hành vi đọc DB. Không xóa scope lạ đã có. UI phase 3 chỉ vẽ `ADMIN` và `DASHBOARD`.
7. Gắn `@RequirePermissions` theo seed. Map controller method → permission id ghi trong phase file này lúc làm, bám route table của spec.
8. Jest cho các case Success Criteria của spec (backend section).
9. Sửa `CLAUDE.md`: cho phép `user_permission`, cấm bảng master và cấm `isAdmin`.

## Todo List

- [x] Persist grants, guard, close scope writes
- [x] Keep user create/update and grants in one transaction
- [x] Migration `user_permission` applied locally
- [x] Seed DASHBOARD user with catalog default grants
- [x] Phase-2 unit tests green (guard/user/scope)
- [x] PermissionsGuard positioned after AuthGuard for correct order
- [x] E2E permissions-grants tests
- [x] Package @vuthanhthien99/interfaces 0.1.1 (dual CJS types + product.products.write)

## Success Criteria

- Các test backend liệt kê trong spec pass.
- User `ADMIN` gọi route có `@RequirePermissions` mà không có row grant → 200.
- User `DASHBOARD` thiếu grant → 403 ngay sau PATCH, không cần login lại.
- `require()` catalog từ Nest process không throw.

## Risk Assessment

- Test cũ tạo scope hoặc gửi nhiều `scopeNames` sẽ đỏ. Sửa test theo contract mới, không nới validation.
- N+1 nếu guard query từng request. Chấp nhận cho MVP. Không thêm Redis.

## Security Considerations

- UI hide không thay cho guard.
- 400 khi id lạ, không bỏ qua âm thầm.
- Không ghi permission vào JWT.
- Bypass admin dựa trên scope JWT, cùng cửa sổ stale với `ScopesGuard`.

## Next Steps

- Phase 3 dùng `PATCH /users/:id` và `GET /users/:id`.
- Phase 7 cần API 403/200 thật.
