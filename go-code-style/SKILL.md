---
name: go-code-style
description: "通用 Go 代码规范专家，生成、重构、评审 Go 代码风格和可维护性。Use when user asks Go 代码规范、代码风格、重构 Go、review Go、优化 if-else、减少嵌套、switch case、错误处理、函数拆分、命名规范、goimport/go vet、可读性、可维护性。Actions: design, refactor, review, implement Go code style improvements."
---

# Go Code Style

Go 代码优先简单、清晰、可维护。主流程尽量左对齐，错误和边界条件优先返回；不要写多层嵌套 `if-else`，互斥状态优先用 `switch case` 或早返回。

## Workflow

- [ ] Step 1: 识别代码意图
  - 确认函数职责、输入输出、错误语义、已有项目风格。
  - 判断问题属于控制流、命名、错误处理、context、并发、测试还是层级边界。
  - 加载 `references/go-code-style-conventions.md`，保持业务行为不变，除非用户明确要求改逻辑。
- [ ] Step 2: 优化结构
  - 错误、空值、权限、非法状态使用 guard clause / early return。
  - 复杂条件抽语义局部变量或 helper；函数只做一个清晰职责。
  - 除 `utils` 等真正通用公用方法外，尽量少写没有 receiver 的函数；业务能力优先实现为对应 struct 的方法。
  - 如果函数的主要输入是某个 struct，且逻辑只依赖或修改该 struct 的字段，例如 `buildUserPrompt(req *Request)`、`buildOptions(req *Request)`、`fillResult(result *Result)`，应改为该 struct 的 receiver 方法，例如 `(r *Request) BuildUserPrompt()`、`(r *Request) BuildOptions()`、`(r *Result) FillXXX()`。
  - 不要为一行转调、简单返回或只包一层错误信息抽无意义薄包装函数；只有当 helper 承载清晰业务步骤、复用价值、复杂分支或能明显改善主流程可读性时才抽函数。
  - 返回前如果需要对已有局部变量做最后一步转换或清理，先赋值给该变量再返回变量，例如 `raw = strings.TrimSpace(raw); return raw`，不要写成 `return strings.TrimSpace(raw)`。
  - 单文件和单行不要过长；按职责、方法组、自然边界拆分或折行。
	- 非 model 的公共 struct 可以定义到 `structs` 目录，并按职责统一存放。
		- 常量按职责统一管理，不要散落在各个函数、handler、service、DAL 或 helper 文件中。
		- 请求/参数 struct 的输入规整逻辑放到该 struct 的 `Normalize()` receiver 方法中，方法直接修改原对象并返回自身；调用方在主逻辑前调用，不在业务调用点散写 `strings.TrimSpace(req.Xxx)`。
		- `Normalize()` 遇到 nil receiver 时初始化空对象并返回，不直接返回 nil；不要新建 `normalized := *r` 这类规整副本。
		- 校验逻辑不要写成 `Validate()` 只转调私有 `validate()` 的空包装；如果没有额外职责，直接用一个 `Validate()` 承担完整校验。
		- 命名精简达意；二值/状态语义变量尽量不使用冗余 `Is` 前缀，例如用 `FirstShot`，不要用 `IsFirstShot`。
	- 短生命周期变量可用 `res`、`ans`、`input`、`output`、`cnt`，但不要遮蔽内置标识符或常见包名。
  - 变量能直接初始化就用 `in := Hello{}`，避免 `var in Hello` 后续再赋值。
- [ ] Step 3: 处理 Go 关键约束
  - 入参、出参优先使用明确 struct 或具体类型，尽量少用 `any`、`interface{}` 或宽泛数据 interface。
  - 入参、出参通常各不超过 3 个；超过时优先抽 param/result struct 或 option。
  - struct 中的数值字段如无特殊原因统一使用 Go 类型 `int64`；其他数值类型需要有明确理由。
  - JSON tag 不要直接使用 `omitempty`，避免字段在响应或序列化中被隐式省略。
  - 代码注释使用中文；日志内容使用英文。
  - I/O、DB、缓存、RPC、耗时任务传递上游 `ctx`。
  - goroutine 必须有退出条件或明确生命周期，并且必须 recover。
  - 只在减少真实复杂度时新增抽象。
- [ ] Step 4: 应用工具
  - `import` 统一使用括号形式；即使只有一个包，也写成 `import (...)`，不要写单行 `import "strings"`。
  - 修改 Go 文件后运行 `goimport`。
  - 能运行测试时运行相关 package 的 `go test`；无法运行时说明原因。
- [ ] Step 5: 交付
  - 运行 Pre-Delivery Checklist。

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
