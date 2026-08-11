# Go Comment Style

Go 注释只补充代码本身表达不了的信息。注释一律用英文，只写 why，不写 what；命名清楚时不要补注释。

## Workflow

1. 先问：删掉这条注释后，是否会误解业务约束、历史兼容、单位、协议、并发/事务/缓存边界或危险副作用？答案是"不会"就删掉。
2. 需要细则时加载 `references/comment-style-conventions.md`。
3. 保留的注释用英文写原因、约束或边界，默认单行，不超过两行。
4. 能通过更好命名表达时，优先改命名，不用注释兜底。
5. 修改 Go 文件后运行 `goimport`；能运行时执行相关 `go test`。

## Rules

- 必要才注释：业务约束、历史兼容、特殊单位/协议、非常规实现、并发/事务/缓存边界、危险副作用。
- 只写 why：解释为什么这么做、为什么不能改，不描述代码在做什么。
- 一律英文；不写中文注释，也不写中英混排。
- 精简：默认单行，一句话说清一件事；不写空洞前缀（`// Note that`、`// This function`）、不排版成段落。
- 不注释见名知义的字段、函数、类型。
- model 常规字段默认不注释：`ID`、`UniqueID`、`Name`、`Status`、`CreatedAt`、`UpdatedAt`、`DeletedAt`。
- 禁止复述型注释：`// ID is the primary key`、`// Name is the name`、`// GetUser gets a user`。

## Reference Loading

新增、删除、评审或重写 Go 注释时，按需加载 `references/comment-style-conventions.md`。

## Pre-Delivery Checklist

- [ ] 每条注释都在解释原因、约束、边界或历史背景，而不是翻译标识符。
- [ ] 注释全部为英文，无中文、无中英混排。
- [ ] 注释精简，默认单行，没有空洞前缀和排版段落。
- [ ] 能靠命名表达的内容已优先通过命名解决。
- [ ] 常规 model 字段没有复述型注释。
