# Go Gin OpenAPI JSON Conventions

Use this reference when generating, refreshing, reviewing, or explaining OpenAPI JSON for selected Gin interfaces.

## Contents

- [Output Contract](#output-contract)
- [Interface Scope](#interface-scope)
- [Bundled Example](#bundled-example)
- [Invocation Examples](#invocation-examples)
- [Creation Mode](#creation-mode)
- [Non-Goals](#non-goals)
- [Generation Details](#generation-details)
- [Route Discovery](#route-discovery)
- [Handler Analysis](#handler-analysis)
- [Parameters](#parameters)
- [Responses](#responses)
- [Schemas](#schemas)
- [Descriptions And Examples](#descriptions-and-examples)
- [JSON Shape Rules](#json-shape-rules)
- [Quality Checklist](#quality-checklist)
- [Failure Handling](#failure-handling)

## Output Contract

- Generate JSON only. Do not generate YAML.
- Use OpenAPI version `3.1.0`.
- Generate one final JSON document containing only the specified interfaces. If the project is large, create temporary fragments only as working material, then aggregate selected interfaces into the final file.
- If the user specifies an output path or filename, write there. Otherwise infer the best location, usually the project root `openapi.json`.
- Infer `info.title` and `info.version` from project config, module/service name, README, build config, or runtime config. Use reasonable defaults only when the project does not expose better values.
- Keep the top-level shape aligned with `assets/openapi.json`: `openapi`, `info`, `tags`, `paths`, `components.schemas`, `components.responses`, `components.securitySchemes`, `servers`, `security`.
- The result must be valid JSON and directly importable into Apifox.

## Interface Scope

- Require an explicit target scope before generating docs.
- Accept target scopes as method + path, path prefix, handler/function name, API struct method, route group, module/package subset, or a short list of routes.
- Scan the wider project only to resolve selected routes, handlers, models, response helpers, shared DTOs, and dependencies.
- Exclude every route outside the requested scope, even when discovered during scanning.
- Treat "scan the whole project" as discovery scope, not documentation scope, unless the user explicitly selects the whole project as the interface scope.
- If no target interface is specified, stop and ask for the smallest useful selector: route path, HTTP method + path, handler name, route group, or module.

## Bundled Example

- Use `assets/openapi.json` as the required output-style example when the user asks for Apifox-compatible output, example alignment, or does not provide another template.
- Treat the example as shape guidance only. Replace every route, schema, title, version, parameter, response, description, and example value with facts inferred from the target project.

## Invocation Examples

Use these rules for prompts such as:

- "用 `$go` 给 `PUT /api/v2/containerSec/scanner/security/detect/policy` 生成 `openapi.json`。"
- "扫描整个项目解析依赖，只为 `UserAPI.CreateUser` 和 `UserAPI.UpdateUser` 生成可以导入 Apifox 的 OpenAPI JSON，输出到 `docs/openapi.json`。"
- "刷新 `/api/v1/users` 路由组的 Gin 接口文档，只按最新代码重建，不保留旧接口。"

Expected result:

- Create or overwrite exactly one final OpenAPI JSON file containing only selected interfaces.
- Report the output path and validation result.
- Mention unresolved routes or response models only when they could not be inferred from code.

## Creation Mode

- If no OpenAPI file exists, create a new file.
- If an OpenAPI file already exists at the selected output path, overwrite it with a full rebuild.
- Do not stop at a plan or requirements summary when the user asks to generate or refresh docs and has specified target interfaces. Inspect the project, generate the JSON, write the file, and validate it.
- Use the user's requested output path when provided. Otherwise infer the project root from `go.mod`, router entry, or git root and write `<project-root>/openapi.json`.
- Create the parent directory if the user specified a path whose directory does not exist.
- If the output would overwrite a user-specified non-OpenAPI file, ask before writing.

## Non-Goals

- Do not maintain multiple document versions.
- Do not diff against old OpenAPI files.
- Do not preserve old fields, old endpoints, or old schemas for compatibility.
- Do not generate documentation for the whole project unless the user explicitly specified the whole project as the target interface scope.
- Do not use runtime traffic, browser traces, or online environments unless the user explicitly asks and provides access.
- Do not generate Swagger UI, Markdown API docs, or client SDKs.

## Generation Details

1. Locate the Go module with `go.mod`; use the nearest git root only if no module root is clearer.
1. Build a route inventory only as needed to match the requested selectors: final path, HTTP method, handler symbol, route group prefix, middleware hint, and source file.
1. Filter the inventory to selected interfaces before creating OpenAPI operations.
1. For each selected handler, build an operation record: summary, query/path/header parameters, request body schema name, response schema name, status code, tags, and unresolved notes.
1. Build a schema registry from every request, response, DTO, and model struct referenced by selected operation records.
1. Resolve references until every `$ref` points to an entry in `components.schemas`.
1. Compose the OpenAPI object in memory, using `3.1.0` and inferred `info` values.
1. Write pretty JSON with two-space indentation.
1. Run JSON parsing validation after writing. If available, also run an OpenAPI validator or Apifox-compatible import check.
1. Deliver the path and concise counts: selected operations, schemas, unresolved items.

Minimal output report:

```text
Generated <output-path>
OpenAPI: 3.1.0
Operations: <n>
Schemas: <n>
Validation: JSON parsed successfully
```

## Route Discovery

- Prefer project code-discovery tools such as `codebase-memory-mcp` graph search when available. Fall back to `rg`, Go AST inspection, and direct file reads only when graph tools are missing or insufficient.
- Resolve `Group()` nesting and route prefixes into complete paths.
- Support `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, and project-defined wrappers around Gin route methods when they exist in the target code.
- Convert Gin path params from `:id` to OpenAPI `{id}`.
- Preserve only selected routes that are statically supported by current code. If dynamic registration cannot be resolved, report the missing facts instead of guessing.
- If multiple router entry points exist, infer the selected scope from the user request, package names, bootstrapping code, or project layout. Ask only when multiple plausible matches remain.
- Do not add neighboring routes from the same group unless the user selected the whole group.

## Handler Analysis

For each selected route, identify:

- Handler function or API struct method.
- Request binding calls such as `ShouldBindJSON`, `BindJSON`, `ShouldBindQuery`, `ShouldBindUri`, `ShouldBindHeader`, project wrappers, `Query`, `DefaultQuery`, `Param`, and `GetHeader`.
- Typed param/request structs passed to service methods.
- `Serialize()` and `Check()` methods that set defaults, normalize fields, or enforce required fields.
- Response calls such as `JSONOK`, `JSONError`, `ctx.JSON`, `c.JSON`, `WithItem`, `WithItems`, and pagination options.
- DTO/model types returned by services when the handler itself is thin.

Use the request-source conventions in `references/api-layer.md` as defaults: `POST` body, `PUT` query ID/uniqueID plus body, and other methods query. When selected code proves a different contract, document the code as written.

Keep API documentation at the HTTP contract level. Do not document service-only workflows or database internals as API fields.

## Parameters

### Header

- Add exactly one header parameter to every operation: `Authorization`.
- Do not emit `authority`, custom token headers, or other headers unless the user explicitly changes this bundle requirement.
- Use `in: header`, `required: false`, `schema.type: string`, and an example such as `Bearer <token>`.

### Path

- Every `{param}` in an OpenAPI path must have a matching `parameters` entry.
- Path params are always `required: true`.
- Use `uri` tags and `ShouldBindUri` structs when available for type, description, and example.

### Query

- Use `form`, `query`, direct `Query` calls, and project helper calls to build query parameters.
- For `PUT`, IDs such as `id` or `uniqueID` normally remain query parameters per `references/api-layer.md`.
- Pagination fields must reflect the project's actual filter model names and examples.

### Request Body

- `POST`, `PUT`, `PATCH`, and update-like `POST` operations with body input must use `requestBody`.
- Body input must be modeled as a named schema under `components.schemas` and referenced with `$ref`.
- Prefer existing request/body structs. If a handler constructs body fields without a struct, derive a named request schema from the handler and route.
- Do not inline large body objects directly inside operations.
- Use `application/json` unless code clearly binds another content type.

## Responses

- Infer the success status code from code or response helpers; default to `200` only when the project does not expose a clearer value.
- Infer the project response envelope automatically from shared response helpers and response DTOs.
- If the project has a fixed envelope, wrap business data in that real envelope.
- Preserve list metadata such as `items`, `total`, `itemsPerPage`, and `startIndex` when response helpers expose it.
- Add stable error responses only when the code exposes a recognizable error shape.
- Include `headers: {}` in responses when aligning with the bundled sample shape.

## Schemas

### Naming

- Prefer Go struct names for `components.schemas`.
- Prefix with package or domain when two structs share the same name.
- Promote request bodies and reusable response DTOs to named schemas.

### Field Names

- Use `json` tags first.
- Ignore `json:"-"`.
- Use `form`, `uri`, and `header` tags for parameter names, not body field names.
- If a struct lacks JSON tags, derive stable lower-camel JSON names only when the field is part of a JSON body or response.

### Required

Add a field to `required` when supported by code evidence:

- `binding:"required"`.
- `validate:"required"`.
- Project validator tags that mean required.
- Non-pointer, non-`omitempty` fields in request/response DTOs when the project convention treats them as required.
- Explicit `Check()` logic that rejects empty values.
- Path parameters.

When uncertain, leave the field out of `required`.

### Type Mapping

- `string` maps to `type: string`.
- `bool` maps to `type: boolean`.
- Signed and unsigned integers map to `type: integer`.
- `float32` and `float64` map to `type: number`.
- Slices and arrays map to `type: array`.
- Maps map to `type: object`.
- Structs map to `type: object` or `$ref`.
- `time.Time` maps to `type: string`, `format: date-time`.
- Project millisecond timestamps map to `type: integer`, `format: int64`.
- Pointers use the underlying type; required and nullability are decided separately.

## Descriptions And Examples

- Every operation should have a `summary`. Prefer route comments, handler comments, method names, and domain names.
- Every documented field should have `description` and `example`.
- Description priority is field comment, type comment, handler/API comment, validation tag, enum constants, field name semantics, then type/context inference.
- Example priority is explicit example/default tags, enum constants, fixtures/tests, field name semantics, then type-based examples.
- When inferring, keep values conservative and recognizable: IDs as `123`, names as `"示例名称"`, timestamps as `1735689600000` or ISO strings depending on code type, booleans as `true`, and emails as `"user@example.com"`.
- Do not leave descriptions empty merely because comments are missing; infer short practical descriptions from code context.

## JSON Shape Rules

- Operations should include `summary`, `deprecated`, `description`, `tags`, `parameters`, optional `requestBody`, `responses`, and `security` when this matches the sample style.
- `components.schemas` must contain all referenced request and reusable response models.
- Prefer `$ref` for named models.
- Ensure every `$ref` target exists.
- Keep output ordering stable: top-level metadata first, then paths, then components.

## Quality Checklist

- [ ] `openapi` is exactly `3.1.0`.
- [ ] JSON parses successfully.
- [ ] The final file is a full rebuild for selected interfaces from current code, not a merge with older docs.
- [ ] Every path method maps to a selected real Gin route.
- [ ] No unselected routes are present in `paths`.
- [ ] Gin `:param` paths are converted to `{param}` and have required path parameters.
- [ ] Every operation has the `Authorization` header and no extra default headers.
- [ ] `POST`, `PUT`, `PATCH`, and update-like body inputs reference named request schemas.
- [ ] The project response envelope is inferred from code and applied consistently.
- [ ] Every schema property has `type`, `description`, and `example` when representable.
- [ ] `required` arrays are based on tags, validation, `Check()`, pointer/`omitempty` conventions, or code checks.
- [ ] Apifox can import the generated JSON without structural errors.

## Failure Handling

Stop and report missing facts instead of fabricating documentation when:

- Route registration is too dynamic to resolve statically.
- Handler wrappers hide the real request or response types.
- Multiple response envelopes are equally plausible.
- The user did not specify which interfaces to document.
- The requested selector matches multiple unrelated routes.
- Build tags select incompatible route sets and the active target cannot be inferred.
- Required project files are unavailable.

Ask for the smallest useful missing input: method + path, handler name, route group, target module, response helper, or output path.
