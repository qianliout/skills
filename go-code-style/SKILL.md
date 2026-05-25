---
name: go-code-style
description: "Go 代码风格和可维护性专家。Use when writing, refactoring, or reviewing Go style, control flow, if-else nesting, switch cases, error handling, function splitting, receiver methods, naming, imports, goimport, go vet, readability, or maintainability."
---

# Go Code Style

Go 代码优先简单、清晰、可维护。主流程尽量左对齐，错误和边界条件优先返回；不要写多层嵌套 `if-else`，互斥状态优先用 `switch case` 或早返回。

## Workflow

1. 识别代码意图：确认函数职责、输入输出、错误语义、已有项目风格和是否允许改变业务逻辑。
2. 加载 `references/go-code-style-conventions.md`，保持业务行为不变，除非用户明确要求改逻辑。
3. 优化控制流：错误、空值、权限、非法状态使用 guard clause / early return；复杂条件抽语义变量或 helper。
4. 优化职责归属：业务能力优先实现为对应 struct 的 pointer receiver 方法；所有方法接收者都使用指针接收者，不能使用值接收者；避免无意义薄包装函数。
5. 收敛结构：常量按职责统一管理；非 model 公共 struct 按项目约定统一存放；领域规整逻辑尽量挂到拥有这些字段的 struct 上，统一收敛到公有 `Serialize()` 方法；不要新增 `Normalize()`、`FillDefault()` 或小写规整方法；`Serialize()`、`Deserialize()`、`ToUpdater()`、`Check()`、`Same()` 之间不互相调用，组合顺序由外部决定；包级函数只保留真正通用、无明确归属的工具。
6. 处理 Go 约束：入参/出参优先具体类型；调用函数或方法时，入参必须是变量或简单字段访问，不能直接传另一个函数/方法的执行结果；slice/map 作为返回值时必须先实例化，所有返回路径都不能返回 nil slice/map；数值字段默认 `int64`；JSON tag 不直接使用 `omitempty`；I/O 传递上游 `ctx`。
7. 应用工具：`import` 使用括号形式；修改 Go 文件后运行 `goimport`，能运行时执行相关 `go test`。

## Reference Loading

生成、重构或评审 Go 代码风格时，必须加载 `references/go-code-style-conventions.md`。

## Pre-Delivery Checklist

- [ ] 代码遵循项目现有风格和命名习惯。
- [ ] 没有多层嵌套 `if-else`；主流程左对齐，错误和边界条件优先返回。
- [ ] 函数职责清晰；过长函数、文件、单行已合理拆分或折行。
- [ ] 除真正通用的 `utils` 方法外，业务函数优先作为对应 struct 的 receiver 方法，没有大量无归属裸函数。
- [ ] 所有方法接收者都是指针接收者，例如 `func (m *Xxx) Check()`；没有值接收者，例如 `func (m Xxx) Check()`。
- [ ] 没有把明显属于某个 struct 的行为写成以该 struct 为首参的裸 helper；此类逻辑已归属为 receiver 方法。
- [ ] trim、default、normalize、derive、fill 等领域规整逻辑已挂到拥有相关字段的 struct 上，并统一进入公有 `Serialize()`；没有新增 `Normalize()`、`FillDefault()` 或小写规整方法；包级函数只保留真正跨领域、无字段归属的通用工具。
- [ ] 没有无意义薄包装函数；一行转调、简单返回或只包一层错误信息的 helper 已内联，除非它有清晰业务语义或复用价值。
- [ ] `Serialize()`、`Deserialize()`、`ToUpdater()`、`Check()`、`Same()` 内部没有互相调用；这些方法的组合完全由外部调用方决定。
- [ ] 单个领域方法尽量在一个函数内完成，没有为同一 struct 拆出私有规整/校验/比较 helper，除非调用的是真正通用、无字段归属的工具。
- [ ] 非 model 的公共 struct 已按项目约定统一存放，必要时放到 `structs` 目录。
- [ ] 常量已按职责统一管理，没有散落在各个函数或业务文件中。
- [ ] 领域方法使用固定的大写签名：`Serialize() *Xxx`、`Deserialize() *Xxx`、`ToUpdater() map[string]interface{}`、`Check() error`、`Same(after *Xxx) bool`；没有小写变体或自定义签名。
- [ ] 校验逻辑没有 `Validate()` 空转调私有 `validate()` 这类重复包装；公开 `Validate()` 已直接表达完整校验职责。
- [ ] 命名精简达意，没有无意义编号、过度冗长变量名、冗余 `Is` 前缀、内置标识符或常见包名遮蔽。
- [ ] 变量声明优先直接初始化，没有不必要的 `var in Hello` 空声明。
- [ ] 入参、出参优先使用明确 struct 或具体类型；没有滥用 `any`、`interface{}`。
- [ ] 入参、出参通常不超过 3 个；超过时已有 struct、result struct、option 或明确理由。
- [ ] 函数/方法调用的实参已先赋值给有语义的局部变量；没有 `Generate(ctx, buildTextMessages(prompt, opts))`、`Run(ctx, buildRequest())` 这类直接把函数/方法调用结果作为入参的写法。
- [ ] struct 数值字段默认使用 Go 类型 `int64`；使用其他数值类型时有明确理由。
- [ ] JSON tag 没有直接使用 `omitempty`。
- [ ] `import` 已统一使用括号形式；没有单行 `import "xxx"`。
- [ ] 返回前对调用结果或已有局部变量的最后一步转换已拆成赋值再返回；任何函数/方法调用结果都没有直接作为 return 表达式，方便断点调试返回值。
- [ ] slice/map 作为返回值时已用 `make` 或字面量实例化，所有成功和错误返回路径都没有返回 nil slice/map。
- [ ] 代码注释使用中文，日志内容使用英文。
- [ ] 错误处理没有吞错；ctx 传递正确。
- [ ] goroutine 有退出条件/生命周期说明，并有 recover 防护。
- [ ] Go 文件已运行 `goimport`；能运行测试时已运行相关 `go test`。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
