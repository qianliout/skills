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
  - 单文件和单行不要过长；按职责、方法组、自然边界拆分或折行。
  - 命名精简达意；短生命周期变量可用 `res`、`ans`、`input`、`output`、`cnt`，但不要遮蔽内置标识符或常见包名。
  - 变量能直接初始化就用 `in := Hello{}`，避免 `var in Hello` 后续再赋值。
- [ ] Step 3: 处理 Go 关键约束
  - 入参、出参优先使用明确 struct 或具体类型，尽量少用 `any`、`interface{}` 或宽泛数据 interface。
  - 入参、出参通常各不超过 3 个；超过时优先抽 param/result struct 或 option。
  - I/O、DB、缓存、RPC、耗时任务传递上游 `ctx`。
  - goroutine 必须有退出条件或明确生命周期，并且必须 recover。
  - 只在减少真实复杂度时新增抽象。
- [ ] Step 4: 应用工具
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
- [ ] 命名精简达意，没有无意义编号、过度冗长变量名、内置标识符或常见包名遮蔽。
- [ ] 变量声明优先直接初始化，没有不必要的 `var in Hello` 空声明。
- [ ] 入参、出参优先使用明确 struct 或具体类型；没有滥用 `any`、`interface{}`。
- [ ] 入参、出参通常不超过 3 个；超过时已有 struct、result struct、option 或明确理由。
- [ ] 错误处理没有吞错；ctx 传递正确。
- [ ] goroutine 有退出条件/生命周期说明，并有 recover 防护。
- [ ] Go 文件已运行 `goimport`；能运行测试时已运行相关 `go test`。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
