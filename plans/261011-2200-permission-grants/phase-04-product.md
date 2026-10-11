# Phase 04 — Product routes

## Context

- [design-spec.md](./design-spec.md)
- [phase-01-package.md](./phase-01-package.md)
- Router hiện tại: `mfe-remote-product/src/routes/product-routes.tsx`

## Overview

- Priority: P2
- Status: Done
- Effort: 3h
- Dựng router product từ catalog. Không sửa backend (phase 2 đã gắn guard).

## Key Insights

- `:productId` phải đăng ký sau `categories` và `files`. Lấy thứ tự từ mảng catalog, không sort lại.
- Index và `:productId` cùng permission `product.products.read`.

## Requirements

- Map đủ route id remote `product`.
- Mỗi route bọc check `product.*.read` tương ứng.
- Thiếu quyền: không hiện link nội bộ tới route đó; URL trực tiếp → Forbidden.
- User `ADMIN` thấy mọi route product.

## Architecture

`routes.filter(remote === 'product')` → map component → `<Route path permission>`.

## Related Code Files

Create:

- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-product/src/routes/route-components.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-product/src/routes/route-components.test.ts`

Modify:

- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-product/src/routes/product-routes.tsx`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-product/package.json`

Nav/link nội bộ nếu có hard-code path: trỏ path từ catalog hoặc ẩn bằng `hasPermission`.

## Implementation Steps

1. Cài `@vuthanhthien99/interfaces`.
2. Map: index → `ProductListPage`, `categories` → `CategoriesPage`, `categories/:categoryId` → `CategoryDetailPage`, `files` → `MyFilesPage`, `:productId` → `ProductDetailPage`.
3. Thay `<Routes>` tay bằng loop catalog. Giữ fallback `*` về list chỉ khi user có `product.products.read`; không thì Forbidden.
4. Test: mọi route id product có component.

## Todo List

- [x] Drive product router from the shared catalog

## Success Criteria

- Test map pass.
- User không có `product.categories.read` không thấy categories và mở path đó ra Forbidden.
- Thứ tự route không để `categories` rơi vào `ProductDetailPage`.

## Risk Assessment

- Loop làm sai thứ tự so với catalog. Test một snapshot mảng `path` đã render.

## Security Considerations

- FE gate chỉ là UX. API product do phase 2 trả 403.

## Next Steps

- Phase 7 có thể dùng một route product làm đại diện. Không chặn phase 5 và 6.
