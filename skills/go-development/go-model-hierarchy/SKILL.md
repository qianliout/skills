---
name: go-model-hierarchy
description: "用于编写、重构、评审、排查或解释 Go domain/GORM model、param、response、校验或字段生命周期时。"
---

# Go Model Hierarchy

Model 层拥有字段契约与生命周期。禁止把 HTTP 适配或 DB 会话管理塞进 model。

## 强制工作流

1. 必须先经 `$go`。
1. 必须读 `references/model-hierarchy.md`。
1. 触及注释/风格/DAL/service/API/测试时必须加载对应 `go-*`。
1. 先定模型树再写 struct；`Serialize`/`Deserialize`/`ToUpdater`/`Check`/`Same` 禁止互相调用。
1. 修改后必须 `goimport`；能测必须 `go test`。

## 禁止清单

- 禁止 JSON tag `omitempty`。
- 禁止生命周期方法互相调用。
- 禁止在 model 默认路径打业务日志。

## 交付门禁

- 已读 model-hierarchy reference 与所需跨层 Skill。
- 字段契约与生命周期符合 reference。
- 已 `goimport`；能测则已测。
