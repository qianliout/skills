# Go Code Style Conventions

Use this reference when generating, refactoring, or reviewing general Go code style.

## Control Flow

- Guard invalid input, nil data, permission failures, and errors with early return.
- Keep the main success path left-aligned.
- Avoid nested `if-else`; use `switch case` for one value with several mutually exclusive states.
- Extract complex boolean expressions into named local variables or small helpers.

Before:

```go
if param.Valid() {
    if user != nil {
        if user.Enabled == "true" {
            return run(user)
        } else {
            return ErrDisabled
        }
    } else {
        return ErrNotFound
    }
} else {
    return ErrInvalidParam
}
```

After:

```go
if !param.Valid() {
    return ErrInvalidParam
}
if user == nil {
    return ErrNotFound
}
if user.Enabled != "true" {
    return ErrDisabled
}
return run(user)
```

For state branching:

```go
switch param.Action {
case ActionCreate:
    return create(ctx, param)
case ActionUpdate:
    return update(ctx, param)
case ActionDelete:
    return delete(ctx, param)
default:
    return fmt.Errorf("unsupported action: %s", param.Action)
}
```

## Function Shape

A good Go function usually has guard clauses, small setup, ordered operation steps, local error handling, and a clear return.

Split a function when it mixes validation, data access, transformation, and response assembly; when a block has a clear purpose and name; or when the reader must scroll to understand one branch. Do not split when the helper name would be vague or the extracted code is clearer inline.

Prefer methods with receivers for behavior that belongs to a struct. Except for real shared utilities such as `utils` helpers, avoid loose functions with no owner. Put business behavior on the service/API/model/param/helper struct that owns the state or responsibility.

All methods must use pointer receivers. Do not use value receivers, even for read-only methods or small structs. This keeps method sets consistent and avoids accidental struct copies.

Good:

```go
func (m *Xxx) Check() error {
    return nil
}
```

Avoid:

```go
func (m Xxx) Check() error {
    return nil
}
```

## Self-Returning Mutation Methods

- `Normalize()`、`FillDefault()`、`WithXxx()` 等会修改 receiver 并返回自身的方法，必须是 pointer receiver，并且返回同一个对象的指针，例如 `func (r *Request) Normalize() *Request`。
- 这类方法直接规整或补全 receiver 字段并返回自身；nil receiver 场景在方法内初始化为空对象后继续处理。
- 只要这类方法有返回值，调用方必须用原变量接收返回值，例如 `req = req.Normalize()`、`input.Prompt = input.Prompt.Normalize()`、`opts = opts.FillDefault()`。
- 不区分调用方当前变量是否为 nil；统一使用原变量接收返回值。原因是 nil receiver 场景下，方法内的 `r = &Request{}` 只改变局部 receiver 变量，不会修改调用方手里的 nil 指针。
- 调用侧不要裸调这类有返回值的方法，也不要另起变量承接规整结果，例如不要写 `req.Normalize()`、`opts.FillDefault()`、`normalized := req.Normalize()`、`prompt := input.Prompt.Normalize()`、`modelInfo := llmModel.Normalize()`。

Good:

```go
func (r *Request) Normalize() *Request {
    if r == nil {
        r = &Request{}
    }
    r.Name = strings.TrimSpace(r.Name)
    return r
}

req = req.Normalize()
req.Check()

existingReq = existingReq.Normalize()
existingReq.Check()

opts = opts.FillDefault()
```

Avoid:

```go
func (r *Request) Normalize() Request {
    if r == nil {
        return Request{}
    }
    r.Name = strings.TrimSpace(r.Name)
    return *r
}

normalized := req.Normalize()
normalized.Check()

var req *Request
req.Normalize()
req.Check()

existingReq.Normalize()
existingReq.Check()

defaults := opts.FillDefault()
```

## File And Line Length

- A single file should not become too long or carry too many responsibilities.
- Split files by type group, responsibility, route group, method family, or established local convention.
- Public structs that are not model-layer types may live in a shared `structs` directory.
- Keep those non-model shared structs in one consistent place instead of scattering them across service, API, DAL, or helper files.
- If a struct belongs to model semantics, param validation, serialization, database mapping, or model constants, keep it in the model layer rather than moving it to `structs`.
- Do not create tiny fragmented files only to reduce line count; split when it improves navigation and ownership.
- A single line should not be too long.
- Wrap long function calls, chained calls, struct literals, slices/maps, and complex conditions at natural boundaries.
- Prefer readable multi-line formatting over dense one-line expressions.

## Constants

- Manage constants in a unified place by responsibility.
- Do not scatter constants across functions, handlers, service files, DAL files, or helper files.
- Model-related constants, enum values, defaults, and field constraints belong in the model layer.
- Shared non-model constants may live in the project’s established constants package or another unified location.
- Prefer named constants over repeated magic strings or numbers.

## Naming

- Types and functions use business meaning: `SearchPolicyParam`, `BuildSummary`, `ValidateOwner`.
- Local variables should describe role: `ownerByID`, `enabledItems`, `pendingIDs`.
- Avoid broad names like `data`, `tmp`, `obj`, `res` when the scope is not tiny.
- Names should be concise and expressive. Do not repeat context already clear from the function, receiver, type, or package name.
- Avoid overlong local names such as `currentProcessingProjectWorldviewVersionList` when `versions` or `worldviewVersions` is clear in scope.
- Avoid redundant `Is` prefixes for binary/status semantics when the core name is already clear. Prefer `FirstShot` over `IsFirstShot`.
- Do not over-design long local variable names for readability. Short-lived variables may use concise names such as `res`, `ans`, `input`, `output`, and `cnt`.
- Do not use Go built-ins or common package names as variable names, such as `max`, `min`, `len`, `cap`, `error`, `slices`, `maps`, or `strings`.
- Keep common Go abbreviations consistent: `ID`, `URL`, `HTTP`, `JSON`.

## Variable Declarations

- Prefer declaration with initialization: `in := Hello{}`.
- Avoid empty declarations followed by later assignment, such as `var in Hello`, when the value can be initialized immediately.
- Use `var` only when it improves clarity, such as declaring a nil pointer/interface intentionally, accumulating a zero value across branches, or sharing a variable outside a narrow inner scope.
- When a function returns a slice or map, instantiate it before any return path and never return a nil slice/map. Use `res := make([]*model.Xxx, 0)` or `ans := make(map[string]*model.Xxx)` and return that value on both success and error paths.

## Types And Interfaces

- Function inputs and outputs should prefer defined structs or concrete types.
- Function inputs and outputs should each usually stay within 3 values. If a signature needs more, prefer a named param struct, result struct, or option pattern.
- Slice/map return values must be non-nil by contract. This includes error paths such as `(items, 0, err)` instead of `(nil, 0, err)` when `items` is a slice return value.
- Numeric fields in structs should use `int64` by default.
- Use other numeric types only for clear exceptions, such as external API contracts, third-party library signatures, byte-size data, proven memory/performance needs, or a local project convention.
- Avoid `any`, `interface{}`, `map[string]any`, and broad data interfaces for request params, response values, and business data.
- Use small behavior interfaces only when callers truly vary by behavior, such as `io.Reader`, `context.Context`, or a narrow project interface.
- If data has a stable shape, define a struct even when only a few fields are currently used.
- Keep `any` for unavoidable boundaries such as generic helpers, JSON/raw dynamic payloads, logging fields, or third-party APIs; convert to typed structs as soon as practical.
- Keep common Go return shapes such as `(value, error)` or `(list, count, error)` when they match local conventions.

## Tags

- Do not use `omitempty` directly in JSON tags.
- Avoid tags such as `json:"name,omitempty"` or `json:",omitempty"`.
- Prefer explicit zero values in API responses and serialized data so callers can distinguish absent fields from empty values by contract, not by implicit tag behavior.

## Error Handling

- Return errors immediately unless there is a clear recovery path.
- Wrap or translate errors according to project convention.
- Include useful context in logs or wrapping, but avoid leaking sensitive values.
- If a secondary cleanup/maintenance error is intentionally ignored, make that explicit.
- Use `errors.Is` / `errors.As` when comparing wrapped errors if the project uses standard wrapping.
- For functions that return `(value, error)` and whose contract says `value` is usable when `err == nil`, do not add repetitive defensive `if value == nil` checks at call sites. The callee should return an error when it cannot provide a usable value; only keep a nil check when the function explicitly allows `(nil, nil)`.

## Context And Concurrency

- Pass `ctx context.Context` through I/O, DB, cache, RPC, queue, and long-running operations.
- Do not replace an upstream ctx with `context.Background()` inside request or job flows.
- Create child contexts only when adding timeout/cancel scope, and always call `cancel`.
- Goroutines need an exit condition, ctx cancellation, bounded work, or a documented lifecycle.
- Every goroutine must guard with `recover`; log the panic and stack or convert it to the project’s observable error path.
- Protect shared mutable state with the project’s established synchronization pattern.

Example:

```go
go func() {
    defer func() {
        if r := recover(); r != nil {
            log.Err(fmt.Errorf("panic: %v", r)).Msg("worker panic")
        }
    }()
    runWorker(ctx)
}()
```

## Comments

Write code comments in Chinese. Use comments for intent, constraints, and surprising behavior. Do not narrate obvious code.

Good:

```go
// ProjectID 为 0 表示查询全局模板。
if param.ProjectID != 0 {
    db = db.Where("project_id = ?", param.ProjectID)
}
```

Avoid:

```go
// 返回错误。
return err
```

## Log Language

- Log messages use English, especially `Msg(...)` text and stable operation names.
- Code comments use Chinese.
- Keep structured log field names consistent with project conventions, such as `projectID`.

## Formatting And Tests

- Use grouped import syntax even when there is only one import.

Good:

```go
import (
    "strings"
)
```

Avoid:

```go
import "strings"
```

- Always run `goimport` after editing Go files.
- Prefer targeted tests first: `go test ./path/to/pkg`.
- If a refactor changes behavior or touches shared code, broaden the test scope.
- If tests cannot run because dependencies or environment are missing, report that clearly.
