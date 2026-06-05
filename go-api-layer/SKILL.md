---
name: go-api-layer
description: "Go API/handler/controller 层专家。Use when writing, refactoring, reviewing, or explaining Gin/HTTP handlers, request binding, query/body/header params, route methods, response DTOs, pagination responses, service calls, JSONOK/JSONError, or API layer conventions."
---

# Go API Layer

API 层只做 HTTP 适配：解析请求、调用 service、转换错误、统一响应。复杂参数组装、业务编排、跨资源聚合和复杂响应组装放到 service/model。

## Workflow

1. 确认 handler 边界：HTTP 方法、query/body/header 来源、service 依赖、返回结构和分页信息。
2. 加载 `references/go-api-conventions.md`；同时遵循当前任务触发的 `go-code-style`、`go-model-hierarchy`、`go-service-layer`、`go-logging`。
3. 定义 API struct：只持有 service、logger 或轻量 helper/config；依赖由构造函数注入，handler 内不临时创建 service/DAL/client/logger。
4. 解析请求：`POST` 参数来自 body；`PUT` 的更新 ID/uniqueID 来自 query，其他字段来自 body；其他方法默认来自 query。
5. 组装 typed param/DTO：字段多时收敛为语义化 param；trim/default/derive 等规整放到拥有字段的 `Serialize()`。
6. 调用 service 前按需要执行 `param = param.Serialize()` 和 `param.Check()`；handler 不访问 DB/GORM/DAL。
7. 使用项目 response helper 返回；列表响应包含 items、total、itemsPerPage、startIndex，空列表返回空切片。

## Reference Loading

生成、重构或评审 API/handler/controller 代码时，必须加载 `references/go-api-conventions.md`。

## Pre-Delivery Checklist

- [ ] API struct 只持有 service/logger/轻量依赖；依赖通过构造注入，没有 nil 依赖跳过逻辑。
- [ ] Handler 使用项目签名、指针接收者，receiver 统一为 `api`。
- [ ] 请求来源符合方法约定：`POST` body；`PUT` query ID/uniqueID + body；其他 query。
- [ ] Param/DTO 定义在合适 model/API 类型层，JSON tag 没有 `omitempty`。
- [ ] Handler 内没有领域规整、业务编排、DB/GORM/DAL 操作。
- [ ] 响应使用统一 helper；列表响应分页字段完整，空列表为空切片。
