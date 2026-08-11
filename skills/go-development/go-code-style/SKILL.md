---
name: go-code-style
description: "用于编写、重构、评审、排查或解释 Go 通用代码风格、注释、日志、early return、薄包装、receiver、goimport 或 LogStr 时。"
---

# Go Code Style

本 Skill 覆盖通用代码风格、注释与日志。任务属于 API/Service/DAL/Model/Test/OpenAPI 时，必须先经 `$go` 路由，并另外加载对应层 Skill；禁止用本 Skill 替代层职责。

## 强制工作流

1. 确认变更范围与是否触及其它层；触及则必须同时加载对应 `go-*`。
2. 风格任务必须读 `references/code-style.md`。
3. 注释任务必须读 `references/comment-style.md`。
4. 日志任务必须读 `references/logging.md`。
5. 同时涉及多项时全部读取；禁止只读其一却改其它领域。
6. 触及字段生命周期时必须加载 `go-model-hierarchy`；触及业务错误包装时必须加载 `go-service-layer`；触及 handler 错误返回时必须加载 `go-api-layer`。
7. 修改 Go 文件后必须 `goimport`；能测必须最小范围 `go test`。

## 禁止清单

- 禁止把业务编排、HTTP 适配、DB 访问塞进「风格清理」。
- 禁止新增复述型或冗余注释；命名能表达则禁止用注释凑数。
- 禁止在 DAL/Model 默认路径新增业务日志。
- 禁止日志 Msg 使用中文；注释必须使用英文；禁止注释使用中文。
- 禁止新增 `Normalize()`、`FillDefault()` 或同职责 helper 替代 `Serialize()`。

## 交付门禁

- 已读本次涉及的全部 reference。
- 风格/注释/日志边界未互相污染层职责。
- 已 `goimport`；能测则已测试。
