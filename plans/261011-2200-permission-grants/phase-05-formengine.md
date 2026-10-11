# Phase 05 — Formengine modes

## Context

- [design-spec.md](./design-spec.md)
- [phase-01-package.md](./phase-01-package.md)
- Parser hiện tại: `mfe-remote-formengine/src/routing.ts`
- Modes: `` → list, `designer`, `runtime`

## Overview

- Priority: P2
- Status: Done
- Effort: 3h
- Giữ parser URL hiện tại. Gắn permission theo mode. Không ép sang `<Routes>`.

## Key Insights

- Formengine không dùng react-router `<Route>`. Catalog vẫn là danh sách path hợp lệ.
- `formengine.forms.design` default false. List và runtime default true.
- `?code=` vẫn là mã form, không phải permission.

## Requirements

- Mode thiếu quyền → Forbidden, không mở designer/runtime/list.
- Path mode không có trong catalog → coi như không có quyền (fail closed), không fallback sang designer.
- Test: ba path catalog đều có view map.

## Architecture

```
parseRoute() → mode
catalog route where remote=formengine and path matches mode
hasPermission(route.permission) ? view : Forbidden
```

Path catalog `` khớp mode `list`. `designer` và `runtime` khớp segment.

## Related Code Files

Modify:

- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-formengine/src/routing.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-formengine/src/routing.test.ts`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-formengine/src/App.tsx`
- `/Users/vuthanhthien/Documents/Coding/personal/mfe-workspace/mfe-remote-formengine/package.json`

Create view map cạnh routing nếu `App.tsx` đang switch mode bằng if.

## Implementation Steps

1. Cài package interfaces.
2. Hàm `permissionForMode(mode)` đọc catalog, không hard-code id ở App.
3. Chỗ render mode: nếu `!hasPermission` thì Forbidden.
4. Nav nội bộ (về list, mở designer) ẩn khi thiếu quyền.
5. Test map đủ 3 path và unknown segment không thành designer.

## Todo List

- [x] Gate formengine modes from the catalog

## Success Criteria

- User chỉ có `formengine.forms.read` mở được list, không mở designer.
- User có `formengine.forms.design` mở designer.
- `ADMIN` mở cả ba.
- Test routing pass.

## Risk Assessment

- Legacy hash URL rewrite chạy trước gate và đẩy user vào mode họ không có. Gate sau khi đã parse mode cuối.

## Security Considerations

- Designer là quyền ghi. Default false.
- API form do phase 2 gắn `@RequirePermissions`.

## Next Steps

- Không phụ thuộc phase 4 và 6.
