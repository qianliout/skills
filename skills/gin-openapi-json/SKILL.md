---
name: gin-openapi-json
description: "手动调用：从 Gin 框架 Go 代码为单个接口生成 OpenAPI 3.1.0 JSON 文档。不自动触发，仅在用户明确指定接口时使用。"
runAs: subagent
argument-hint: "<method+path|handler-name> [--output <filepath>]"
---

IRON LAW: 每次只生成一个接口。扫描到相邻路由、同组接口、同 handler 的其他方法时一律忽略。

每次生成都是对当前代码的全量重建。不兼容旧 JSON、不合并、不保留历史上存在但代码中已删除的字段或路由。

## Workflow

Copy this checklist and check off items as you complete them:

- [ ] Step 0: Run pre-flight script ⛔ BLOCKING
- [ ] Step 1: Confirm the single target interface ⚠️ REQUIRED
- [ ] Step 2: Load references and asset
- [ ] Step 3: Locate the route and handler
- [ ] Step 4: Analyze the handler and build the operation record
- [ ] Step 5: Build schema registry for this operation only
- [ ] Step 6: Resolve output path
- [ ] Step 7: Compose OpenAPI JSON
- [ ] Step 8: Write file and validate
- [ ] Step 9: Report result

### Step 0: Run Pre-Flight Script ⛔ BLOCKING

Before any code analysis, run the deterministic wrapper to validate inputs and resolve paths:

```bash
bash scripts/generate.sh <SELECTOR> [--output <path>]
```

This script:
- Validates the selector is non-empty
- Locates the Go project root by searching upward for `go.mod`
- Auto-generates the output filename if `--output` is not provided
- Creates the output parent directory via `mkdir -p`
- Emits a JSON object: `{ "selector", "output", "project_root" }`

If the script exits non-zero, stop and report the error. Do not proceed without a valid `project_root`.

### Step 1: Confirm the Single Target Interface ⚠️ REQUIRED

用户必须指定一个接口。只接受能定位到唯一 handler 的选择器：

- Method + path: `PUT /api/v2/containerSec/scanner/security/detect/policy`
- Handler 函数名: `UserAPI.CreateUser`

不接受模糊选择器（path prefix、route group、module/package），因为这些可能匹配多个接口。

如果选择器匹配到多个路由，列出匹配项并要求用户精确到其中一个。

If no target is specified, stop and ask.

### Step 2: Load References and Asset

Load `references/gin-openapi-json-conventions.md` for detailed generation rules.

Read `assets/openapi.json` only as a shape template — top-level keys, parameter layout, `$ref` nesting, response envelope pattern. Replace every concrete value with facts from the target code.

### Step 3: Locate the Route and Handler

1. Locate the Go module root from `go.mod`.
2. Search for the route: `rg "\.(GET|POST|PUT|PATCH|DELETE)\("` and resolve `Group()` nesting to the full path.
3. Convert Gin `:param` to OpenAPI `{param}`.
4. If route registration is too dynamic to resolve statically, stop and report the missing facts.

### Step 4: Analyze the Handler and Build the Operation Record

Read the handler source and identify:

- Request binding: `ShouldBindJSON`, `BindJSON`, `ShouldBindQuery`, `ShouldBindUri`, `Param`, `Query`, `DefaultQuery`, `GetHeader`.
- Typed request structs passed to service methods.
- Response calls: `JSONOK`, `JSONError`, `ctx.JSON`, `c.JSON`, `WithItem`, `WithItems`.
- DTO/model types returned by services.

Build a single operation record: summary, query/path/header parameters, request body schema name, response schema name, status code, tags.

Parameter defaults:
- `POST` → body from `ShouldBindJSON` struct
- `PUT` → query `id`/`uniqueID` + body from bind struct
- Other methods → query parameters
When code proves a different contract, document the code as written.

### Step 5: Build Schema Registry for This Operation Only

1. Collect every request DTO, response DTO, and nested struct referenced by this single operation.
2. For each struct, extract fields using `json` tags (ignore `json:"-"`).
3. Map Go types: `string`→string, `bool`→boolean, `int`/`int64`→integer, `float`→number, slice→array, struct→object/$ref, `time.Time`→string with `format: date-time`.
4. Determine `required` from `binding:"required"`, `validate:"required"`, non-pointer non-`omitempty` fields, and explicit `Check()` logic.
5. Add `description` and `example` for every field. Priority: field comments, type comments, validation tags, enum constants, field name semantics, type-based defaults.

### Step 6: Resolve Output Path

The output path is already resolved by `scripts/generate.sh` in Step 0. Use:

- `output` from the script's JSON if a specific path was provided or auto-generated
- Confirm the path with the user before writing

### Step 7: Compose OpenAPI JSON

Build the OpenAPI `3.1.0` object — every generation is a fresh new file:

```json
{
  "openapi": "3.1.0",
  "info": { "title": "...", "description": "", "version": "..." },
  "tags": [],
  "paths": { "<single-path>": { "<single-method>": { ... } } },
  "components": {
    "schemas": { ... },
    "responses": {},
    "securitySchemes": {}
  },
  "servers": [],
  "security": []
}
```

- `paths` contains exactly one path with exactly one method.
- Infer `info.title` and `info.version` from project config, module name, or README.
- The operation gets `summary`, `deprecated: false`, `description`, `tags`, `parameters`, optional `requestBody`, `responses`, `security`.
- Exactly one header parameter: `Authorization` (`in: header`, `required: false`, `schema.type: string`, example `Bearer <token>`).
- `requestBody` uses `$ref` to a named schema; do not inline body objects.
- Responses use the project's envelope (if one exists), wrapping business data.
- Include `headers: {}` in responses.
- Do not carry over any fields, schemas, or endpoints from any previous JSON file.

### Step 8: Write File and Validate

1. Create parent directories if needed.
2. Write the JSON with two-space indentation.
3. Validate JSON can be parsed.
4. Verify every `$ref` target exists in `components.schemas`.
5. Check all path `{param}` entries have matching required path parameters.

### Step 9: Report Result

```text
Generated <output-path>
OpenAPI: 3.1.0
Interface: <METHOD> <path>
Operations: 1
Schemas: <n>
Validation: JSON parsed successfully
```

Mention any unresolved facts.

## Anti-Patterns

- Do NOT generate more than one operation. `paths` must have exactly one path with one method.
- Do NOT inline body schemas inside operations — always use `$ref`.
- Do NOT fabricate fields, types, or descriptions not in the Go code.
- Do NOT guess route registrations too dynamic to resolve — report and stop.
- Do NOT generate YAML, Markdown, Swagger UI, or client SDKs.
- Do NOT merge with or diff against any existing OpenAPI file. Every run is a clean new file.
- Do NOT omit `description` and `example` on schema properties.

## Pre-Delivery Checklist

- [ ] Exactly one interface in `paths` — one path, one method.
- [ ] `openapi` is exactly `3.1.0`.
- [ ] JSON parses successfully.
- [ ] Every `$ref` target exists in `components.schemas`.
- [ ] Gin `:param` converted to `{param}` with required path parameter.
- [ ] Operation has `Authorization` header parameter.
- [ ] `POST`/`PUT`/`PATCH` body uses `$ref` to named request schema.
- [ ] Every schema property has `type`, `description`, `example`.
- [ ] `required` arrays based on code evidence only.
- [ ] Response envelope from code, applied consistently.
- [ ] No merged-in old data — everything is from current code only.
