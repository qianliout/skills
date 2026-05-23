# Go API Layer Conventions

Use this reference when generating, refactoring, or reviewing general Go API/handler/controller layer code.

## Responsibility

API layer owns HTTP adaptation:

- Read query/header/body from the framework context.
- Build typed API params.
- Run request validation when the param provides `Check()`.
- Call service methods.
- Convert service errors with project wrappers/i18n when needed.
- Return data through project response helpers.

API layer should stay thin. It does not own database access, cross-DAL aggregation, complex parameter assembly, complex response assembly, long business workflows, or model serialization.

## Structure

Typical shape:

```go
type XxxAPI struct {
    xxxSrv service.XxxService
}

func NewXxxAPI(xxxSrv service.XxxService) *XxxAPI {
    return &XxxAPI{xxxSrv: xxxSrv}
}
```

Rules:

- Keep API struct narrow: service dependencies, logger, or tiny stateless helpers.
- Dependency validity is guaranteed by construction/bootstrap; avoid repeated nil checks in handlers.
- Handler methods use pointer receivers and the project framework signature, commonly `func (api *XxxAPI) Action(ctx *gin.Context)`.
- Do not use value receivers for API/handler methods.

## Request Parsing

- Use query params for all request parameters; do not use path params.
- Use project helpers for query/header parsing.
- Use `ShouldBindJSON`, `BindJSON`, or the project wrapper for JSON body binding.
- Convert raw HTTP strings into a typed param before calling service.
- Prefer one param struct over many positional arguments.
- Put params and response DTOs at the model/API type layer, not inside handler functions.
- Put trim, enum validation, ID normalization, default values, and derived fields in `param.Check()` or param methods.

## HTTP Methods

Use only these methods by default:

- `GET`: read-only list/detail.
- `POST`: create, submit action, non-idempotent operation.
- `PUT`: full update.
- `DELETE`: delete.

Do not introduce `PATCH`, `HEAD`, `OPTIONS`, or other HTTP methods unless the user explicitly confirms the exception.

Example:

```go
param := model.SearchXxxAPIParam{
    Keyword: util.GetKeywordFromQuery(ctx, "keyword"),
    Status:  util.GetKeywordFromQuery(ctx, "status"),
    Filter:  model.GetFilter(ctx).SetMaxLimit(consts.DefaultMaxLimit),
}
if err := param.Check(); err != nil {
    response.JSONError(ctx, err)
    return
}
```

## Update Pattern

PUT updates must be full updates:

- The update ID is required in query, such as `?id=123`.
- The body contains the full update content.
- Do not use path params for the ID.
- Do not treat PUT as partial update.

Example:

```go
id := util.GetInt64FromQuery(ctx, "id")
body := model.UpdateXxxBody{}
if err := ctx.ShouldBindJSON(&body); err != nil {
    response.JSONError(ctx, response.NewHttpError(http.StatusBadRequest, err))
    return
}

param := model.UpdateXxxAPIParam{
    ID:   id,
    Data: body,
}
```

## Response Pattern

List response:

```go
items, cnt, err := api.xxxSrv.SearchXxx(ctx, param)
if err != nil {
    response.JSONError(ctx, wrapSearchXxxErr(err))
    return
}

response.JSONOK(ctx,
    response.WithItems(items),
    response.WithTotalItems(cnt),
    response.WithItemsPerPage(param.Filter.Limit),
    response.WithStartIndex(param.Filter.Offset),
)
```

Single item response:

```go
item, err := api.xxxSrv.GetXxxDetail(ctx, param)
if err != nil {
    response.JSONError(ctx, err)
    return
}
response.JSONOK(ctx, response.WithItem(item))
```

Rules:

- Return immediately after `JSONError`.
- Use empty slices for successful empty lists.
- Include pagination metadata when the endpoint is paginated.
- Do not expose raw low-level errors if the project has service/API error wrappers.

## Handler Complexity

Keep handlers short. API logic should be simple: parse request, build typed param, call service, return response. Move logic to service when the handler:

- Calls multiple services or repeatedly calls one service in a loop.
- Builds complex service params from many intermediate values.
- Builds complex response objects from multiple data sources.
- Builds association maps or performs cross-resource aggregation.
- Contains complex branch rules.
- Mutates persistence data.
- Needs retries, transactions, async work, or cache coordination.

Small response shaping is acceptable, but complex assembly and domain decisions belong in service.

## Type Rules

- Prefer typed params and DTO structs over `any`, `interface{}`, or `map[string]any`.
- Function inputs and outputs should usually stay within 3 values; use param/result structs when needed.
- Avoid defining request/response structs inside handler functions.
- Do not introduce `uint64`, `uint`, `bool`, or numbers larger than `int64`; follow model-layer type constraints.
- Use string states such as `"true"` / `"false"` when the project avoids bool fields.

## Formatting And Tests

- Run `goimport` after editing Go files.
- Prefer targeted tests for the touched package.
- If route registration or middleware behavior changes, verify the route wiring and expected HTTP status/error shape.
