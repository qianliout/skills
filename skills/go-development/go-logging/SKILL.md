---
name: go-logging
description: "Go 日志规范 Skill。Use when writing, refactoring, reviewing, debugging, or explaining Go logging code, logger ownership, log levels, error logging, LogStr, panic recover logs, sensitive data handling, and API/service/DAL/model logging boundaries."
---

# Go Logging

用于 Go 日志相关任务。日志用于定位问题和追踪关键异常，不替代错误返回，不记录敏感信息，不制造重复噪音。

## Workflow

1. 判断日志边界：API、service、DAL、model、helper、goroutine、批量任务或外部调用。
2. 读取 `references/logging.md` 和 `references/logging-conventions.md`。
3. 涉及 code style 或所在层实现时，再按需使用对应 Go 分类 Skill。
4. 需要日志的 struct 自己持有 logger，并在构造函数中设置稳定 module/subModule。
5. 日志 Msg 和操作名使用英文；结构化字段放关键业务 ID、错误对象和安全 param 摘要。
6. 修改 Go 文件后运行 `goimport`；能定位包或测试时运行最小范围 `go test`。

## Layer Boundaries

- 谁拥有业务上下文谁记录日志；私有 helper 默认返回错误给上层。
- DAL 和 Model 默认不新增日志；确实需要 DAL 日志时，先说明原因并让用户决定。
- goroutine panic 必须 recover 并记录日志。
- 禁止记录 token、secret、password、Authorization、Cookie、原始敏感 body 和大 payload。

## Pre-Delivery Checklist

- 已读取本 Skill 的两个 reference。
- logger 所有权、日志位置、字段、安全摘要和错误日志去重符合约定。
- 没有在 DAL/model 中自动新增日志，也没有泄露敏感数据。
- 修改 Go 文件后已运行 `goimport`；能运行时已执行相关 `go test`。
