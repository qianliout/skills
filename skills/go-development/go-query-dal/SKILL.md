---
name: go-query-dal
description: "用于编写、重构、评审、排查或解释 Go store/DAL/DAO、GORM 查询、CRUD 或持久化边界时。"
---

# Go Query DAL

DAL 只编排持久化。禁止承载业务规则。一个 DAL 方法只围绕一个主要 data model。细则与合法形态示例见 `references/query-dal.md`。

## 强制工作流

1. 必须先经 `$go`。
1. 必须读 `references/query-dal.md`。
1. 触及 model/service/风格/日志/测试时必须加载对应 `go-*`。
1. 每个 DB 方法必须创建 timeout context，并 `WithContext(cancelCtx)`；表名必须来自主要 model 的 `TableName()`。
1. 修改后必须 `goimport`；能测必须 `go test`。

## 禁止清单

- 禁止在 DAL 写业务决策、跨资源业务聚合。
- 禁止默认在 DAL 打业务日志。
- 禁止无 timeout 的 DB 调用。
- 禁止 `return db.Xxx(...).Error`；必须先取 err 再分支返回。
- 禁止 DAO helper/私有拆分方法；一个公开方法必须写完全部执行逻辑。
- 禁止跳过 reference 或偏离其中示例的确定顺序。

## 交付门禁

- 已读 query-dal reference 与所需跨层 Skill。
- 签名、receiver（`dal`）、流水线顺序符合 reference。
- 已 `goimport`；能测则已测。
