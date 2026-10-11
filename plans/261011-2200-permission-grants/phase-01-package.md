# Phase 01 — Package + auth slice

## Context

- [design-spec.md](./design-spec.md)
- Pattern exports: `mfe-shared/packages/sdk/package.json`
- Auth slice: `mfe-shared/packages/sdk/src/store/authSlice.ts`

## Overview
    
- Priority: P1
- Status: Done
- Effort: 4h
- Tạo `@vuthanhthien99/interfaces`. Catalog là source of truth. SDK chỉ thêm field `permissions` trên slice, không import package này.

## Key Insights

- Backend Nest là CommonJS. SDK hiện là ESM-only và backend không phụ thuộc SDK. Entry catalog phải build được bản `require`.
- `permissions/react` import SDK để đọc slice. SDK không được import `interfaces`.
- `route.id` unique theo path. Permission id được nhiều route dùng chung.

## Requirements

- Export seed đúng bảng trong spec, gồm block `admin.users.delete`.
- `isAllowed({ scopes, permissions, permission })`: `ADMIN` → true; không thì kiểm tra list.
- `defaultPermissionIds()` trả các id `default: true`.
- `toTreeItems()` nhóm theo `group` (tên remote). Parent không phải permission id.
- Test unique id, mọi route/block trỏ tới permission có thật, và `isAllowed`.
- `<Can>` và `<PermissionRoute>` theo spec.
- `MeUser` và auth slice có `permissions: string[]`. `setFromMe` copy field. `setPartial` / `clearAuth` xóa về `[]`.

## Architecture

```
interfaces/permissions        pure, dual ESM+CJS
interfaces/permissions/react  ESM, peer: react, @vuthanhthien99/sdk
sdk auth slice                string[] only
```

## Related Code Files

Create:

- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-shared/packages/interfaces/` (package.json, tsconfig, src, tests)

Modify:

- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-shared/packages/sdk/src/store/authSlice.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-shared/packages/sdk/src/store/authSlice.spec.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-shared/package.json` (format glob thêm `interfaces`)

## Implementation Steps

1. Scaffold package theo style `sdk`: `type: module`, build `dist` ESM và `dist-cjs` cho entry `permissions` only.
2. Exports:
   - `./permissions` → `import` ESM, `require` CJS
   - `./permissions/react` → `import` only
3. Viết `permissions`, `routes`, `blocks` đúng seed spec. Thứ tự product: index, `categories`, `categories/:categoryId`, `files`, `:productId`.
4. Pure helpers + vitest.
5. React helpers. `<PermissionRoute>` nhận `forbidden` element từ app, hoặc render fallback text "Forbidden" nếu không truyền. Không kéo UI kit vào package.
6. Sửa auth slice + spec. Không thêm dependency `interfaces` vào SDK.
7. Smoke: một file CJS `require('@vuthanhthien99/interfaces/permissions')` in ra `defaultPermissionIds`. Fail phase nếu Node không load được.

## Todo List

- [x] Ship catalog, helpers, dual build, auth slice field
- [x] Prove Nest-compatible require() of the catalog entry

## Success Criteria

- `pnpm test` trong package và sdk pass.
- `require` của entry catalog chạy trên Node CJS.
- Không có import cycle sdk ↔ interfaces.

## Risk Assessment

- Dual build dễ lệch types. Một `tsc` project ESM, một project CJS cùng `src/permissions` (exclude react).
- Quên thêm `interfaces` vào prettier/husky của `mfe-shared` → format CI đỏ.

## Security Considerations

- Package không chứa secret và không đọc token.
- `isAllowed` fail closed khi scopes/permissions thiếu hoặc rỗng, trừ khi có `ADMIN`.

## Next Steps

- Phase 2 và phase 4–6 cài package này.
