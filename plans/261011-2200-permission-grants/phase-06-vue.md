# Phase 06 — Vue routes

## Context

- [design-spec.md](./design-spec.md)
- [phase-01-package.md](./phase-01-package.md)
- Router: `mfe-remote-vue/src/router/index.ts`

## Overview

- Priority: P2
- Status: Done
- Effort: 2h
- Vue-router đọc path từ catalog. Component vẫn nằm trong remote.

## Key Insights

- Package không export Vue component. Map cục bộ `route.id` → component.
- `beforeEach` đọc permission của route matched. Thiếu quyền → route Forbidden cục bộ, không đẩy user sang remote khác.

## Requirements

- Bốn path: ``, `analytics`, `reports`, `notifications` với permission trong spec.
- Tab/nav ẩn mục thiếu quyền.
- `ADMIN` thấy đủ tab.

## Architecture

Build `RouteRecordRaw[]` từ catalog `remote === 'vue'`. `meta.permission` lấy từ catalog. Guard gọi `isAllowed` với scopes + permissions từ auth store SDK (store dùng chung, không cần React helper).

## Related Code Files

Modify:

- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-vue/src/router/index.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-vue/package.json`
- Nav trong `mfe-remote-vue/src/views/DashboardLayout.vue` nếu tab đang hard-code.

Create:

- Test map route id → component (vitest hoặc test runner remote đang dùng).

## Implementation Steps

1. Cài `@vuthanhthien99/interfaces`. Import entry `permissions` (pure), không import entry react.
2. Map bốn component hiện có: `OverviewPanel`, `AnalyticsPanel`, `ReportsPanel`, `NotificationsPanel`.
3. Thay mảng `routes` tay bằng catalog. Giữ layout cha.
4. `beforeEach`: thiếu permission → Forbidden view.
5. Ẩn tab tương ứng.
6. Test đủ 4 id.

## Todo List

- [x] Drive vue-router from the shared catalog

## Success Criteria

- Test map pass.
- Không có `vue.analytics.read` thì không vào `/analytics` và không thấy tab.
- Path string trong router bằng path catalog.

## Risk Assessment

- Auth store chưa `ready` thì guard chạy lúc `permissions` còn `[]` và chặn nhầm. Đợi status `ready` hoặc `error` trước khi quyết định. `error` → không render panel như user không quyền; để shell/gate hiện retry nếu đã có. Nếu vue không có gate riêng, dừng ở empty state có nút reload.

## Security Considerations

- Cùng rule fail closed. API do phase 2.

## Next Steps

- Song song với phase 4 và 5.
