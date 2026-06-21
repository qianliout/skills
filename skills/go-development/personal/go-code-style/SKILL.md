---
name: go-code-style
description: "Go 代码风格和可维护性专家。Use when writing, refactoring, reviewing, debugging, or explaining Go style, control flow, if-else nesting, switch cases, error handling, function splitting, helper extraction, receiver methods, naming, imports, goimport, go vet, readability, maintainability, goroutine recovery, JSON tags, int64 conventions, or repository-wide Go code rules."
---

# Go Code Style

Go 代码优先简单、清晰、可维护。主流程尽量左对齐，错误和边界条件优先返回；不到万不得已不要使用 `if-else` 或 `else if`，优先 guard clause 或 `switch`。

## Workflow

1. 识别代码意图：职责、输入输出、错误语义、已有项目风格、触发的 Go skill，以及是否允许改变业务逻辑。
2. 加载 `references/go-code-style-conventions.md`；除非用户明确要求，不改变业务行为。
3. 优化控制流：错误、空值、权限、非法状态使用 early return；复杂条件优先抽语义变量，只有明显降低阅读成本时才抽 helper。
4. 优化职责归属：行为优先挂到拥有状态或职责的 struct pointer receiver；除真正通用 `utils` 外，少写无归属包级函数。
5. 平衡函数粒度：主流程保留 3-7 个同抽象层级业务步骤；只在复用、稳定语义、隔离副作用、复杂分支或明显改善阅读时拆 helper。
6. 审核防御分支：只在输入边界、外部系统、真实 panic 风险、明确允许 nil/zero 的 public contract 或 model nil receiver 生命周期方法里新增防御检查。
7. 收敛领域生命周期：规整逻辑归属到拥有字段的 `Serialize()`；`Serialize()`、`Deserialize()`、`ToUpdater()`、`Check()`、`Same()` 不互相调用。
8. 应用项目硬约束：指针接收者、receiver 命名、`int64` 默认数值类型、毫秒级时间戳、JSON tag 不写 `omitempty`、slice/map 返回前初始化、I/O 传递上游 `ctx`、新 goroutine 必须 recover。
9. 修改 Go 文件后运行 `goimport`；能运行时执行相关 `go test`。

## Shared Rules

- 多层同时涉及时，按 API 适配 HTTP、service 编排业务、DAL 访问持久化、model 管理字段生命周期、logging 管理日志边界来组合。
- 长期依赖必须通过构造函数或明确字段注入；业务方法内不临时创建 service、DAL、client、cache、logger，也不能用 nil 依赖跳过业务逻辑。
- 所有方法使用指针接收者；同一个 struct 的接收者形式和变量名必须一致。常用命名：service=`s`、DAL=`dal`、API=`api`、名字含 Param 的 model 类型=`p`、其他 model 对象=`vi`。
- 常量统一放到项目定义的 `consts` 目录；不要散落在 model、API、service、DAL、helper 或函数体中。
- 字段、参数、返回值和层间传递默认使用 `int64`；只有外部协议、第三方库、明确性能/存储边界或既有兼容约束需要时才使用其它数值类型。
- 新表或新功能的时间字段统一使用毫秒级 `int64` 时间戳。
- 任何 JSON tag 都不能写 `omitempty`。

## Reference Loading

生成、重构或评审 Go 代码风格时，必须加载 `references/go-code-style-conventions.md`。

## Pre-Delivery Checklist

- [ ] 已结合当前任务触发的 Go 子 skill；职责没有跨层侵入。
- [ ] 控制流左对齐：错误、空值、权限和非法状态优先返回；没有不必要的 `if-else` / `else if`。
- [ ] 函数职责清晰，主流程保持同一抽象层级；没有薄 helper 链或无归属裸函数。
- [ ] 新增 helper 和防御检查都有明确必要性；没有用静默降级掩盖内部错误。
- [ ] 长期依赖由构造、初始化或启动阶段保证；业务方法内没有依赖 nil 跳过逻辑。
- [ ] 所有方法使用一致的指针接收者和层级 receiver 命名。
- [ ] 领域规整归属到拥有字段的 `Serialize()`；生命周期方法不互相调用。
- [ ] 常量、时间字段、JSON tag、数值类型、slice/map 返回值、ctx、goroutine recovery、import 均符合 reference 规则。
- [ ] Go 文件已运行 `goimport`；能运行测试时已运行相关 `go test`。
