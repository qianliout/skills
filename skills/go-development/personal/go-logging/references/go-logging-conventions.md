# Go Logging Conventions

Use this reference when generating, refactoring, or reviewing Go logging code.

## Layer Boundaries

API layer:

- Record only entrance-level key information and abnormal returns when needed.
- Do not log complex business details.
- Log only safe request summaries.

Service layer:

- Structs that need logs hold their own logger.
- Record key exceptions, external call failures, async task failures, and business context.
- Service usually owns the richest business context, so it is often the right place for error logs.

DAL layer:

- Default: no logs.
- Return errors only.
- Agent must not automatically add DAL logs.
- If DAL logging looks necessary, tell the user why and let the user decide.

Model layer:

- No logs.
- `Check()`, `Serialize()`, `Deserialize()`, `ToUpdater()`, and similar methods return errors only.
- Agent must not automatically add model logs.
- If model logging looks necessary, tell the user why and let the user decide.

Private helpers:

- Default: no error logs.
- Return errors to the upper caller; the caller records with operation name, business IDs, and param summary.
- Log inside a helper only if helper-owned context would be lost and the user explicitly wants it.

## Logger Ownership

- A struct that needs logs owns a logger field.
- Initialize the logger in the constructor.
- Set stable `module` and `subModule` during initialization.
- Do not use global logging objects directly in methods.
- Do not create a logger inside every method.
- Do not pass logger as a normal argument through call chains.
- Keep logger as the last dependency field when the struct also owns service/DAL/client/cache/config dependencies.
- Service/API methods that use the logger still follow receiver naming from their layer: service receiver `s`, API receiver `api`. Model `LogStr()` follows model receiver naming: Param uses `p`, other model-layer objects use `vi`. The receiver form and variable name must stay consistent with other methods on the same struct.

Example:

```go
type XxxSrv struct {
    xxxDal XxxDal
    log    *utils.LogEvent
}

func NewXxxSrv(xxxDal XxxDal) *XxxSrv {
    srv := XxxSrv{
        xxxDal: xxxDal,
        log: utils.NewLogEvent(
            utils.WithModule("xxx"),
            utils.WithSubModule("service"),
        ),
    }
    return &srv
}
```

## Log Levels

- Debug: temporary or low-frequency troubleshooting; avoid long-term noisy debug logs.
- Info: important successful business actions and lifecycle events.
- Warn: recoverable exceptions, degradation, skipped non-critical data, compatibility behavior.
- Error: current operation failed, external/cache/async failure, or goroutine panic recovered.

## Log Content

Error logs should include:

- Operation name.
- Error object.
- Key business IDs.
- Safe param summary.

Recommended:

```go
paramLog := param.LogStr()
s.log.Err(err).
    Int64("projectID", projectID).
    Str("param", paramLog).
    Msg("search xxx failed")
```

Avoid:

```go
logging.Get().Err(err).Interface("param", param).Msg("error")
```

## LogStr

Use `LogStr() string` when a struct needs to be summarized in logs.

Rules:

- `LogStr()` only builds a string.
- No validation.
- No default filling.
- No field normalization.
- No permission checks.
- No DB/cache/network/file I/O.
- No side effects.
- No receiver or external state mutation.
- Use a pointer receiver; do not use a value receiver. Keep the receiver form and variable name consistent with the rest of the same struct. Model-layer Param `LogStr()` receivers use `p`; other model-layer object receivers use `vi`.
- No complex calculation, sorting, filtering, or deduplication.
- No sensitive fields.
- Output should be stable, concise, and searchable.

Example:

```go
func (p *SearchXxxParam) LogStr() string {
    ans := fmt.Sprintf(
        "projectID=%d,status=%s,keyword=%s,limit=%d,offset=%d",
        p.ProjectID,
        p.Status,
        p.Keyword,
        p.Filter.Limit,
        p.Filter.Offset,
    )
    return ans
}
```

## Error Logging

- Do not log and then hide the error.
- Avoid repeated logs for the same error across layers.
- The layer with useful context records the log.
- If an error is intentionally ignored, log or comment the reason according to project convention.
- Private helpers return errors to callers; callers log.
- Goroutine panic must be recovered and logged.

## Sensitive Data

Never log:

- Password, token, secret, access key.
- Cookie or Authorization header.
- Sensitive raw request body fields.
- Private user data.
- Large payloads, full file content, or full SQL params.

When needed, log only masked values, hashes, length, count, type, or IDs.

## Format

- Logs use English.
- `Msg` should be short, stable English text.
- Operation names in logs should also be stable English text.
- Put structured values in fields, not inside `Msg`.
- Keep field names consistent, such as always using `projectID`.
- `module` / `subModule` names should be stable and map to business domain or code layer.

## Batch And Loops

- Do not log every successful item in a large loop.
- Failed item logs should contain the item key ID.
- At the end of a batch task, log a summary when useful: total, success count, failure count, duration.
- For high-frequency errors, consider sampling or aggregation.
