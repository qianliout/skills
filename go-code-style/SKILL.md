---
name: go-code-style
description: "Go 代码风格和可维护性专家。Use when writing, refactoring, or reviewing Go style, control flow, if-else nesting, switch cases, error handling, function splitting, receiver methods, naming, imports, goimport, go vet, readability, or maintainability."
---

# Go Code Style

Go 代码优先简单、清晰、可维护。主流程尽量左对齐，错误和边界条件优先返回；不要写多层嵌套 `if-else`，互斥状态优先用 `switch case` 或早返回。

## Shared Rules

- 新写 Go 代码必须同时遵循当前任务触发的 Go skill；多层同时涉及时，按 API 适配 HTTP、service 编排业务和依赖、DAL 访问持久化、model 管理字段生命周期、logging 管理日志边界来组合。
- 行为优先归属到拥有状态或职责的 struct pointer receiver；除真正通用的 `utils` 外，少写无归属包级函数。
- 长期依赖必须通过构造函数或明确字段注入；不要在业务方法里临时创建 service、DAL、client、cache、logger。
- 函数粒度保持可读：主流程保留 3-7 个同一抽象层级的业务步骤，避免一个函数塞太多阶段，也避免拆成薄 helper 链。
- 所有方法使用指针接收者；receiver 命名统一为 service=`s`、DAL=`dal`、API=`api`、名字含 Param 的 model 层类型=`p`、其他 model 层对象=`vi`。
- JSON tag 不能写 `omitempty`；新表或新功能的所有时间相关字段、DB 存储和前后端传参都使用毫秒级 `int64` 时间戳。

## Workflow

1. 识别代码意图：确认函数职责、输入输出、错误语义、已有项目风格、已触发的 Go skill 约束，以及是否允许改变业务逻辑。
2. 加载 `references/go-code-style-conventions.md`，保持业务行为不变，除非用户明确要求改逻辑。
3. 优化控制流：错误、空值、权限、非法状态使用 guard clause / early return；复杂条件优先抽语义变量，只有命名后能显著降低阅读成本时才抽 helper。
4. 优化职责归属：业务能力优先实现为对应 struct 的 pointer receiver 方法，尽量少写包内裸函数；同一个 struct 不能同时存在值接收者和指针接收者方法，发现混用时统一改成指针接收者；所有方法接收者都使用指针接收者，不能使用值接收者；receiver 命名按层统一：service=`s`、DAL=`dal`、API=`api`、名字含 Param 的 model 层类型=`p`、其他 model 层对象=`vi`；避免无意义薄包装函数。
5. 平衡函数粒度：一个函数保持同一抽象层级，通常呈现 3-7 个有业务语义的步骤；拆分只在跨数据域、可复用、有清晰命名收益、隔离副作用或主流程已经难以一屏理解时进行；不要把一两行转调、简单条件、简单赋值拆成跳转成本更高的 helper。
6. 收敛结构：常量按职责统一管理；非 model 公共 struct 按项目约定统一存放；领域规整逻辑尽量挂到拥有这些字段的 struct 上，统一收敛到公有 `Serialize()` 方法；不要新增 `Normalize()`、`FillDefault()` 或小写规整方法；`Serialize()`、`Deserialize()`、`ToUpdater()`、`Check()`、`Same()` 之间不互相调用，组合顺序由外部决定；包级函数只保留真正通用、无明确归属的工具。
7. 处理 Go 约束：入参/出参优先具体类型；调用函数或方法时，入参必须是变量或简单字段访问，不能直接传另一个函数/方法的执行结果；slice/map 作为返回值时必须先实例化，所有返回路径都不能返回 nil slice/map；数值字段默认 `int64`；新表或新功能的时间字段统一使用 `int64` 毫秒级时间戳，已有功能不强制迁移；任何 JSON tag 都不能写 `omitempty`；I/O 传递上游 `ctx`。
8. 应用工具：`import` 使用括号形式；修改 Go 文件后运行 `goimport`，能运行时执行相关 `go test`。

## Reference Loading

生成、重构或评审 Go 代码风格时，必须加载 `references/go-code-style-conventions.md`。

## Pre-Delivery Checklist

- [ ] 代码遵循项目现有风格和命名习惯。
- [ ] 新写代码已优先遵循当前任务触发的 Go skill 规则；多个 skill 同时适用时，按各层职责组合执行。
- [ ] 没有多层嵌套 `if-else`；主流程左对齐，错误和边界条件优先返回。
- [ ] 函数职责清晰；既没有一个函数塞入过多阶段，也没有拆成大量无命名收益的小 helper。
- [ ] 函数粒度平衡：主函数保留 3-7 个同一抽象层级的清晰步骤；helper 只有在跨数据域、可复用、隔离副作用或显著提升主流程可读性时存在。
- [ ] 除真正通用的 `utils` 方法外，业务函数优先作为对应 struct 的 receiver 方法，没有大量无归属裸函数。
- [ ] 同一个 struct 没有混用值接收者和指针接收者；发现 `func (vi Xxx) ...` 与 `func (vi *Xxx) ...` 并存时，已统一改成 `func (vi *Xxx) ...`。
- [ ] 所有方法接收者都是指针接收者；receiver 命名按层统一：service=`s`、DAL=`dal`、API=`api`、名字含 Param 的 model 层类型=`p`、其他 model 层对象=`vi`；没有值接收者。
- [ ] 没有把明显属于某个 struct 的行为写成以该 struct 为首参的裸 helper；此类逻辑已归属为 receiver 方法。
- [ ] trim、default、normalize、derive、fill 等领域规整逻辑已挂到拥有相关字段的 struct 上，并统一进入公有 `Serialize()`；没有新增 `Normalize()`、`FillDefault()` 或小写规整方法；包级函数只保留真正跨领域、无字段归属的通用工具。
- [ ] 没有无意义薄包装函数；一行转调、简单返回或只包一层错误信息的 helper 已内联，除非它有清晰业务语义或复用价值。
- [ ] `Serialize()`、`Deserialize()`、`ToUpdater()`、`Check()`、`Same()` 内部没有互相调用；这些方法的组合完全由外部调用方决定。
- [ ] 单个领域方法尽量在一个函数内完成，没有为同一 struct 拆出私有规整/校验/比较 helper，除非调用的是真正通用、无字段归属的工具。
- [ ] 非 model 的公共 struct 已按项目约定统一存放，必要时放到 `structs` 目录。
- [ ] 常量已按职责统一管理，没有散落在各个函数或业务文件中。
- [ ] `Serialize()`、`Deserialize()`、`ToUpdater()`、`Check()`、`Same()` 这组领域生命周期方法使用固定的大写签名：`Serialize() *Xxx`、`Deserialize() *Xxx`、`ToUpdater() map[string]interface{}`、`Check() error`、`Same(after *Xxx) bool`；这组方法没有小写变体或自定义签名。GORM、标准库接口或项目框架适配方法按其要求保留固定签名，例如 `TableName() string`。
- [ ] 校验逻辑没有 `Validate()` 空转调私有 `validate()` 这类重复包装；公开 `Validate()` 已直接表达完整校验职责。
- [ ] 命名精简达意，没有无意义编号、过度冗长变量名、冗余 `Is` 前缀、内置标识符或常见包名遮蔽。
- [ ] 变量声明优先直接初始化，没有不必要的 `var in Hello` 空声明。
- [ ] 入参、出参优先使用明确 struct 或具体类型；没有滥用 `any`、`interface{}`。
- [ ] 入参、出参通常不超过 3 个；超过时已有 struct、result struct、option 或明确理由。
- [ ] 函数/方法调用的实参已先赋值给有语义的局部变量；没有 `Generate(ctx, buildTextMessages(prompt, opts))`、`Run(ctx, buildRequest())` 这类直接把函数/方法调用结果作为入参的写法。
- [ ] struct 数值字段默认使用 Go 类型 `int64`；使用其他数值类型时有明确理由。
- [ ] 新表或新功能的时间相关字段、参数和响应统一使用 `int64` 毫秒级时间戳；已有功能没有被无意迁移时间单位。
- [ ] 所有 JSON tag 都没有 `omitempty`。
- [ ] `import` 已统一使用括号形式；没有单行 `import "xxx"`。
- [ ] 返回前对调用结果或已有局部变量的最后一步转换已拆成赋值再返回；任何函数/方法调用结果都没有直接作为 return 表达式，方便断点调试返回值。
- [ ] slice/map 作为返回值时已用 `make` 或字面量实例化，所有成功和错误返回路径都没有返回 nil slice/map。
- [ ] 代码注释使用中文，日志内容使用英文。
- [ ] 错误处理没有吞错；ctx 传递正确。
- [ ] goroutine 有退出条件/生命周期说明，并有 recover 防护。
- [ ] Go 文件已运行 `goimport`；能运行测试时已运行相关 `go test`。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
