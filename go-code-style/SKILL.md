---
name: go-code-style
description: "通用 Go 代码规范专家，生成、重构、评审 Go 代码风格和可维护性。Use when user asks Go 代码规范、代码风格、重构 Go、review Go、优化 if-else、减少嵌套、switch case、错误处理、函数拆分、命名规范、goimport/go vet、可读性、可维护性。Actions: design, refactor, review, implement Go code style improvements."
---

# Go Code Style

核心约束：Go 代码优先简单、清晰、可维护；保持主流程左对齐，错误和边界条件优先返回。不要写多层嵌套的 `if-else`；多个互斥条件优先用 `switch case` 或提前返回优化。

## Workflow

- [ ] Step 1: 识别代码意图 ⚠️ REQUIRED
  - [ ] 确认函数职责、输入输出、错误语义和已有项目风格。
  - [ ] 判断问题属于控制流、命名、错误处理、context、并发、测试还是层级边界。
  - [ ] 保持现有业务行为不变，除非用户明确要求改逻辑。
- [ ] Step 2: 优化结构
  - [ ] 错误、空值、权限、非法状态用 guard clause / early return。
  - [ ] 多个互斥分支用 `switch case`；复杂条件抽成语义化局部变量或 helper。
  - [ ] 函数只做一个清晰职责；过长函数按业务步骤拆私有 helper。
  - [ ] 命名精简达意，避免含混缩写、无意义编号和过度冗长的变量名。
- [ ] Step 3: 处理 Go 关键约束
  - [ ] 错误处理贴近错误来源，不吞错；包装或转换错误遵循项目约定。
  - [ ] 函数入参、出参优先使用定义好的 struct 或具体类型，尽量少用 `any`、`interface{}` 或过宽的数据 interface。
  - [ ] 函数入参、出参尽量各不超过 3 个；超过时优先抽 param/result struct，配置类参数可考虑 option 模式。
  - [ ] 涉及 I/O、DB、缓存、RPC、耗时任务时传递 `ctx context.Context`，不要用 `context.Background()` 替代上游 ctx。
  - [ ] goroutine 必须有退出条件、ctx/cancel 或明确生命周期，避免泄漏。
  - [ ] 不为了“抽象”而抽象；只在减少真实复杂度时新增 abstraction。
- [ ] Step 4: 应用 Go 工具
  - [ ] 修改 Go 文件后运行 `goimport`。
  - [ ] 能运行测试时，优先运行相关 package 的 `go test`；公共 API 或复杂逻辑变更要补充测试。
- [ ] Step 5: 交付检查
  - [ ] 运行 Pre-Delivery Checklist。
  - [ ] 如果无法运行测试，说明原因。

## Reference Loading

需要生成、重构或评审 Go 代码规范时，加载 `references/go-code-style-conventions.md`。

## Required Patterns

```go
func Do(ctx context.Context, param Param) error {
    if err := param.Check(); err != nil {
        return err
    }
    if ctx == nil {
        return errors.New("nil context")
    }

    return do(ctx, param)
}
```

```go
switch status {
case StatusPending:
    return handlePending(ctx, data)
case StatusDone:
    return handleDone(ctx, data)
case StatusFailed:
    return handleFailed(ctx, data)
default:
    return fmt.Errorf("unknown status: %s", status)
}
```

```go
if item == nil {
    return nil, ErrNotFound
}
if item.Disabled == "true" {
    return nil, ErrDisabled
}
return buildResponse(item), nil
```

## Anti-Patterns

- 不要写多层嵌套的 `if-else`；优先早返回、`switch case` 或拆 helper。
- 不要用 `else` 包住主流程；前面的分支已经 `return` 时，后续代码直接左对齐。
- 不要把不同抽象层级的逻辑塞进同一个函数。
- 不要用含混变量名，如 `data1`、`tmp`、`res2`，除非生命周期极短且语义明显。
- 不要写过度冗长的变量名；命名应借助当前函数、类型、包名上下文，做到精简达意。
- 不要在入参、出参中滥用 `any`、`interface{}` 或宽泛数据 interface；优先定义明确 struct。
- 不要让函数签名堆太多入参或出参；超过 3 个时优先抽 struct 或 option。
- 不要吞掉错误；如果允许忽略，必须显式说明或使用项目既有写法。
- 不要在有上游 ctx 的调用链里改用 `context.Background()`。
- 不要启动没有退出机制或生命周期说明的 goroutine。
- 不要为了复用少量代码引入复杂 abstraction。
- 不要引入与项目现有风格冲突的新框架、新 helper 或新目录结构。

## Pre-Delivery Checklist

- [ ] 代码已遵循项目现有风格和命名习惯。
- [ ] 命名精简达意，没有含混缩写、无意义编号或过度冗长变量名。
- [ ] 没有多层嵌套 `if-else`；复杂分支已用早返回、`switch case` 或 helper 优化。
- [ ] 主流程尽量左对齐，错误和边界条件优先返回。
- [ ] 函数长度和职责可读；复杂步骤已拆分。
- [ ] 入参、出参优先使用明确 struct 或具体类型，没有滥用 `any`、`interface{}` 或宽泛数据 interface。
- [ ] 入参、出参尽量各不超过 3 个；超过时已有 struct、result struct、option 或明确理由。
- [ ] 错误处理没有吞错，日志或包装遵循项目约定。
- [ ] 涉及 I/O、DB、缓存、RPC、耗时任务时正确传递 ctx。
- [ ] goroutine 有退出条件或明确生命周期。
- [ ] Go 文件已运行 `goimport`。
- [ ] 能运行测试时已运行相关 `go test`。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
