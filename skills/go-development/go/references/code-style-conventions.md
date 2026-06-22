# Go Code Style Conventions

Use this reference when generating, refactoring, or reviewing general Go code style.

## Contents

- [Reference Alignment](#reference-alignment)
- [Control Flow](#control-flow)
- [Function Shape](#function-shape)
- [Thin Wrapper Ban](#thin-wrapper-ban)
- [Defensive Check Boundary](#defensive-check-boundary)
- [Domain Method Shape](#domain-method-shape)
- [File And Line Length](#file-and-line-length)
- [Constants](#constants)
- [Naming](#naming)
- [Variable Declarations](#variable-declarations)
- [Return Values For Debugging](#return-values-for-debugging)
- [Types And Interfaces](#types-and-interfaces)
- [Tags](#tags)
- [Time Fields](#time-fields)
- [Error Handling](#error-handling)
- [Context And Concurrency](#context-and-concurrency)
- [Comments](#comments)
- [Log Language](#log-language)
- [Formatting And Tests](#formatting-and-tests)

## Reference Alignment

New Go code should follow the currently selected Go references first. When multiple references apply, combine them by layer responsibility: API adapts HTTP, service orchestrates dependencies and business flow, DAL handles persistence, model owns field lifecycle and domain methods, logging follows `references/logging.md`, and general readability follows this style guide.

## Control Flow

- Guard invalid input, nil data, permission failures, and errors with early return.
- Keep the main success path left-aligned.
- Avoid `if-else` and `else if` unless there is no clearer early-return or `switch` form. Prefer sequential guard clauses: write `if condition { return ... }`, then continue with the next `if`.
- Avoid nested `if-else`; use `switch case` for one value with several mutually exclusive states.
- Keep `else` only when both branches must feed a shared later step and early return or `switch` would make the function less clear.
- Extract complex boolean expressions into named local variables first. Use a small helper only when the expression is reused, hides a stable business concept, or would make the caller much easier to scan.

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
err := run(user)
return err
```

For state branching:

```go
switch param.Action {
case ActionCreate:
    err := create(ctx, param)
    return err
case ActionUpdate:
    err := update(ctx, param)
    return err
case ActionDelete:
    err := delete(ctx, param)
    return err
default:
    return fmt.Errorf("unsupported action: %s", param.Action)
}
```

## Function Shape

A good Go function usually has guard clauses, small setup, ordered operation steps, local error handling, and a clear return. It should read like a short business procedure, not like a packed script and not like a table of contents that forces constant jumping.

Balance function granularity with these rules:

- Keep one function at one abstraction level. A service method may say "validate param, load data, enrich result, serialize response"; it should not also hide unrelated HTTP parsing or raw SQL details.
- Prefer 3-7 ordered business steps in the main function. Fewer steps may be clearer inline; many more steps usually means a real subtask should be named.
- Split when a block crosses a data domain, has a stable business name, is reused, isolates side effects, handles a complex branch, or makes the main flow readable without hiding essential decisions.
- Do not split when the helper name is vague, the body is only one or two obvious lines, the helper only forwards arguments, or the reader must jump through several helpers to understand one simple operation.
- Prefer semantic local variables before helpers for small expressions and one-off transformations.
- Avoid "helper chains" where `A()` only calls `B()`, `B()` only calls `C()`, and each layer adds no business decision.

## Thin Wrapper Ban

Do not add meaningless thin wrappers. Before adding a helper or method, it must satisfy at least one of these conditions:

- It is reused by two or more call sites with the same business meaning.
- It names a stable business concept that is clearer than the inline code.
- It isolates a real side effect, such as a transaction, external call, batch query, cache maintenance, goroutine, or complex conversion.
- It owns a complex branch or cross-domain aggregation that would distract from the main flow.
- The main function already has more than 7 same-level business steps and the extraction makes the primary procedure easier to read.

Do not add helpers for these cases:

- The helper only forwards to another service, DAL, client, or function.
- The body is one or two obvious lines of assignment, nil check, type conversion, or simple condition.
- The helper only hides a single `if` condition or boolean expression that could be a named local variable.
- The helper has a vague name such as `processData`, `handleResult`, `buildInfo`, `prepareData`, `doCreate`, or `checkData`.
- The helper has a single call site and no clear side-effect boundary or stable domain meaning.
- The helper turns a readable linear flow into a jump chain.

Prefer inline code or semantic local variables when the operation is short and local to one function. Existing thin wrappers may remain for compatibility, but do not copy the pattern or add more.

Prefer methods with receivers for behavior that belongs to a struct. Except for real shared utilities such as `utils` helpers, avoid loose package-level functions with no owner. Put business behavior on the service/API/model/param/helper struct that owns the state or responsibility. If a function's first parameter is the struct that clearly owns the behavior, make it a pointer receiver method unless it is a genuinely generic utility.

Domain normalization belongs to the struct that owns the fields being normalized. If logic trims, fills defaults, normalizes IDs, derives fields, fixes enum aliases, or prepares persisted/query/update fields from a specific struct's data, implement it on that struct's public `Serialize()` method. Do not create `Normalize()`, `FillDefault()`, lower-case normalization helpers, or package-level functions for logic that clearly belongs to one struct. Keep package-level functions only for truly general, domain-neutral utilities with no clear field owner, such as primitive string helpers or generic collection helpers.

If `Serialize()` or `Deserialize()` exists for a struct, do not add another method or function with overlapping normalization, defaulting, derived-field, serialization, or deserialization responsibilities. Avoid aliases, wrappers, migration shims, or lower-case variants for the same behavior.

Common domain lifecycle methods must use fixed exported names and signatures:

```go
func (vi *Xxx) Serialize() *Xxx
func (vi *Xxx) Deserialize() *Xxx
func (vi *Xxx) ToUpdater() map[string]any
func (vi *Xxx) Check() error
func (vi *Xxx) Same(after *Xxx) bool
```

For this lifecycle method group, do not introduce lower-case variants such as `serialize()` or alternate signatures such as `Serialize()`, `Serialize(ctx context.Context)`, `Check(param Xxx) error`, or `ToUpdater(data *Xxx) map[string]any`. This restriction does not forbid framework or interface adapter methods with their required signatures, such as GORM `TableName() string`, `MarshalJSON() ([]byte, error)`, or other established project adapter methods.

All methods must use pointer receivers. Do not use value receivers, even for read-only methods or small structs. A single struct must not mix value receiver methods and pointer receiver methods; if both forms exist, convert the value receiver methods to pointer receivers so the whole struct uses one receiver style. The receiver variable name must also be consistent for every method on the same struct. Do not use `s` on one `XxxSrv` method and `srv` on another, or `vi` on one model method and `m` on another. Receiver names are standardized by layer: service uses `s`, DAL uses `dal`, API uses `api`, model-layer types whose names contain `Param` use `p`, and other model-layer objects use `vi`.

Service/API/DAL dependencies should be injected through constructors or explicit struct fields following the corresponding layer reference. Do not create DALs, services, clients, caches, or loggers ad hoc inside business methods when they are long-lived dependencies. Keep dependency field order and constructor parameter order consistent; common order is persistence dependencies first, then cross-domain services, infrastructure/cache/clients, config or small helpers, and logger last.

Dependency ownership rules:

- Struct fields declare long-lived collaborators only: DAL/service interfaces, DB handles, cache, external clients, config, clocks, ID generators, small stateless helpers, and logger.
- Constructors wire those collaborators and keep parameter order aligned with field order.
- Business methods create only request-scoped values: params, local result containers, query builders, timeout contexts, transactions, timers, and temporary maps/slices.
- Adding a dependency means updating struct fields, constructor parameters, constructor assignments, and bootstrap/call sites together.
- Avoid method-local `NewXxxSrv`, `NewXxxDao`, `NewClient`, `NewCache`, or `utils.NewLogEvent` calls unless the object is intentionally short-lived and not a service dependency.
- Long-lived dependencies must be non-nil by construction, initialization, or bootstrap. Do not add branches that skip calls, validation, writes, cache maintenance, or logging just because an injected service, DAL, DB, cache, client, helper, or logger is nil. Fix the wiring or startup validation instead.
- This dependency rule does not forbid ordinary input nil checks, model/param receiver nil handling, panic recover checks, or explicit contracts where a callee documents `(nil, nil)` as a valid result.

## Defensive Check Boundary

Do not add defensive checks just to make internal code look safer. A defensive check is allowed only when it protects a real boundary or contract:

- API/request boundary: user input from query, body, header, path, files, or auth/session context.
- External system boundary: HTTP/RPC/MQ responses, file reads, third-party SDK data, DB rows that can be absent, cache misses, or decoded payloads.
- Real panic risk: map/slice indexing, type assertion, nil pointer from optional input, reflection, unsafe operations, or unmarshalling dynamic data.
- Public method contract explicitly accepts nil, zero value, empty input, or `(nil, nil)`.
- Model lifecycle methods that intentionally handle nil receivers, such as `Serialize()` and `Deserialize()`.
- Goroutine panic recovery and cleanup paths where failure must be observed.

Do not add these defensive checks:

- Checking injected service, DAL, DB, cache, client, helper, or logger for nil and then skipping logic or returning success.
- Rechecking fields that the current flow already validated through `Check()` or equivalent boundary validation.
- Checking objects that were just created in the same function with `make`, composite literals, or constructors that must return usable values.
- Checking a `(value, error)` result for nil when the callee contract says `value` is usable whenever `err == nil`.
- Changing an initialized empty slice/map into nil or adding special branches for empty results that the caller can already handle.
- Silently degrading for impossible internal states instead of returning an error or fixing the invariant.

When a check is necessary, keep it close to the boundary that introduces uncertainty. Once a value has crossed validation or construction, downstream code should rely on the contract instead of repeating the same guard.

Good:

```go
func (vi *Xxx) Check() error {
    return nil
}
```

Avoid:

```go
func (vi Xxx) Check() error {
    return nil
}
```

Also avoid mixed receivers on the same struct:

```go
func (vi Xxx) Name() string {
    return vi.Name
}

func (vi *Xxx) Serialize() *Xxx {
    return vi
}
```

Use pointer receivers consistently instead:

```go
func (vi *Xxx) Name() string {
    return vi.Name
}

func (vi *Xxx) Serialize() *Xxx {
    return vi
}
```

## Domain Method Shape

- `Serialize()` 统一承载 trim、default、normalize、derive、fill、序列化文本字段、派生查询/更新字段等规整职责。
- `Serialize()` 和 `Deserialize()` 修改 receiver，不接收参数，返回 receiver 指针。
- `Serialize()` 和 `Deserialize()` 在 receiver 为 nil 时必须新建一个对象，并返回这个对象；非 nil 时直接修改并返回原 receiver。
- `Serialize()` 和 `Deserialize()` 方法体内不创建规整副本；除 nil receiver 分支用于创建接收对象外，不新建替代对象。
- 调用方必须用原变量接收 `Serialize()` / `Deserialize()` 返回值，例如 `req = req.Serialize()`、`item = item.Deserialize()`，否则 nil receiver 场景下新对象会丢失。
- `ToUpdater()` 不接收参数，返回已初始化的 `map[string]any`。
- `Check()` 不接收参数，只返回 `error`；它只做校验，不做 trim/default/derive/fill。
- `Same(after *Xxx) bool` 只接收同类型对象指针并返回比较结果。
- `Serialize()`、`Deserialize()`、`ToUpdater()`、`Check()`、`Same()` 内部不要互相调用；这些方法的组合顺序完全由外部调用方决定。
- 单个领域方法尽量在一个函数内完成，不为同一 struct 拆出私有规整、校验、比较、updater helper。只有真正通用、无字段归属的标准库或项目工具函数可以被调用。
- 这组生命周期方法必须是大写公有方法，即使当前项目里已有小写或其他签名，也按固定签名生成和重构；框架/接口适配方法不属于这组限制，按适配方要求的签名实现，例如 GORM `TableName() string`。

Good:

```go
func (p *RequestParam) Serialize() *RequestParam {
    if p == nil {
        p = &RequestParam{}
    }
    p.Name = strings.TrimSpace(p.Name)
    return p
}

req = req.Serialize()
req.Check()

updater := req.ToUpdater()
```

Avoid:

```go
func (p *RequestParam) normalize() {}

func (p *RequestParam) Normalize() *RequestParam {}

func (p *RequestParam) FillDefault() {}

func (p *RequestParam) serializeName() {}

func (p *RequestParam) Check() error {
    p.Serialize()
    return nil
}

func (p *RequestParam) Serialize() {}

func (p *RequestParam) Serialize() *RequestParam {
    ans := &RequestParam{}
    ans.Name = strings.TrimSpace(p.Name)
    return ans
}

req.Serialize()

func SerializeRequestParam(p *RequestParam) {}
```

## File And Line Length

- A single file should not become too long or carry too many responsibilities.
- Split files by type group, responsibility, route group, method family, or established local convention.
- Public structs that are not model-layer types may live in a shared `structs` directory.
- Keep those non-model shared structs in one consistent place instead of scattering them across service, API, DAL, or helper files.
- If a struct belongs to model semantics, param validation, serialization, or database mapping, keep it in the model layer rather than moving it to `structs`.
- Do not create tiny fragmented files only to reduce line count; split when it improves navigation and ownership.
- A single line should not be too long.
- Wrap long function calls, chained calls, struct literals, slices/maps, and complex conditions at natural boundaries.
- Prefer readable multi-line formatting over dense one-line expressions.

## Constants

- Put all constants in the project-defined `consts` directory.
- Do not define constants in model, API, service, DAL, helper, handler, or function bodies.
- Model-related constants, enum values, defaults, and field constraints also belong in `consts`; model code may reference them, but must not define them locally.
- Organize constants inside `consts` by business responsibility so ownership stays clear.
- Prefer named constants over repeated magic strings or numbers.

## Naming

- Types and functions use business meaning: `SearchPolicyParam`, `BuildSummary`, `ValidateOwner`.
- Public interfaces and methods should describe the resource and action at a reusable level. Do not encode the current caller, owner, tenant, or scene into method names such as `SearchXxxForUser`, `UpdateXxxForProject`, `CreateXxxForOrg`, or `DeleteXxxForWorkspace`.
- Prefer a general method plus typed param fields for constraints: use `SearchXxx(ctx, param)` with `param.UserID`, `param.ProjectID`, or `param.OwnerID`; use `UpdateXxx(ctx, param)` or `UpdateXxx(ctx, id, data)` with checked fields instead of creating a new method per caller scenario.
- Add a specialized method name only when the behavior is genuinely different, stable, and not expressible as filters or command fields, such as a separate domain action with distinct side effects.
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

## Return Values For Debugging

- Do not mechanically forbid every direct `return xxx()`. Decide by debugging value and readability.
- If the return expression is a business call, I/O call, DAL/service/client call, complex conversion/construction, chained call, error wrapper, or a result whose intermediate value may need inspection, assign it to a local variable first and then return it.
- If the return expression is very direct, side-effect-free, and does not need an intermediate breakpoint, it may be returned directly.
- For `(value, error)` calls, split the call into `value, err := ...`, handle `err`, then `return value, nil`.
- For final conversions or cleanup with real computation, assign the converted value to a local variable before returning it.
- Direct return is fine for simple values such as `nil`, `err`, `true`, `false`, `0`, `""`, constants, field access, `fmt.Errorf("...")`, `errors.New("...")`, and stable adapter methods that return a literal or stable value such as `vi.TableName()`.

Good:

```go
result, err := client.Do(ctx, req)
if err != nil {
    return nil, err
}
return result, nil

value := strings.TrimSpace(raw)
return value

return fmt.Errorf("unsupported action: %s", param.Action)

return vi.TableName()
```

Avoid:

```go
return client.Do(ctx, req)

return strings.TrimSpace(raw)

return buildResult(input)

return repo.Find(ctx, id)

return wrapSearchErr(err)

return data.Serialize()

return db.Updates(updater).Error
```

## Types And Interfaces

- Function inputs and outputs should prefer defined structs or concrete types.
- Function inputs and outputs should each usually stay within 3 values. If a signature needs more, prefer a named param struct, result struct, or option pattern.
- Function and method call arguments should be variables, constants, literals, or simple field/index access. Do not pass another function or method call result directly as an argument; assign it to a meaningful local variable first so the value can be named, inspected, and debugged.
- Slice/map return values must be non-nil by contract. This includes error paths such as `(items, 0, err)` instead of `(nil, 0, err)` when `items` is a slice return value.
- Prefer plain primitive fields and params such as `string` and `int64`.
- Avoid named primitive wrappers such as `type Kind string` unless there is a real need: an external API or third-party library requires the type, the type owns meaningful methods, or a strong type-safety boundary prevents practical bugs.
- Constants for allowed values still belong in `consts`; they do not require a matching named primitive type.
- Numeric types across project code should use `int64` by default, including struct fields, function/method parameters, return values, counters, paging values, IDs, timestamps, and values passed between API/service/DAL/model layers.
- Use other numeric types only when necessary for external API contracts, third-party library signatures, byte-size data, proven memory/performance needs, or existing compatibility constraints.
- Do not introduce `int`, `int32`, `uint`, `uint64`, or other numeric aliases only because the current value range is small; prefer `int64` for project consistency.
- Do not preserve non-`int64` numeric types only for old implementation compatibility; keep compatibility only when the external contract or migration risk makes it necessary.
- Avoid `any`, `interface{}`, `map[string]any`, and broad data interfaces for request params, response values, and business data, except for model-layer `ToUpdater()` which must return `map[string]any`.
- Use small behavior interfaces only when callers truly vary by behavior, such as `io.Reader`, `context.Context`, or a narrow project interface.
- If data has a stable shape, define a struct even when only a few fields are currently used.
- Keep `any` for unavoidable boundaries such as generic helpers, JSON/raw dynamic payloads, logging fields, or third-party APIs; convert to typed structs as soon as practical.
- Keep common Go return shapes such as `(value, error)` or `(list, count, error)` when they match local conventions.

Good:

```go
messages := buildTextMessages(prompt, opts)
resp, err := g.chatModel.Generate(ctx, messages)
```

Avoid:

```go
resp, err := g.chatModel.Generate(ctx, buildTextMessages(prompt, opts))
```

## Tags

- Do not use `omitempty` in JSON tags.
- Avoid tags such as `json:"name,omitempty"` or `json:",omitempty"`.
- Prefer explicit zero values in API responses and serialized data so callers can distinguish absent fields from empty values by contract, not by implicit tag behavior.

## Time Fields

- For newly designed tables or features, use `int64` millisecond timestamps for all time-related fields.
- Keep the same millisecond unit across database storage, model fields, params, responses, frontend/backend payloads, service calls, DAL queries, cache payloads, and serialized data.
- Use `time.Now().UTC().UnixMilli()` when generating current timestamps.
- Do not migrate existing features from their established time unit unless the task explicitly asks for that migration.

## Error Handling

- Return errors immediately unless there is a clear recovery path.
- Wrap or translate errors according to project convention.
- Include useful context in logs or wrapping, but avoid leaking sensitive values.
- If a secondary cleanup/maintenance error is intentionally ignored, make that explicit.
- Use `errors.Is` / `errors.As` when comparing wrapped errors if the project uses standard wrapping.
- For functions that return `(value, error)` and whose contract says `value` is usable when `err == nil`, do not add repetitive defensive `if value == nil` checks at call sites. The callee should return an error when it cannot provide a usable value; only keep a nil check when the function explicitly allows `(nil, nil)`.
- Do not treat a nil injected dependency as a recoverable runtime condition. Code such as `if s.cache != nil { ... }`, `if dal.db == nil { return res, 0, nil }`, or `if api.srv == nil { response.JSONOK(ctx, nil); return }` hides wiring errors and is not allowed.

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
            err := fmt.Errorf("panic: %v", r)
            log.Err(err).Msg("worker panic")
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
