---
name: go-gin-openapi-json
description: "用于用户明确指定单个 Gin 接口并要求生成或刷新 OpenAPI JSON 时。"
runAs: subagent
argument-hint: "<method+path|handler-name> [--output <filepath>]"
---

# Go Gin OpenAPI JSON

铁律：每次只能生成一个接口。扫描到相邻路由、同一注册范围中的其它接口或同一 handler 的其它方法，全部忽略。

每次生成都必须按当前代码全量重建。禁止合并旧 JSON，禁止保留代码已删除的字段、路由或 schema。

## 执行清单

复制此清单并逐项完成：

- [ ] Step 0：运行预检脚本，失败立即停止。
- [ ] Step 1：确认唯一目标接口。
- [ ] Step 2：读取规则与模板。
- [ ] Step 3：定位路由和 handler。
- [ ] Step 4：分析 HTTP 契约。
- [ ] Step 5：建立该 operation 专用 schema。
- [ ] Step 6：使用脚本确定输出路径。
- [ ] Step 7：组合全新的 OpenAPI JSON。
- [ ] Step 8：写入并校验。
- [ ] Step 9：报告结果。

### Step 0：运行预检脚本

在分析代码前必须运行：

```bash
bash scripts/generate.sh <SELECTOR> [--output <path>]
```

脚本会校验 selector、向上查找 `go.mod`、确定默认输出路径、创建输出目录，并输出 `{selector,output,project_root}`。脚本非零退出时必须停止并报告错误。

### Step 1：确认唯一目标接口

只接受唯一命中的 `METHOD /path` 或 handler 名，例如 `PUT /api/v1/users/:id`、`UserAPI.CreateUser`。prefix、包名和其它无法唯一命中的 selector 必须拒绝；列出匹配项并要求用户精确指定一个接口。

### Step 2：读取规则与模板

必须读取 `references/gin-openapi-json.md`。必须将 `assets/openapi.json` 作为输出形状模板，只能替换为目标代码证明的事实。

当需要对齐 HTTP API 形态时，必须加载 `go-api-layer`。本目录禁止保留其 reference 副本。

### Step 3 至 Step 7：从代码重建

定位选定路由，解析完整 path，将 Gin `:param` 转为 OpenAPI `{param}`。只追踪该接口的绑定参数、DTO、校验、响应 helper、service 返回类型与 envelope。动态注册无法静态确定时停止，不得猜测。

`paths` 只能有一个 path 和一个 method。请求 body 必须引用命名 schema；所有 `$ref` 必须指向 `components.schemas` 中的目标。输出必须是两空格缩进的 OpenAPI `3.1.0` JSON。

### Step 8：写入并校验

写入 Step 0 返回的 `output` 路径。必须校验 JSON 可解析、每个 `$ref` 有目标、每个 `{param}` 都有必填 path 参数，且请求和响应结构与当前代码一致。未完成全部校验，禁止宣称成功。

### Step 9：报告结果

报告输出路径、`METHOD path`、operation 数量 `1`、schema 数量和校验结果。无法确认的事实必须明确列出。

## 交付前检查

- [ ] `paths` 只有一个 path 和一个 method。
- [ ] `openapi` 严格为 `3.1.0`。
- [ ] JSON 已成功解析。
- [ ] 每个 `$ref` 都有 `components.schemas` 目标。
- [ ] 每个 Gin path 参数都已转换并声明为必填。
- [ ] 未带入旧 JSON 的字段、路由或 schema。
