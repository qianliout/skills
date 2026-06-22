# Go Logging

日志用于定位问题和追踪关键异常，不替代错误返回，不记录敏感信息，不制造重复噪音。DAL/model 层默认不新增日志；确实需要时先说明原因并让用户决定。

## Workflow

1. 判断日志边界：API、service、DAL、model、helper、goroutine、批量任务或外部调用。
2. 加载 `references/logging-conventions.md`；同时遵循当前任务触发的 `references/code-style.md` 和所在层 reference。
3. 设置 logger：需要日志的 struct 自己持有 logger，并在构造函数中设置稳定 module/subModule。
4. 设计内容：日志 Msg 和操作名使用英文；结构化字段放关键业务 ID、错误对象和安全 param 摘要。
5. 控制信息量：需要记录 struct 时优先提供 pointer receiver 的 `LogStr() string`；禁止记录 token、secret、password、Authorization、Cookie、原始敏感 body 和大 payload。
6. 放置日志：谁拥有业务上下文谁记录；私有 helper 默认返回错误给上层；goroutine panic 必须 recover 并记录日志。

## Reference Loading

生成、重构或评审日志代码时，必须加载 `references/logging-conventions.md`。

## Pre-Delivery Checklist

- [ ] 需要日志的 API/service 等 struct 自己持有 logger，并在构造函数中设置稳定 module/subModule。
- [ ] 没有全局日志、方法内临时 logger，或把 logger 作为普通参数层层传递。
- [ ] DAL/model 层没有被 Agent 自动新增日志。
- [ ] 错误日志包含操作名、错误对象和关键业务 ID；没有每层重复打印同一个错误。
- [ ] `LogStr()` 使用指针接收者，只做安全摘要拼装，不包含敏感字段或大 payload。
- [ ] 私有 helper 默认返回错误给上层记录；goroutine panic 有 recover 日志。
- [ ] 日志 Msg 使用英文且稳定简短，结构化信息放字段中。
