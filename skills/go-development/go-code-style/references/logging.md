# Go 日志硬约束

日志只用于定位与关键异常追踪；禁止替代错误返回、泄露敏感信息、跨层重复打印。必须同时遵守 `code-style.md`。API/Service 构造与编排细则分别遵守对应 `go-*`。Logger 实现以项目 `infra/logger` 为准。

## 谁打

| 层 | 规则 |
| --- | --- |
| API | 只记入口关键信息与必要异常返回；禁止业务细节 |
| Service | 记关键异常、外部/Cache/异步失败；附带最完整可用业务上下文 |
| DAL / Model | 默认禁止；需要时必须先说明原因并等用户决定。`Check`/`Serialize`/`Deserialize`/`ToUpdater` 等只返回错误 |
| helper | 默认只返回错误；禁止打日志，下列除外：独有上下文会丢失且用户明确要求 |

拥有最完整业务上下文的层必须记录；同一 error 禁止跨层重复打印；禁止记录后吞掉错误。

## Logger

- 需要日志的 struct 必须持有 `log *logger.Logger`，构造时用 `logger.New(logger.WithModule(...), logger.WithSubModule(...))` 初始化稳定 module/subModule；logger 必须是依赖字段最后一项。
- 禁止方法内使用全局 logger、临时 `logger.New`、把 logger 当普通参数沿调用链传递。
- 级别方法必须带 `ctx`：`log.Debug(ctx)` / `Info(ctx)` / `Warn(ctx)` / `Error(ctx)`，再链式字段，最后 `.Msg(...)`。
- 错误必须用 `.Err(err)`；结构化值必须用 `.Str` / `.Int64` / `.Bool` / `.Interface` 等字段方法，禁止塞进 `Msg`。

## 级别与内容
- Debug 禁止长期高噪音
- Error 必须：英文短 `Msg` + `.Err(err)` + 关键业务 ID + `LogStr()`；字段名稳定；禁止中文 Msg。
- 禁止 password/token/secret/Cookie/Authorization/原始敏感体/大 payload/完整 SQL 参数；定位只用脱敏、哈希、长度、数量、类型或业务 ID。
- 忽略的 error 必须记日志或英文注释原因；panic 必须 recover 并记日志与 stack。
- 禁止循环逐项成功日志；失败项必须带关键 ID；批结束必须记总数/成功/失败/耗时；高频错误必须采样或聚合。

## `LogStr()`

- struct 需要日志摘要时必须提供 `LogStr() string`；必须指针 receiver；Param 用 `p`，其他 Model 用 `vi`。
- 只拼字符串；禁止校验、填默认、规范化、权限、I/O、副作用、改状态、复杂计算/排序/过滤/去重。
- 输出必须短、稳、可搜索；禁止敏感字段与大载荷。

## 样例

```go
type XxxSrv struct {
    xxxDal dal.XxxDal
    log    *logger.Logger
}

s.log.Error(ctx).Err(err).Int64("projectID", param.ProjectID).Str("param", param.LogStr()).Msg("createXxx failed")
```

禁止：

```go
s.log.Error(ctx).Msg("创建失败: " + err.Error() + " token=" + token)
logger.New(...).Error(ctx).Err(err).Msg("createXxx failed") // 方法内临时 New
```
