---
name: go-api-layer
description: "用于编写、重构、评审、排查或解释 Gin/HTTP handler、请求绑定、响应 DTO 或分页响应时。"
---

# Go API Layer

API 层只做 HTTP 适配。禁止在 handler 内写复杂业务、聚合、DB/GORM/SQL 或模型生命周期逻辑。

## 强制工作流

1. 必须先经 `$go` 路由进入本 Skill。
1. 必须读取 `references/api-layer.md`。
1. 涉及 param/model 生命周期时必须加载 `go-model-hierarchy`；涉及编排时必须加载 `go-service-layer`；涉及风格、注释或日志时必须加载 `go-code-style`。
1. API struct 只持有 service、logger 或轻量 helper/config；依赖必须构造注入。
1. 修改后必须 `goimport`；能测必须 `go test`。

## 禁止清单

- 禁止 handler 访问 DAL/DB/GORM/SQL。
- 禁止在 handler 做复杂参数规整；必须落到拥有字段的 `Serialize()`。
- 禁止 JSON tag 使用 `omitempty`。
- 禁止对 service 返回的 error 再处理；解析/校验失败仍用 `response.NewErr`。
- 禁止跳过 `$go` 或本 Skill reference 直接改 handler。

## 交付门禁

- 已读 `api-layer.md` 与路由要求的其它 Skill。
- Handler 瘦身符合 reference。
- 已 `goimport`；能测则已测。
