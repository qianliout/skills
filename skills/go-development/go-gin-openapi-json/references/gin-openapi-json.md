# Gin 单接口 OpenAPI JSON 规则

每次执行只能产出一个 operation。当前 Go 代码是唯一事实来源；扫描发现的其它路由不得写入输出。

## 强制范围

- selector 必须唯一命中一个 `METHOD path` 或一个 handler。
- selector 缺失、含糊或命中不止一个接口时，立即停止并要求精确输入。
- 禁止把相邻路由、同一注册范围中的接口或同一 handler 的其它方法写入 `paths`。
- 每次必须从当前代码全量重建，禁止合并、diff 或继承旧 JSON。
- 已从代码删除的字段、路由和 schema 必须从输出消失。

## 执行顺序

1. 先运行 `bash scripts/generate.sh <SELECTOR> [--output <path>]`。脚本失败立即停止。
1. 读取目标路由、handler、参数 DTO、校验、response helper 和关联类型。
1. 将 Gin `:param` 转为 `{param}`；无法静态解析注册关系时停止，不得编造。
1. 只为该 operation 创建参数、request body、responses 和 `components.schemas`。
1. 使用 `assets/openapi.json` 的顶层结构与对象形状；全部具体值必须来自目标代码。
1. 写入脚本返回的 `output`，使用两空格缩进。
1. 解析 JSON，检查 `$ref` 和 path 参数后再报告成功。

## HTTP 契约

- 代码的路由、handler、DTO、校验和 response helper 决定最终契约。
- 需要对齐 API 层默认形态时加载 `go-api-layer`；代码有明确证据时始终以代码为准。
- `POST`、`PUT`、`PATCH` 的 body 使用命名 schema 和 `$ref`，不得在 operation 内联大型对象。
- 每个 `{param}` 必须有同名、`required: true` 的 path 参数。
- schema 依据 Go `json` tag、验证 tag 和代码检查构建；`json:"-"` 不得输出。
- 无法确认的字段、状态码、envelope 或注册关系必须报告为缺失事实，不得猜测。

## JSON 形状

- `openapi` 固定为 `3.1.0`。
- `paths` 只能包含一个 path，且该 path 只能包含一个 HTTP method。
- `components.schemas` 必须包含每个 `$ref` 的目标。
- 顶层保留 `info`、`tags`、`paths`、`components`、`servers` 和 `security`。
- 输出仅为 JSON，不生成 YAML、Swagger UI、Markdown 文档或客户端 SDK。

## 交付检查

- [ ] selector 唯一命中。
- [ ] 预检脚本已成功执行。
- [ ] `paths` 只有一个 operation。
- [ ] JSON 可解析。
- [ ] 每个 `$ref` 有效。
- [ ] 每个 path 参数完整。
- [ ] 输出完全来自当前代码。
- [ ] 已报告输出路径与校验结果。
