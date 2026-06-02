---
name: go-code-style
description: "Go 代码风格和可维护性专家。Use when writing, refactoring, or reviewing Go style, control flow, if-else nesting, switch cases, error handling, function splitting, receiver methods, naming, imports, goimport, go vet, readability, or maintainability."
---

# Go Code Style

Go 代码优先简单、清晰、可维护。主流程尽量左对齐，错误和边界条件优先返回；不要写多层嵌套 `if-else`，互斥状态优先用 `switch case` 或早返回。

## Shared Rules

- 新写 Go 代码必须同时遵循当前任务触发的 Go skill；多层同时涉及时，按 API 适配 HTTP、service 编排业务和依赖、DAL 访问持久化、model 管理字段生命周期、logging 管理日志边界来组合。
- 行为优先归属到拥有状态或职责的 struct pointer receiver；除真正通用的 `utils` 外，少写无归属包级函数。
- 长期依赖必须通过构造函数或明确字段注入；不要在业务方法里临时创建 service、DAL、client、cache、logger；不能因为注入依赖为 nil 就跳过调用、校验、写入、日志或其它业务逻辑。
- 函数粒度保持可读：主流程保留 3-7 个同一抽象层级的业务步骤，避免一个函数塞太多阶段，也避免拆成薄 helper 链。
- 所有方法使用指针接收者；同一个 struct 的所有方法接收者必须一致，包括指针/值形式和 receiver 变量名；receiver 命名统一为 service=`s`、DAL=`dal`、API=`api`、名字含 Param 的 model 层类型=`p`、其他 model 层对象=`vi`。
- JSON tag 不能写 `omitempty`；项目内数值类型默认统一使用 `int64`，字段、参数、返回值和层间传递都遵循这个默认；除非外部协议、第三方库签名、明确性能/存储边界或既有兼容约束确有必要，不新增 `int`、`int32`、`uint`、`uint64` 等其它数值类型，也不要仅为兼容旧实现保留非 `int64` 数值类型；新表或新功能的所有时间相关字段、DB 存储和前后端传参都使用毫秒级 `int64` 时间戳；除非确有必要，避免新增基础包装类型，如 `type Kind string`。

## Workflow

1. 识别代码意图：确认函数职责、输入输出、错误语义、已有项目风格、已触发的 Go skill 约束，以及是否允许改变业务逻辑。
2. 加载 `references/go-code-style-conventions.md`，保持业务行为不变，除非用户明确要求改逻辑。
3. 优化控制流：错误、空值、权限、非法状态使用 guard clause / early return；复杂条件优先抽语义变量，只有命名后能显著降低阅读成本时才抽 helper。
4. 优化职责归属：业务能力优先实现为对应 struct 的 pointer receiver 方法，尽量少写包内裸函数；同一个 struct 不能同时存在值接收者和指针接收者方法，发现混用时统一改成指针接收者；同一个 struct 的 receiver 变量名也必须一致；所有方法接收者都使用指针接收者，不能使用值接收者；receiver 命名按层统一：service=`s`、DAL=`dal`、API=`api`、名字含 Param 的 model 层类型=`p`、其他 model 层对象=`vi`；避免无意义薄包装函数。
5. 平衡函数粒度：一个函数保持同一抽象层级，通常呈现 3-7 个有业务语义的步骤；拆分只在跨数据域、可复用、有清晰命名收益、隔离副作用或主流程已经难以一屏理解时进行；不要把一两行转调、简单条件、简单赋值拆成跳转成本更高的 helper。
6. 收敛结构：所有常量统一放到项目定义的 `consts` 目录下，不能散落在 model、API、service、DAL、helper 或函数体中；非 model 公共 struct 按项目约定统一存放；领域规整逻辑尽量挂到拥有这些字段的 struct 上，统一收敛到公有 `Serialize()` 方法；不要新增 `Normalize()`、`FillDefault()` 或小写规整方法；`Serialize()`、`Deserialize()`、`ToUpdater()`、`Check()`、`Same()` 之间不互相调用，组合顺序由外部决定；包级函数只保留真正通用、无明确归属的工具。
7. 处理 Go 约束：入参/出参优先具体类型；调用函数或方法时，入参必须是变量或简单字段访问，不能直接传另一个函数/方法的执行结果；slice/map 作为返回值时必须先实例化，所有返回路径都不能返回 nil slice/map；项目内字段、参数、返回值和层间传递中的数值类型默认统一使用 `int64`；除非外部接口、第三方库签名、明确性能/存储边界或既有兼容约束确有必要，不新增 `int`、`int32`、`uint`、`uint64` 等其它数值类型，也不要仅为兼容旧实现保留非 `int64` 数值类型；字段和参数优先使用 `string`、`int64` 等基础类型，除非外部接口、第三方库、明确方法集或类型安全边界确实需要，避免新增基础包装类型，如 `type Kind string`；新表或新功能的时间字段统一使用 `int64` 毫秒级时间戳，已有功能不强制迁移；任何 JSON tag 都不能写 `omitempty`；I/O 传递上游 `ctx`；长期依赖的非 nil 保证由构造、初始化或启动阶段负责，业务方法内不能用 nil 依赖作为跳过逻辑的条件。
8. 应用工具：`import` 使用括号形式；修改 Go 文件后运行 `goimport`，能运行时执行相关 `go test`。

## Reference Loading

生成、重构或评审 Go 代码风格时，必须加载 `references/go-code-style-conventions.md`。

## Pre-Delivery Checklist

- [ ] 已优先遵循当前任务触发的 Go skill；多层同时涉及按 API/service/DAL/model/logging/comment 职责组合。
- [ ] 控制流左对齐：错误、空值、权限和非法状态优先返回，没有多层嵌套 `if-else`。
- [ ] 函数职责清晰，主流程保持 3-7 个同层级步骤；没有薄 helper 链或无归属裸函数。
- [ ] 接口和公开方法保持资源/动作级别；没有 `SearchXxxForUser`、`UpdateXxxForProject` 这类场景化方法名。
- [ ] 长期依赖由构造、初始化或启动阶段保证非 nil；业务方法内没有依赖 nil 跳过逻辑。
- [ ] 所有方法使用一致的指针接收者和层级 receiver 命名。
- [ ] 领域规整归属到拥有字段的 struct，并统一进入公有 `Serialize()`；生命周期方法不互相调用。
- [ ] 常量、时间字段、JSON tag、数值类型、slice/map 返回值、注释/日志语言、ctx、goroutine、import、return 调试价值均符合 reference 规则。
- [ ] Go 文件已运行 `goimport`；能运行测试时已运行相关 `go test`。
