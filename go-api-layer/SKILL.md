---
name: go-api-layer
description: "Go API/handler/controller 层专家。Use when writing, refactoring, or reviewing Gin/HTTP handlers, request binding, query/body params, response DTOs, pagination responses, service calls, JSONOK/JSONError, or API layer conventions."
---

# Go API Layer

API 层只负责 HTTP 适配：解析请求、基础校验入口、调用 service、统一响应。复杂参数组装、关联聚合、业务编排和复杂响应组装放到 service 层。

## Workflow

1. 识别 API 边界：确认 handler、query/body/header 来源、service 依赖、返回 items/count/page 信息。
2. 加载 `references/go-api-conventions.md`，按项目约定处理路由、请求解析、错误响应和分页响应。
3. 定义结构：API struct 只持有 service、logger 或轻量依赖；字段和构造函数参数常见顺序为 service、轻量 helper/config、logger；依赖通过构造函数或明确字段注入，不能在 handler 内临时创建 service/DAL/client，也不能因为 service/logger/helper 为 nil 就跳过调用或降级执行；同一个 API struct 的 handler 方法统一使用指针接收者，receiver 统一命名为 `api`。
4. 解析请求：按 HTTP 方法确定参数来源：`POST` 所有参数都从 body 传参；`PUT` 从 query 读取更新 ID 或 uniqueID，其他参数从 body 传参；其他方法使用 query 传参；字段多时组装语义化 param。
5. 校验与调用：带领域方法的 param/DTO 使用指针变量；param 有 `Serialize()` 时用原变量接收返回值，再执行 `Check()`；handler 不直接访问 DB/GORM/DAL；trim/default/derive/fill 等领域规整统一放到拥有字段的 param/DTO 的公有 `Serialize()` 中。
6. 响应交付：使用统一 response helper；列表响应包含 items、total、itemsPerPage、startIndex；handler 保持薄但不机械拆分，简单 parse/build/call/return 流程优先内联。

## Reference Loading

生成、重构或评审 API/handler/controller 层代码时，必须加载 `references/go-api-conventions.md`。

## Pre-Delivery Checklist

- [ ] 已同时遵循当前任务涉及的 `go-code-style`、`go-logging`、`go-model-hierarchy`、`go-service-layer` 规则。
- [ ] API struct 只持有 service/logger/轻量依赖；依赖由构造注入，handler 内没有临时创建或 nil 跳过逻辑。
- [ ] Handler 使用项目签名和指针接收者，receiver 统一为 `api`。
- [ ] 请求参数来源符合方法约定：`POST` 全部 body；`PUT` query 必传更新 ID 或 uniqueID，body 传其他全量内容；其他方法使用 query。
- [ ] Param/DTO 定义在 model/API 类型层；字段较多时收敛为语义化 param。
- [ ] 调用 service 前按需要执行 `param = param.Serialize()`、`param.Check()`；handler 内没有散落领域规整或业务编排。
- [ ] API 层没有 DB/GORM/DAL 操作；复杂组装、聚合和业务流程留在 service。
- [ ] 响应使用统一 helper；列表响应包含分页信息，空列表为空切片。
