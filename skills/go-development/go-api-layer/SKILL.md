---
name: go-api-layer
description: "Go API/HTTP handler Skill。Use when writing, refactoring, reviewing, debugging, or explaining Gin/HTTP handlers, controller/API structs, request binding, query/body/header parsing, response DTOs, pagination responses, and response helpers."
---

# Go API Layer

用于 Go API、Gin handler 和 HTTP 适配层任务。API 层只做请求解析、service 调用、错误转换和统一响应；复杂业务、聚合、持久化和模型生命周期不要放进 handler。

## Workflow

1. 确认 HTTP 方法、路由、请求来源、service 依赖、返回结构和分页语义。
2. 读取 `references/api-layer.md` 和 `references/api-layer-conventions.md`。
3. 涉及通用风格、service/model/logging/comment/test 时，再按需使用对应 Go 分类 Skill。
4. 定义 API struct 和构造函数；只持有 service、logger 或轻量 helper/config。
5. 按方法约定解析请求，组装 typed param/DTO，调用 service，并用项目 response helper 返回。
6. 修改 Go 文件后运行 `goimport`；能定位包或测试时运行最小范围 `go test`。

## Layer Boundaries

- Handler 不访问 DB、GORM、SQL、DAL。
- Handler 不承载复杂参数组装、领域规整、业务编排或复杂响应组装。
- 请求来源默认规则：`POST` body；`PUT` query ID/uniqueID + body；其它方法 query。现有代码有明确契约时以代码为准。
- 列表响应包含 items、total、itemsPerPage、startIndex；空列表返回空切片。

## Pre-Delivery Checklist

- 已读取本 Skill 的两个 reference。
- API struct 依赖清晰，handler 薄且只做 HTTP 适配。
- 请求绑定、param/DTO、错误转换和 response helper 符合项目约定。
- 修改 Go 文件后已运行 `goimport`；能运行时已执行相关 `go test`。
