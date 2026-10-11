# Design spec — Permission grants

Status: approved. Chưa implement. Bước tiếp theo là implementation plan.

## Problem

Scope hiện tại chỉ đủ để phân biệt admin và user board (`ADMIN`, `DASHBOARD`) và để quyết định remote nào vào được. Bên trong remote, page, route, button, block chưa có quyền riêng. Admin không có chỗ gán quyền chi tiết cho user thường.

Mỗi remote đang tự khai báo path. Thêm page dễ lệch giữa nơi định nghĩa quyền và nơi gắn router.

## User stories

- Admin gán scope + permission trên `/app/admin/users` (không còn section `/scopes`).
- Admin mở `DASHBOARD` và gán permission cho từng user board bằng cây checkbox.
- Admin mở một user `ADMIN` thì không thấy cây permission.
- Admin trên `/app/admin/users` đổi được scope của user và, nếu scope là `DASHBOARD`, gán permission bằng cùng một cây.
- User mới `DASHBOARD` nhận các permission đánh dấu default trong catalog.
- User `ADMIN` vào mọi page và API dù không có row grant.
- User `DASHBOARD` chỉ thấy route, block đã được gán. Deep link thiếu quyền ra Forbidden. API thiếu quyền trả 403.
- Dev thêm route bằng cách sửa catalog trong package, rồi map component ở remote. Path và permission không khai báo hai nơi.

## Decisions

| Topic | Choice |
|-------|--------|
| Model | Permission là string fine-grain. Scope chỉ còn `ADMIN` \| `DASHBOARD`. |
| Gán | Gán thẳng permission cho user. Scope không expand thành permission. |
| Admin | Scope `ADMIN` = bypass. UI không gán permission cho admin. |
| Client payload | `GET /users/me` trả `permissions[]`. JWT không chứa permissions. |
| Default | Catalog `default: true`. Create user `DASHBOARD` không gửi `permissions` thì copy default. |
| MFE vs in-app | Scope giữ gate remote (`mfe-configs/accessible`). Permission gate route/block trong remote. |
| Package | `@vuthanhthien99/interfaces`, subpath permissions. Catalog + helper React. |
| Thiếu quyền trên UI | Hide. Deep link → Forbidden. API vẫn enforce. |
| Phạm vi remote | `admin`, `product`, `formengine`, `vue`. `mfe-landing` là site public, ngoài catalog. |
| Route sync | Package export mảng route có thứ tự. Remote map `route.id` → component. |
| Admin tree | MUI X Simple Tree View, `checkboxSelection`, chỉ leaf chọn được. |
| Ghi quyền | Một API `PATCH /users/:id`. Hai màn admin dùng chung. |

## Approaches considered

### 1. Catalog package + `user_permission` strings (chọn)

Package là source of truth của id, tree, default, route, block. DB chỉ lưu grant `(user_id, permission)`. Validate id ∈ catalog lúc ghi.

Ưu: khớp các quyết định trên, không thêm bảng master permission, FE/BE dùng chung id. Nhược: đổi catalog cần deploy package. Phù hợp MVP.

### 2. Sync catalog vào bảng `permission` lúc boot

Thêm drift sync và migration. Không cần cho MVP.

### 3. Ability engine kiểu CASL

Thừa so với string permission. Không có rule theo ownership hay condition.

## Architecture

```
@vuthanhthien99/interfaces
  permissions          catalog, tree, pure checks (không React, không sdk)
  permissions/react    hasPermission, Can, PermissionRoute (đọc auth slice sdk)

mfe-backend
  scope constants ADMIN, DASHBOARD
  user_permission
  @RequirePermissions
  /users/me → permissions[]

mfe-remote-admin
  /users, /users/new, /users/:id  sửa scope + cây khi DASHBOARD
  (không còn /scopes — gán permission chỉ trên form user)

product, formengine, vue
  dựng router từ catalog + map component cục bộ
```

| Unit | Sở hữu | Không sở hữu |
|------|--------|----------------|
| `interfaces` | Id, group, default, route, block, pure check, React helper | Nest guard, DB, page admin |
| Backend | Persist grant, enforce API, `/users/me` | Render cây |
| Admin | Hai entry gán quyền, Forbidden | Tạo permission id mới |
| Remote khác | Map component, bọc `<Can>` | Gán quyền |

Backend import entry `permissions` (pure). Không import `permissions/react`. SDK không import `interfaces`, để tránh vòng phụ thuộc. Remote import cả hai.

## Catalog

### Permission

```ts
interface PermissionDef {
  id: string;       // 'product.categories.read'
  group: string;    // node cha trên cây, không phải scope
  label: string;
  default: boolean;
}
```

Id unique, lowercase, dạng `remote.resource.action`. `group` = tên remote, dùng làm node cha trên cây.

Default nằm ở cột dưới. Quy tắc: read/list/fill của board remote thì `default: true`. Mọi id remote `admin`, formengine designer, và action ghi/xóa thì `default: false`.

### Route

```ts
interface RouteDef {
  id: string;
  remote: 'admin' | 'product' | 'formengine' | 'vue';
  path: string;          // relative trong remote, '' = index
  permission: string;    // phải tồn tại trong permissions
}
```

Thứ tự mảng = thứ tự đăng ký router. Segment tĩnh đứng trước param.

Seed (path lấy từ router hiện tại). `route.id` unique theo path. Cột Permission là id grant, nhiều route được dùng chung một id. Catalog `permissions` = các id ở cột này, cộng `admin.users.delete` từ block seed.

| Remote | Path | Permission | Default |
|--------|------|------------|---------|
| admin | `users` | `admin.users.read` | false |
| admin | `users/new` | `admin.users.write` | false |
| admin | `users/:id` | `admin.users.write` | false |
| admin | `configs` | `admin.configs.read` | false |
| admin | `configs/new` | `admin.configs.write` | false |
| admin | `configs/:id` | `admin.configs.write` | false |
| admin | `configs/:id/nav` | `admin.configs.write` | false |
| admin | `files` | `admin.files.read` | false |
| admin | `files/published` | `admin.files.publish` | false |
| product | `` | `product.products.read` | true |
| product | `categories` | `product.categories.read` | true |
| product | `categories/:categoryId` | `product.categories.read` | true |
| product | `files` | `product.files.read` | true |
| product | `:productId` | `product.products.read` | true |
| formengine | `` | `formengine.forms.read` | true |
| formengine | `designer` | `formengine.forms.design` | false |
| formengine | `runtime` | `formengine.forms.fill` | true |
| vue | `` | `vue.overview.read` | true |
| vue | `analytics` | `vue.analytics.read` | true |
| vue | `reports` | `vue.reports.read` | true |
| vue | `notifications` | `vue.notifications.read` | true |

Thứ tự các dòng product trong bảng là thứ tự đăng ký router, để `:productId` không nuốt `categories` và `files`.

Bỏ route admin cũ `scopes/new` và `scopes/:id`.

Formengine không dùng `<Routes>`. Nó parse segment đầu thành mode. Vẫn lấy path từ catalog rồi map mode → view. Permission check chạy trên mode đó.

Mỗi remote giữ `Record<routeId, Component>`. Package không export component. Test fail nếu catalog của remote đó thiếu key trong map.

### Block

```ts
interface BlockDef {
  id: string;
  remote: 'admin' | 'product' | 'formengine' | 'vue';
  permission: string;
}
```

Block dùng khi một control trên page phải chặt hơn permission của chính page. Page dùng permission của route.

Seed MVP: `admin.users.delete` trên hành động xóa user (page list vẫn là `admin.users.read`). Control khác chỉ thêm vào catalog khi cần chặt hơn page. Không tạo block giả cho mọi button.

### Tree admin

Dựng từ `permissions[].group`. Parent không selectable. Leaf id = permission id. `selectedItems` và payload chỉ chứa leaf.

User `ADMIN`: không render cây. User `DASHBOARD`: cây controlled.

## Data

Bảng `user_permission`:

- `user_id` FK → `user`
- `permission` string
- unique `(user_id, permission)`
- không có bảng master permission

`user_scope` giữ nguyên. User có đúng một scope: `ADMIN` hoặc `DASHBOARD`. Hai row scope đó vẫn được seed vì FK. Create/update/delete scope trả `403`. Spec này không xóa scope lạ đã có trong DB; UI và API gán user không còn nhận chúng.

## API contracts

`UserResDto` thêm `permissions: string[]`.

`CreateUserReqDto` / `UpdateUserReqDto`:

- `scopeNames`: đúng một phần tử, `ADMIN` hoặc `DASHBOARD`.
- `permissions?: string[]`: khi có mặt thì là **full set** (replace). `[]` = xóa hết grant. Chỉ gửi leaf id.

| Case | Kết quả |
|------|---------|
| Create `DASHBOARD`, omit `permissions` | Copy mọi id `default: true` |
| Create/update `DASHBOARD` + `permissions` | Replace grant bằng mảng đó |
| Create/update `ADMIN` + field `permissions` | `400` |
| `DASHBOARD` → `ADMIN` | Giữ row grant, runtime bỏ qua |
| `ADMIN` → `DASHBOARD` | Grant cũ có hiệu lực lại |
| Id không thuộc catalog | `400`, body liệt kê id lạ |
| `scopeNames` sai | `400` |
| User không tồn tại | `404` |

Create/update user và ghi grant trong một transaction.

`GET /users/me`:

- User thường: `permissions` = grant còn id trong catalog. Id đã bỏ khỏi catalog bị loại và log warning.
- User `ADMIN`: `permissions: []`. Client dùng scope để bypass.

JWT payload không đổi.

### Enforce API

`@RequirePermissions(...ids)` trong backend, AND semantics, đọc grant từ DB. Cache nếu có thì invalidate khi `PATCH` user đó.

- Chưa login → `401`
- `ADMIN` → pass, không đọc grant
- Thiếu permission → `403`
- Đủ permission → pass

Scope gate của remote (`@RequireScopes`, `mfe-configs/accessible`) giữ nguyên, chạy riêng.

Đổi grant có hiệu lực trên API ngay. UI của user đích đổi sau lần `GET /users/me` kế tiếp. Không websocket.

## Frontend contracts

Auth slice thêm `permissions: string[]`. `setFromMe` ghi field này. Không đưa token vào slice.

```ts
function isAllowed(input: {
  scopes: readonly string[];
  permissions: readonly string[];
  permission: string;
}): boolean
```

`true` khi `scopes` chứa `ADMIN` hoặc `permissions` chứa id.

- `hasPermission(id)` đọc slice, gọi `isAllowed`.
- `<Can permission>`: false → render `null`.
- `<PermissionRoute permission>`: false → Forbidden, giữ URL.

Nav trong remote lọc bằng `hasPermission` của route tương ứng.

Status `partial`: chưa render nav/route theo permission. Status `error`: màn retry, không coi list rỗng là "không có quyền".

Save cây lỗi: giữ selection, hiện lỗi API. Hai admin cùng sửa một user: last write wins, không có version check.

API trả `403` vì quyền vừa đổi: refetch `/users/me` một lần, báo quyền đã đổi.

## Error handling

Fail closed khi status đã `ready` và không có `ADMIN`.

| Case | Hành vi |
|------|---------|
| Auth `partial` | Không flash full menu |
| Auth `error` | Retry, không render app như user zero-permission |
| `<Can>` false | `null` |
| Route false | Forbidden |
| Catalog route thiếu component | Test/CI fail. Runtime nếu lọt: Forbidden |
| Id grant chết sau deploy | `/me` bỏ id, không 500 |
| Ghi grant lỗi giữa chừng | Rollback cả user update |

## Testing

### Package

- Id permission và route unique.
- Mọi `route.permission` và `block.permission` tồn tại trong `permissions`.
- `isAllowed`: `ADMIN` + list rỗng → true; user thường thiếu id → false; có id → true.

### React helper

- `<Can>` false không render children.
- `<PermissionRoute>` false render Forbidden, true render page.

### Backend

- Create `DASHBOARD` omit permissions → đúng tập default.
- Id lạ → `400`, không ghi grant.
- `permissions` kèm scope `ADMIN` → `400`.
- `scopeNames` không hợp lệ → `400`.
- Guard: admin pass; có grant pass; thiếu grant `403`; chưa login `401`.
- `/me` bỏ id không còn trong catalog.
- `DASHBOARD` → `ADMIN` giữ row; guard vẫn bypass.
- Transaction: lỗi giữa chừng không để user thiếu grant so với request.

### Remote

Mỗi remote: mọi route catalog của remote đó có component map. Admin: user `ADMIN` không có cây; save `DASHBOARD` chỉ gửi leaf; gán quyền chỉ trên form user.

### E2E một luồng

User `DASHBOARD` không có permission: nav không có route, deep link Forbidden, API `403`. Sau khi gán và reload `/me`: page mở được, API `200`. User `ADMIN` mở được page đó dù không có row `user_permission`.

## Implementation notes

- Làm package và backend trước, rồi admin UI, rồi từng remote. Vẫn một spec.
- `mfe-backend/CLAUDE.md` đang cấm bảng roles/permissions. Cập nhật doc: được phép `user_permission` (grant string), không thêm bảng master permission, không thêm `isAdmin`.
- Polyrepo: backend và remote phải cùng version `@vuthanhthien99/interfaces`. Id mới chưa publish thì API `400`.
- Formengine map catalog vào parser mode hiện có, không ép sang `<Routes>` nếu parser đang là source của URL.
- Product giữ thứ tự `:productId` sau các path tĩnh, lấy thứ tự từ mảng catalog.

## Risks

- Last write wins khi hai admin sửa cùng user.
- UI user đích stale đến lần `/me` sau. API đã chặn.
- Đổi `ADMIN` → `DASHBOARD` làm grant cũ sống lại. UI phải hiện cây với selection đó trước khi save.
- Catalog phình vì mọi route nằm một package. Đúng chủ đích đồng bộ; mỗi route mới là một thay đổi shared.
- Landing không nằm trong catalog. Nếu sau này có vùng login trong landing, đó là spec khác.

## Success

- Không còn UI tạo scope. Chỉ `ADMIN` và `DASHBOARD`.
- User board không vào page/API khi chưa được gán; sau gán và reload thì vào được.
- Admin bypass không cần row grant và không có cây trên form của chính user admin.
- Route path dùng trong remote lấy từ catalog. Test map component xanh.
- `GET /users/me` là nguồn permissions cho UI. JWT không có field permissions.

## Next

Sau khi spec được duyệt: viết implementation plan (`/plan`) từ file này. Plan tách phase package → backend → admin UI → product → formengine → vue, mỗi phase có test của chính nó.
