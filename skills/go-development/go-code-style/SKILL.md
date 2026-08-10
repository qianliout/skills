---
name: go-code-style
description: "用于编写、重构、评审、排查或解释 Go 通用代码风格、注释或日志时。"
---

# Go Code Style

本 Skill 覆盖通用代码风格、注释与日志。任务属于 API/Service/DAL/Model/Test/OpenAPI 时，必须先经 `$go` 路由，并另外加载对应层 Skill；禁止用本 Skill 替代层职责。

## 强制工作流

1. 确认变更范围与是否触及其它层；触及则必须同时加载对应 `go-*`。
1. 风格任务必须读 `references/code-style.md`。
1. 注释任务必须读 `references/comment-style.md`。
1. 日志任务必须读 `references/logging.md`。
1. 同时涉及多项时全部读取；禁止只读其一却改其它领域。
1. 修改 Go 文件后必须 `goimport`；能测必须最小范围 `go test`。

## 禁止清单

- 禁止把业务编排、HTTP 适配、DB 访问塞进「风格清理」。
- 禁止新增复述型注释；命名能表达则禁止用注释凑数。
- 禁止在 DAL/Model 默认路径新增业务日志。
- 禁止日志 Msg 使用中文；禁止注释使用英文（标识符除外）。
- 禁止软性逃避措辞。

## 交付门禁

- 已读本次涉及的全部 reference。
- 风格/注释/日志边界未互相污染层职责。
- 已 `goimport`；能测则已测试。
