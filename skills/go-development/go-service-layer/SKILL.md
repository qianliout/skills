---
name: go-service-layer
description: "用于编写、重构、评审、排查或解释 Go service 接口、构造注入、业务编排或错误包装时。"
---

# Go Service Layer

Service 负责业务编排。禁止直接访问 DB、GORM、SQL。禁止把 DAL/Model 职责搬进 service。

## 强制工作流

1. 必须先经 `$go`。
1. 必须读 `references/service-layer.md`。
1. 触及 DAL/Model/日志/风格/测试时必须加载对应 `go-*`。
1. interface、struct、constructor 必须同步；依赖必须显式注入。
1. 修改后必须 `goimport`；能测必须 `go test`。

## 禁止清单

- 禁止 service 内临时 new 长期依赖或用 nil 依赖跳过逻辑。
- 禁止直接 DB/GORM/SQL。
- 禁止无用户确认擅自把已有多参数导出方法改成其它形状（分层已规定签名除外）。

## 交付门禁

- 已读 service-layer reference 与所需跨层 Skill。
- 依赖注入与边界符合 reference。
- 已 `goimport`；能测则已测。
