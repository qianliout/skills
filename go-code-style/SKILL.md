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
4. 优化职责归属：业务能力优先实现为对应 struct 的 receiver 方法；避免无意义薄包装函数。
5. 收敛结构：常量按职责统一管理；非 model 公共 struct 按项目约定统一存放；请求/参数规整放到 `Normalize()` receiver 方法。
6. 处理 Go 约束：入参/出参优先具体类型；数值字段默认 `int64`；JSON tag 不直接使用 `omitempty`；I/O 传递上游 `ctx`。
7. 应用工具：`import` 使用括号形式；修改 Go 文件后运行 `goimport`，能运行时执行相关 `go test`。

## Reference Loading

生成、重构或评审 Go 代码风格时，必须加载 `references/go-code-style-conventions.md`。

## Pre-Delivery Checklist

- [ ] 代码遵循项目现有风格和命名习惯。
- [ ] 没有多层嵌套 `if-else`；主流程左对齐，错误和边界条件优先返回。
- [ ] 函数职责清晰；过长函数、文件、单行已合理拆分或折行。
- [ ] 除真正通用的 `utils` 方法外，业务函数优先作为对应 struct 的 receiver 方法，没有大量无归属裸函数。
- [ ] 没有把明显属于某个 struct 的行为写成以该 struct 为首参的裸 helper；此类逻辑已归属为 receiver 方法。
- [ ] 没有无意义薄包装函数；一行转调、简单返回或只包一层错误信息的 helper 已内联，除非它有清晰业务语义或复用价值。
- [ ] 非 model 的公共 struct 已按项目约定统一存放，必要时放到 `structs` 目录。
- [ ] 常量已按职责统一管理，没有散落在各个函数或业务文件中。
- [ ] 请求/参数 struct 的 `Normalize()` 是 receiver 方法，直接修改原对象并返回自身；nil receiver 会初始化为空对象；业务逻辑中没有散落的参数 trim/default 处理。
- [ ] 校验逻辑没有 `Validate()` 空转调私有 `validate()` 这类重复包装；公开 `Validate()` 已直接表达完整校验职责。
- [ ] 命名精简达意，没有无意义编号、过度冗长变量名、冗余 `Is` 前缀、内置标识符或常见包名遮蔽。
- [ ] 变量声明优先直接初始化，没有不必要的 `var in Hello` 空声明。
- [ ] 入参、出参优先使用明确 struct 或具体类型；没有滥用 `any`、`interface{}`。
- [ ] 入参、出参通常不超过 3 个；超过时已有 struct、result struct、option 或明确理由。
- [ ] struct 数值字段默认使用 Go 类型 `int64`；使用其他数值类型时有明确理由。
- [ ] JSON tag 没有直接使用 `omitempty`。
- [ ] `import` 已统一使用括号形式；没有单行 `import "xxx"`。
- [ ] 返回前对已有局部变量的最后一步转换已拆成赋值再返回；没有 `return strings.TrimSpace(raw)` 这类把清理逻辑塞进 return 的写法。
- [ ] 代码注释使用中文，日志内容使用英文。
- [ ] 错误处理没有吞错；ctx 传递正确。
- [ ] goroutine 有退出条件/生命周期说明，并有 recover 防护。
- [ ] Go 文件已运行 `goimport`；能运行测试时已运行相关 `go test`。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
