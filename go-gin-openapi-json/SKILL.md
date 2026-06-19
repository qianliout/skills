---
name: "go-gin-openapi-json"
description: "Generate or refresh Apifox-importable OpenAPI 3.1.0 JSON for specified Go + Gin interfaces only, using the current backend code. Use when the user asks for openapi.json, OpenAPI JSON, Apifox import docs, selected Gin route documentation, requestBody/parameters/responses, or components.schemas generated from router, handler/controller, request/response structs, tags, validation, comments, and project response helpers. Requires a specified interface scope such as method+path, handler name, route group, or module subset. Always rebuild selected docs from latest code, JSON only, no YAML, no historical merge."
---

# Go Gin OpenAPI JSON

Iron Law: generate documentation only for the interfaces the user specified. Use current Go code as the source of truth, but do not include every project route unless the user explicitly lists those routes as the target scope.

## Required Coordination

- Load and apply `go-api-layer` before interpreting Gin handlers when that skill is available.
- Follow `go-api-layer` request-source conventions: `POST` body, `PUT` query ID/uniqueID plus body, other methods query by default, unless the existing project code proves a different pattern.
- Prefer project code-discovery tools such as `codebase-memory-mcp` graph search when available; fall back to `rg`, Go AST inspection, and direct file reads only when graph tools are missing or insufficient.

## Output Contract

- Generate JSON only. Do not generate YAML.
- Use OpenAPI version `3.1.0`.
- Generate one final JSON document containing only the specified interfaces. If the project is large, create temporary fragments only as working material, then aggregate selected interfaces into the final file.
- If the user specifies an output path or filename, write there. Otherwise infer the best location, usually the project root `openapi.json`.
- Infer `info.title` and `info.version` from project config, module/service name, README, build config, or runtime config. Use reasonable defaults only when the project does not expose better values.
- Keep the top-level shape aligned with `openapi.json` in this skill: `openapi`, `info`, `tags`, `paths`, `components.schemas`, `components.responses`, `components.securitySchemes`, `servers`, `security`.
- The result must be valid JSON and directly importable into Apifox.

## Interface Scope

- Require an explicit target scope before generating docs.
- Accept target scopes as method+path, path prefix, handler/function name, API struct method, route group, module/package subset, or a short list of routes.
- Scan the wider project only to resolve selected routes, handlers, models, response helpers, shared DTOs, and dependencies.
- Exclude every route that is outside the requested scope, even if it is discovered during scanning.
- If the user asks to "scan the whole project", treat that as discovery scope, not documentation scope. Ask which interfaces should be included.
- If no target interface is specified, stop and ask for the smallest useful selector: route path, HTTP method+path, handler name, route group, or module.

## Bundled Example

- This skill includes `openapi.json` as the required output-style example.
- Read the bundled example before generating a document when the user asks for Apifox-compatible output, example alignment, or does not provide another template.
- Treat the example as shape guidance only. Replace every route, schema, title, version, parameter, response, description, and example value with facts inferred from the target project.

## Invocation Examples

Use this skill for prompts like:

- "用 `$go-gin-openapi-json` 给 `PUT /api/v2/containerSec/scanner/security/detect/policy` 生成 `openapi.json`。"
- "扫描整个项目解析依赖，只为 `UserAPI.CreateUser` 和 `UserAPI.UpdateUser` 生成可以导入 Apifox 的 OpenAPI JSON，输出到 `docs/openapi.json`。"
- "刷新 `/api/v1/users` 路由组的 Gin 接口文档，只按最新代码重建，不保留旧接口。"

Expected result:

- Create or overwrite exactly one final OpenAPI JSON file containing only selected interfaces.
- Report the output path and the validation result.
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
- Do not generate Swagger UI, markdown API docs, or client SDKs.

## Workflow

1. Identify the target interface scope, Go project root, and output path.
2. If the target interface scope is missing or ambiguous, ask for route path, method+path, handler name, route group, or module subset before generating.
3. Read the sample `openapi.json` in this skill if the user wants example alignment or no project-specific template exists.
4. Discover Gin route registration enough to resolve only the selected method/path/handler bindings.
5. Trace each selected handler/controller using `go-api-layer` conventions to identify query, path, header, body, response helper, status code, and service-returned DTOs.
6. Resolve request/response/model structs and their tags, comments, validation, serialization, and `Check()` methods for selected interfaces only.
7. Infer the project-wide response envelope from response helpers and DTOs, such as `JSONOK`, `JSONError`, `WithItem`, `WithItems`, `code/message/data`, or `apiVersion/data`.
8. Build `components.schemas` only for schemas referenced by selected operations.
9. Add descriptions, examples, and required fields for every documented field.
10. Write stable, pretty-printed JSON and validate it parses.
11. Re-check all `$ref` values, path parameters, body models, and response envelopes before delivery.

## How To Generate The File

1. Locate the Go module with `go.mod`; use the nearest git root only if no module root is clearer.
2. Build a route inventory only as needed to match the requested selectors: final path, HTTP method, handler symbol, route group prefix, middleware hint, and source file.
3. Filter the inventory to selected interfaces before creating OpenAPI operations.
4. For each selected handler, build an operation record: summary, query/path/header parameters, request body schema name, response schema name, status code, tags, and unresolved notes.
5. Build a schema registry from every request, response, DTO, and model struct referenced by selected operation records.
6. Resolve references until every `$ref` points to an entry in `components.schemas`.
7. Compose the OpenAPI object in memory, using `3.1.0` and the inferred `info` values.
8. Write pretty JSON with two-space indentation.
9. Run JSON parsing validation after writing. If available, also run an OpenAPI validator or Apifox-compatible import check.
10. Deliver the path and concise counts: selected operations, schemas, unresolved items.

Minimal output report:

```text
Generated <output-path>
OpenAPI: 3.1.0
Operations: <n>
Schemas: <n>
Validation: JSON parsed successfully
```

## Route Discovery

- Resolve `Group()` nesting and route prefixes into complete paths.
- Support `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, and project-defined wrappers around Gin route methods.
- Convert Gin path params from `:id` to OpenAPI `{id}`.
- Preserve only selected routes that are statically supported by the current code. If dynamic registration cannot be resolved, report the missing facts instead of guessing.
- If multiple router entry points exist, infer the selected scope from user request, package names, bootstrapping code, or project layout. Ask only when multiple plausible matches remain.
- Do not add neighboring routes from the same group unless the user selected the whole group.

## Handler Analysis

For each route, identify:

- Handler function or API struct method.
- Request binding calls such as `ShouldBindJSON`, `BindJSON`, `ShouldBindQuery`, `ShouldBindUri`, `ShouldBindHeader`, project wrappers, `Query`, `DefaultQuery`, `Param`, and `GetHeader`.
- Typed param/request structs passed to service methods.
- `Serialize()` and `Check()` methods that set defaults, normalize fields, or enforce required fields.
- Response calls such as `JSONOK`, `JSONError`, `ctx.JSON`, `c.JSON`, `WithItem`, `WithItems`, and pagination options.
- DTO/model types returned by services when the handler itself is thin.

Keep API documentation at the HTTP contract level. Do not document service-only workflow or database internals as API fields.

## Parameters

### Header

- Add exactly one header parameter to every operation: `Authorization`.
- Do not emit `authority`, custom token headers, or other headers unless the user explicitly changes this skill requirement.
- Use `in: header`, `required: false`, `schema.type: string`, and an example such as `Bearer <token>`.

### Path

- Every `{param}` in the OpenAPI path must have a matching `parameters` entry.
- Path params are always `required: true`.
- Use `uri` tags and `ShouldBindUri` structs when available for type, description, and example.

### Query

- Use `form`, `query`, direct `Query` calls, and project helper calls to build query parameters.
- For `PUT`, IDs such as `id` or `uniqueID` normally remain query parameters per `go-api-layer`.
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
- If a struct lacks JSON tags, derive stable lower-camel JSON names only when the field is part of a JSON body/response.

### Required

Add a field to `required` when supported by code evidence:

- `binding:"required"`
- `validate:"required"`
- project validator tags that mean required
- non-pointer, non-`omitempty` fields in request/response DTOs when the project convention treats them as required
- explicit `Check()` logic that rejects empty values
- path parameters

When uncertain, leave the field out of `required`.

### Type Mapping

- `string` -> `type: string`
- `bool` -> `type: boolean`
- signed and unsigned integers -> `type: integer`
- `float32`, `float64` -> `type: number`
- slices and arrays -> `type: array`
- maps -> `type: object`
- structs -> `type: object` or `$ref`
- `time.Time` -> `type: string`, `format: date-time`
- project millisecond timestamps -> `type: integer`, `format: int64`
- pointers use the underlying type; required/nullability is decided separately.

## Descriptions And Examples

- Every operation should have a `summary`. Prefer route comments, handler comments, method names, and domain names.
- Every documented field should have `description` and `example`.
- Description priority: field comment, type comment, handler/API comment, validation tag, enum constants, field name semantics, then type/context inference.
- Example priority: explicit example/default tags, enum constants, fixtures/tests, field name semantics, then type-based examples.
- If inferring, keep the value conservative and recognizable: IDs as `123`, names as `"示例名称"`, timestamps as `1735689600000` or ISO strings depending on code type, booleans as `true`, emails as `"user@example.com"`.
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
- [ ] Project response envelope is inferred from code and applied consistently.
- [ ] Every schema property has `type`, `description`, and `example` when representable.
- [ ] `required` arrays are based on tags, validation, `Check()`, pointer/omitempty conventions, or code checks.
- [ ] Apifox can import the generated JSON without structural errors.

## Failure Handling

Stop and report missing facts instead of fabricating documentation when:

- route registration is too dynamic to statically resolve,
- handler wrappers hide the real request or response types,
- multiple response envelopes are equally plausible,
- the user did not specify which interfaces to document,
- the requested selector matches multiple unrelated routes,
- build tags select incompatible route sets and the active target cannot be inferred,
- required project files are unavailable.

In the report, ask for the smallest useful input: method+path, handler name, route group, target module, response helper, or output path.
