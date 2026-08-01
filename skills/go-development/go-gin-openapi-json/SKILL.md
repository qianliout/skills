---
name: go-gin-openapi-json
description: "Go Gin OpenAPI JSON Skill。Use when generating, refreshing, reviewing, or explaining OpenAPI 3.1.0 JSON for selected Gin routes, handlers, request/response schemas, Apifox imports, and Go API schema contracts."
---

# Go Gin OpenAPI JSON

用于从 Gin Go 代码生成、刷新、评审或解释 OpenAPI `3.1.0` JSON。只为用户明确指定的接口范围生成文档；以当前 Go 代码为事实来源。

## Workflow

1. 确认目标接口范围、Go 项目根目录和输出路径。范围缺失或存在多个合理匹配时，要求用户提供 route、method + path、handler、route group 或 module selector。
2. 读取 `references/gin-openapi-json.md`、`references/gin-openapi-json-conventions.md`，以及 `../go-api-layer/references/api-layer.md` 和 `../go-api-layer/references/api-layer-conventions.md`（API 层约定的唯一来源，本 Skill 不维护副本）。
3. 用户要求 Apifox 兼容、示例对齐或项目没有专用模板时，读取 `assets/openapi.json`。
4. 优先用项目代码图工具定位选定路由、handler、model 和 response helper；图工具不足时再使用 `rg`、Go AST 和直接文件读取。
5. 只追踪选定接口需要的参数来源、DTO、校验、序列化、service 返回类型和响应 envelope。
6. 只为选定 operation 构建 `paths` 和被引用的 `components.schemas`，生成一个最终 JSON 文件。
7. 验证 JSON 可解析、所有 `$ref` 有目标、path 参数完整、请求和响应结构与代码一致。

## Scope Boundaries

- 最终文档不包含未选中的路由。
- 真实代码与默认 API 约定不一致时，文档忠实反映代码。
- 无法从代码确认的路由、响应模型或 envelope 不得猜测。
- 输出 JSON 使用两空格缩进，`openapi` 为 `3.1.0`。

## Pre-Delivery Checklist

- 目标接口范围明确。
- 已读取本 Skill 的 Go OpenAPI reference 和 `go-api-layer` 的 API layer reference。
- 请求参数、body、响应 envelope 和 schema 均有代码依据。
- JSON 可解析，所有 `$ref`、path 参数和 request body schema 完整有效。
