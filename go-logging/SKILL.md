---
name: go-logging
description: "通用 Go 日志规范专家，生成、重构、评审日志代码。Use when user asks 日志规范、加日志、改日志、日志字段、logger 初始化、module/subModule、LogStr、错误日志、panic recover 日志、service 日志、API 日志、DAL/model 不加日志、避免重复日志、敏感信息脱敏。Actions: design, create, refactor, review, implement Go logging."
---

# Go Logging

日志用于定位问题和追踪关键异常，不替代错误返回，不记录敏感信息，不制造重复噪音。DAL/model 层默认不加日志；Agent 不自动在 DAL/model 层新增日志，如确实需要只提醒用户并说明原因。

## Workflow

- [ ] Step 1: 判断日志边界
  - 确认当前代码属于 API、service、DAL、model、helper、goroutine、批量任务或外部调用。
  - 加载 `references/go-logging-conventions.md`，按项目约定落地。
  - 私有 helper 默认不记录错误日志，返回错误给上层调用方统一记录。
- [ ] Step 2: 设置 logger
  - 需要记录日志的 struct 自己持有 logger。
  - logger 在构造函数中初始化，并设置稳定的 module / subModule。
  - 不使用全局日志对象直接打日志，不在方法内部临时创建 logger。
- [ ] Step 3: 设计日志内容
  - 日志内容使用英文，尤其是 `Msg(...)` 和稳定操作名。
  - 错误日志包含操作名、错误对象、关键业务 ID、必要 param 摘要。
  - 记录 struct 信息时优先提供 `LogStr() string`，避免直接记录完整 struct。
  - `LogStr()` 只能做字符串拼装，不做校验、规范化、I/O、副作用或复杂计算。
  - 禁止记录 token、secret、password、Authorization、Cookie、原始敏感 body、大 payload。
- [ ] Step 4: 放置日志
  - 谁拥有业务上下文，谁记录日志；避免每层重复打印同一个错误。
  - 不要只打日志不返回错误。
  - goroutine panic 必须 recover 并记录日志。
  - 批量/循环中避免每条成功日志；失败日志包含 item 关键 ID。
- [ ] Step 5: 交付
  - 修改 Go 文件后遵循 `go-code-style`，运行 `goimport` 和相关测试。
  - 运行 Pre-Delivery Checklist。

## Reference Loading

生成、重构或评审日志代码时，必须加载 `references/go-logging-conventions.md`。

## Pre-Delivery Checklist

- [ ] DAL/model 层没有被 Agent 自动新增日志。
- [ ] 需要日志的 struct 自己持有 logger，并在构造函数中设置 module / subModule。
- [ ] 没有直接使用全局日志对象打日志，也没有在每个方法里临时创建 logger。
- [ ] 错误日志包含操作名、错误对象和关键业务 ID。
- [ ] struct 摘要日志使用 `LogStr()`；`LogStr()` 只做字符串拼装，不含敏感字段。
- [ ] 私有 helper 默认不记录错误日志，由上层调用方记录。
- [ ] 没有只打日志不返回错误；没有每层重复打印同一个错误。
- [ ] goroutine panic 有 recover 日志。
- [ ] 没有记录敏感信息或大 payload；循环/批量任务没有大量成功日志。
- [ ] 日志 Msg 使用英文且稳定简短，结构化信息放字段中。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
