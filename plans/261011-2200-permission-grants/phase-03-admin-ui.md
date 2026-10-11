# Phase 03 — Admin assign UI

## Context

- [design-spec.md](./design-spec.md)
- [phase-02-backend.md](./phase-02-backend.md)
- Routes: `mfe-remote-admin/src/routes/admin-routes.tsx`
- Users: `mfe-remote-admin/src/pages/users/`
- Scopes: `mfe-remote-admin/src/pages/scopes/`
- Tree docs: https://mui.com/x/react-tree-view/simple-tree-view/selection/#checkbox-selection

## Overview

- Priority: P1
- Status: Done
- Effort: 5h
- Thay CRUD scope bằng hai constant. Gán permission bằng cây checkbox. User form sửa scope và permission.

## Key Insights

- Một component cây dùng ở user form và ở màn dashboard permissions.
- Payload chỉ leaf id. Parent id không gửi.
- User `ADMIN`: không mount cây, không gửi field `permissions`.
- Chuyển `ADMIN` → `DASHBOARD`: cây mở với grant đang lưu (API trả về dù runtime đang bỏ qua).

## Requirements

- `/scopes` list `ADMIN` và `DASHBOARD`. Không nút create/delete/rename.
- `/scopes/dashboard/permissions` list user scope đó, mỗi user một cây, save bằng `PATCH`.
- `/scopes/admin` chỉ giải thích bypass.
- `/users/new` và `/users/:id`: chọn đúng một scope. `DASHBOARD` hiện cây. `ADMIN` ẩn cây.
- Save `DASHBOARD` gửi full leaf selection (replace).
- Route admin lấy path từ catalog + map component. Bỏ `scopes/new` và `scopes/:id`.
- Nút xóa user bọc `<Can permission="admin.users.delete">`.
- Deep link thiếu quyền → Forbidden.

## Architecture

```
catalog.toTreeItems()
  → SimpleTreeView checkboxSelection multiSelect
  → selectedItems filtered to leaf ids
  → PATCH /api/v1/users/:id
```

Controlled `selectedItems`. Parent `disableSelection` để checkbox leaf theo doc MUI (item không selectable thì ẩn checkbox).

## Related Code Files

Create:

- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/src/components/PermissionTree.tsx`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/src/pages/scopes/ScopePermissionsPage.tsx`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/src/pages/scopes/AdminScopePage.tsx`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/src/routes/route-components.ts`

Modify:

- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/src/routes/admin-routes.tsx`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/src/pages/users/UserCreatePage.tsx`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/src/pages/users/UserEditPage.tsx`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/src/pages/users/UsersListPage.tsx`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/src/pages/scopes/ScopesListPage.tsx`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/src/lib/api/users.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/src/schemas/user.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/package.json`

Delete (khi không còn import):

- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/src/pages/scopes/ScopeCreatePage.tsx`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-admin/src/pages/scopes/ScopeEditPage.tsx`

## Implementation Steps

1. Dependency: `@vuthanhthien99/interfaces` và `@mui/x-tree-view` nếu chưa có.
2. `route-components.ts` map mọi `route.id` remote `admin`. Test fail nếu thiếu key.
3. `AdminRoutes` render từ `routes.filter(r => r.remote === 'admin')` theo thứ tự catalog. Bọc `PermissionRoute`.
4. `PermissionTree` controlled, leaf-only.
5. User create/edit: scope select + cây có điều kiện. Omit `permissions` khi `ADMIN`.
6. Scopes list + hai trang con. Trang dashboard load user có scope `DASHBOARD` (filter client từ list users hoặc query nếu API đã hỗ trợ; không thêm endpoint mới nếu list hiện tại đủ).
7. Ẩn nút delete user khi thiếu `admin.users.delete`.
8. Xóa API client create/update/delete scope nếu không còn caller.

## Todo List

- [x] Replace scope CRUD with assign tree and catalog-driven admin routes

## Success Criteria

- Không còn UI tạo scope.
- Save user dashboard chỉ gửi leaf id, đủ full set.
- Form user admin không có cây và không có key `permissions` trong body.
- Test map component pass.
- Vào URL `scopes/new` không còn form tạo scope.

## Risk Assessment

- MUI selection trả cả parent id. Filter leaf trước khi PATCH, có test cho bước filter.
- Hai entry (scopes page và user page) lệch payload. Dùng chung `PermissionTree` và cùng hàm build body.

## Security Considerations

- Admin UI vẫn nằm sau scope `ADMIN` của remote (mfe-config + SoftGate hiện tại). Permission chỉ thêm lớp trong page.
- Không tin cây để bỏ qua 400 từ API. Hiện lỗi server trên form.

## Next Steps

- Phase 7 đi luồng gán quyền từ UI này nếu e2e chạy trên admin. Tối thiểu e2e được gọi API trực tiếp.
