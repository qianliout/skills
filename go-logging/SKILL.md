---
name: go-logging
description: "通用 Go 日志规范专家，生成、重构、评审日志代码。Use when user asks 日志规范、加日志、改日志、日志字段、logger 初始化、module/subModule、LogStr、错误日志、panic recover 日志、service 日志、API 日志、DAL/model 不加日志、避免重复日志、敏感信息脱敏。Actions: design, create, refactor, review, implement Go logging."
---

# Go Logging

核心约束：日志用于定位问题和追踪关键异常，不替代错误返回，不记录敏感信息，不制造重复噪音。DAL/model 层默认不加日志；Agent 不自动在 DAL/model 层新增日志，如确实需要只提醒用户并说明原因。

## Workflow

- [ ] Step 1: 判断日志边界 ⚠️ REQUIRED
  - [ ] 确认当前代码属于 API、service、DAL、model、helper、goroutine、批量任务或外部调用。
  - [ ] DAL/model 层不自动加日志；需要时只提醒用户。
  - [ ] 私有 helper 默认不记录错误日志，返回错误给上层调用方统一记录。
- [ ] Step 2: 设置 logger
  - [ ] 需要记录日志的 struct 自己持有 logger。
  - [ ] logger 在构造函数中初始化，并设置稳定的 module / subModule。
  - [ ] 不使用全局日志对象直接打日志，不在方法内部临时创建 logger。
- [ ] Step 3: 设计日志内容
  - [ ] 错误日志包含操作名、错误对象、关键业务 ID、必要 param 摘要。
  - [ ] 记录 struct 信息时优先提供 `LogStr() string`，不直接 `Interface("param", param)`。
  - [ ] `LogStr()` 只能做字符串拼装，不做校验、规范化、I/O、副作用或复杂计算。
  - [ ] 禁止记录 token、secret、password、Authorization、Cookie、原始敏感 body、大 payload。
- [ ] Step 4: 放置日志
  - [ ] 谁拥有业务上下文，谁记录日志；避免每层重复打印同一个错误。
  - [ ] 不要只打日志不返回错误。
  - [ ] goroutine panic 必须 recover 并记录日志。
  - [ ] 批量/循环中避免每条成功日志；失败日志包含 item 关键 ID。
- [ ] Step 5: 交付检查
  - [ ] 运行 Pre-Delivery Checklist。
  - [ ] 修改 Go 文件后遵循 `go-code-style`，运行 `goimport` 和相关测试。

## Reference Loading

需要生成或评审 Go 日志代码时，加载 `references/go-logging-conventions.md`。

## Required Patterns

struct 持有 logger：

```go
type XxxSrv struct {
    xxxDal XxxDal
    log    *utils.LogEvent
}

func NewXxxSrv(xxxDal XxxDal) *XxxSrv {
    return &XxxSrv{
        xxxDal: xxxDal,
        log: utils.NewLogEvent(
            utils.WithModule("xxx"),
            utils.WithSubModule("service"),
        ),
    }
}
```

错误日志：

```go
s.log.Err(err).
    Int64("projectID", projectID).
    Str("param", param.LogStr()).
    Msg("search xxx failed")
```

`LogStr()`：

```go
func (p SearchXxxParam) LogStr() string {
    return fmt.Sprintf(
        "projectID=%d,status=%s,keyword=%s,limit=%d,offset=%d",
        p.ProjectID,
        p.Status,
        p.Keyword,
        p.Filter.Limit,
        p.Filter.Offset,
    )
}
```

goroutine recover：

```go
go func() {
    defer func() {
        if r := recover(); r != nil {
            s.log.Error().
                Interface("panic", r).
                Msg("worker panic")
        }
    }()
    runWorker(ctx)
}()
```

## Anti-Patterns

- 不要在 DAL/model 层自动新增日志。
- 不要使用全局日志对象直接打日志。
- 不要在方法内部临时创建 logger。
- 不要把 logger 作为普通参数层层传递。
- 不要只打日志不返回错误。
- 不要每层重复打印同一个错误。
- 不要在私有 helper 中默认记录错误日志；返回错误给上层调用方。
- 不要直接 `Interface("param", param)` 记录完整 struct；优先 `param.LogStr()`。
- 不要在 `LogStr()` 中做字符串拼装之外的逻辑。
- 不要记录敏感信息或大体积 payload。
- 不要在大循环中记录每条成功日志。
- 不要启动没有 recover 日志的 goroutine。

## Pre-Delivery Checklist

- [ ] DAL/model 层没有被 Agent 自动新增日志。
- [ ] 需要日志的 struct 自己持有 logger，并在构造函数中设置 module / subModule。
- [ ] 没有直接使用全局日志对象打日志。
- [ ] 错误日志包含操作名、错误对象和关键业务 ID。
- [ ] struct 摘要日志使用 `LogStr()`，且 `LogStr()` 只做字符串拼装。
- [ ] 私有 helper 默认不记录错误日志，由上层调用方记录。
- [ ] 没有只打日志不返回错误。
- [ ] 没有每层重复打印同一个错误。
- [ ] goroutine panic 有 recover 日志。
- [ ] 没有记录敏感信息或大 payload。
- [ ] 循环/批量任务没有大量成功日志。
- [ ] 日志 Msg 稳定简短，结构化信息放字段中。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
