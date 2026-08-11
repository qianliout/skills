---
name: go-code-style
description: "Go 通用代码风格 Skill。Use when writing, refactoring, reviewing, debugging, or explaining general Go code style, control flow, naming, error handling, dependency boundaries, receiver conventions, imports, gofmt/goimports, or maintainability rules."
---

# Go Code Style

用于 Go 通用代码风格、可维护性和跨层基础约定。它不替代 API、Service、DAL、Model、Logging、Comment 或 Test 专项 Skill；任务明显属于某层时，先使用对应专项 Skill，再按需组合本 Skill。

## Workflow

1. 确认任务意图、允许变更范围、现有项目风格和是否涉及其它 Go 分层。
2. 读取 `references/code-style.md` 和 `references/code-style-conventions.md`。
3. 保持业务行为不变，优先优化控制流、命名、错误处理、依赖注入、receiver、常量、时间字段、JSON tag、ctx 和 goroutine recover。
4. 多层任务按职责组合其它 Go 分类 Skill；不要把通用风格规则变成跨层职责迁移。
5. 修改 Go 文件后运行 `goimport`；能定位包或测试时运行最小范围 `go test`。

## Core Boundaries

- 主流程尽量左对齐；错误、空值、权限和非法状态优先 early return。
- 依赖通过构造函数、初始化或启动阶段保证；业务方法内不临时创建长期依赖，也不用 nil 依赖跳过业务逻辑。
- 所有方法使用一致的指针接收者；同一 struct 的 receiver 名称保持一致。
- 代码注释和日志内容都用英文；注释只写 why，默认单行。

## Pre-Delivery Checklist

- 已读取本 Skill 的两个 reference。
- 控制流、命名、receiver、错误处理、依赖注入和 import 符合 reference。
- 没有改变无关业务行为或把某层职责搬到另一层。
- 修改 Go 文件后已运行 `goimport`；能运行时已执行相关 `go test`。
