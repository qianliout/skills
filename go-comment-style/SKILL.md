---
name: go-comment-style
description: "Go 中文注释规范专家。Use when writing, refactoring, reviewing, or explaining Go comments, doc comments, field comments, function comments, struct comments, package comments, model comments, or deciding whether comments are necessary."
---

# Go Comment Style

Go 注释只补充代码本身表达不了的信息。所有代码注释用中文；命名清楚时不要补注释。

## Workflow

1. 先问：删掉注释后是否会误解业务约束、历史兼容、单位、协议、并发/事务/缓存边界或危险副作用？
2. 需要细则时加载 `references/go-comment-conventions.md`。
3. 保留的注释必须简短、中文，说明原因、约束或边界。
4. 能通过更好命名表达时，优先改命名，不用注释兜底。
5. 修改 Go 文件后运行 `goimport`；能运行时执行相关 `go test`。

## Rules

- 必要才注释：业务约束、历史兼容、特殊单位/协议、非常规实现、并发/事务/缓存边界、危险副作用。
- 不注释见名知义的字段、函数、类型。
- model 常规字段默认不注释：`ID`、`UniqueID`、`Name`、`Status`、`CreatedAt`、`UpdatedAt`、`DeletedAt`。
- 禁止复述型注释：`// ID 主键ID`、`// UniqueID 唯一ID`、`// Name 名称`、`// GetUser 获取用户`。

## Reference Loading

新增、删除、评审或重写 Go 注释时，按需加载 `references/go-comment-conventions.md`。

## Pre-Delivery Checklist

- [ ] 注释都解释原因、约束、边界或历史背景，而不是翻译标识符。
- [ ] 能靠命名表达的内容已优先通过命名解决。
- [ ] 常规 model 字段没有复述型注释。
- [ ] 保留注释为中文、简短、可长期维护。
