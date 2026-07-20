---
name: go-comment-style
description: "Go 注释规范 Skill。Use when writing, deleting, refactoring, reviewing, or explaining Go comments, doc comments, field comments, model field comments, exported identifier comments, and Chinese comment style."
---

# Go Comment Style

用于 Go 注释新增、删除、重写和评审。Go 注释只补充代码本身表达不了的信息；所有代码注释用中文，命名清楚时不要补注释。

## Workflow

1. 判断注释是否说明业务约束、历史兼容、特殊单位/协议、并发/事务/缓存边界或危险副作用。
2. 读取 `references/comment-style.md`；需要细则时读取 `references/comment-style-conventions.md`。
3. 能通过更好命名表达时，优先改命名，不用注释兜底。
4. 删除或避免复述型注释；保留的注释必须简短、中文、可长期维护。
5. 修改 Go 文件后运行 `goimport`；能定位包或测试时运行最小范围 `go test`。

## Comment Boundaries

- 不注释见名知义的字段、函数、类型。
- model 常规字段默认不注释：`ID`、`UniqueID`、`Name`、`Status`、`CreatedAt`、`UpdatedAt`、`DeletedAt`。
- 禁止复述型注释，例如 `// ID 主键ID`、`// Name 名称`、`// GetUser 获取用户`。

## Pre-Delivery Checklist

- 已读取必要 reference。
- 注释解释原因、约束、边界或历史背景，而不是翻译标识符。
- 能靠命名表达的内容已优先通过命名解决。
- 修改 Go 文件后已运行 `goimport`；能运行时已执行相关 `go test`。
