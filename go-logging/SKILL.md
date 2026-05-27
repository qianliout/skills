---
name: go-logging
description: "Go 日志规范专家。Use when writing, refactoring, or reviewing logging, logger initialization, module/subModule fields, LogStr, error logs, panic recover logs, service/API logging, avoiding DAL/model logs, duplicate logs, sensitive data, or large payload logging."
---

# Go Logging

日志用于定位问题和追踪关键异常，不替代错误返回，不记录敏感信息，不制造重复噪音。DAL/model 层默认不加日志；Agent 不自动在 DAL/model 层新增日志，如确实需要只提醒用户并说明原因。

## Workflow

1. 判断日志边界：确认代码属于 API、service、DAL、model、helper、goroutine、批量任务还是外部调用。
2. 加载 `references/go-logging-conventions.md`，按项目约定处理 logger、日志字段、敏感信息和重复日志。
3. 设置 logger：需要记录日志的 struct 自己持有 logger；在构造函数中初始化并设置稳定 module/subModule。
4. 设计内容：日志 Msg 和操作名使用英文；错误日志包含操作名、错误对象、关键业务 ID 和必要 param 摘要。
5. 控制信息量：记录 struct 时优先提供 pointer receiver 的 `LogStr() string`；所有日志相关方法都使用指针接收者；model 层 Param 的 `LogStr()` receiver 用 `p`，其他 model 层对象用 `vi`；禁止记录 token、secret、password、Authorization、Cookie、原始敏感 body 和大 payload。
6. 放置日志：谁拥有业务上下文谁记录；私有 helper 默认返回错误给上层记录；goroutine panic 必须 recover 并记录日志。
7. 交付：修改 Go 文件后遵循 `go-code-style`，运行 `goimport` 和相关测试。

## Reference Loading

生成、重构或评审日志代码时，必须加载 `references/go-logging-conventions.md`。

## Pre-Delivery Checklist

- [ ] 新写日志相关代码同时符合 `go-code-style` 以及所在层当前任务涉及的 Go skill 规则。
- [ ] DAL/model 层没有被 Agent 自动新增日志。
- [ ] 需要日志的 struct 自己持有 logger，并在构造函数中设置 module / subModule。
- [ ] 没有直接使用全局日志对象打日志，也没有在每个方法里临时创建 logger。
- [ ] 错误日志包含操作名、错误对象和关键业务 ID。
- [ ] struct 摘要日志使用 `LogStr()`；`LogStr()` 只做字符串拼装，不含敏感字段。
- [ ] logger、service/API 日志方法和 `LogStr()` 都使用指针接收者，没有值接收者；service/API receiver 分别用 `s`/`api`，model 层 Param 用 `p`，其他 model 层对象用 `vi`。
- [ ] 私有 helper 默认不记录错误日志，由上层调用方记录。
- [ ] 没有只打日志不返回错误；没有每层重复打印同一个错误。
- [ ] goroutine panic 有 recover 日志。
- [ ] 没有记录敏感信息或大 payload；循环/批量任务没有大量成功日志。
- [ ] 日志 Msg 使用英文且稳定简短，结构化信息放字段中。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
