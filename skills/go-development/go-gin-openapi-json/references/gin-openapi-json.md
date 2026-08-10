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

## 单 operation 硬规则

- 铁律：输出只含目标 Gin 路由对应的一个 operation。`paths` 只能有一个 path，且该 path 只能有一个 HTTP method。
- 项目使用 `Authorization` 鉴权时，目标 operation 必须声明唯一的 `Authorization` header 参数：`in: header`、`schema.type: string`，并提供与项目协议一致的示例；`required` 必须与鉴权中间件或 handler 的代码一致。
- 每个已输出的参数、request schema 属性和 response schema 属性必须同时有非空 `description` 与 `example`。描述按字段注释、类型注释、handler 注释、校验 tag、枚举、字段语义的顺序取证；示例按显式 example/default tag、枚举、测试夹具、字段语义的顺序取证。代码没有文字说明时，必须从代码语义写出简短描述与保守示例，不得留空。
- Go 类型映射必须严格执行：`string` 为 `string`；`bool` 为 `boolean`；有符号和无符号整数为 `integer`；`float32` 与 `float64` 为 `number`；slice 与 array 为 `array`；map 为 `object`；struct 为 `object` 或 `$ref`；`time.Time` 为 `string` 且 `format: date-time`；项目毫秒时间戳为 `integer` 且 `format: int64`；指针使用底层类型，必填性与可空性另行由代码决定。
- `required` 只能由代码证据导出：`binding:"required"`、`validate:"required"`、项目 required 校验 tag、拒绝空值的 `Check()` 逻辑、项目已确立的非指针且非 `omitempty` 约定，以及 path 参数。证据不足时不得加入 `required`。
- 成功状态码必须来自 handler 或 response helper；只有代码没有更明确状态码时才能使用 `200`。项目存在固定 response envelope 时，response 必须使用该 envelope 包装业务数据；helper 暴露的列表元数据必须保留。错误 response 只允许记录代码已暴露的稳定错误形状。
- 产物必须可被 Apifox 直接导入：JSON 可解析、`openapi` 为 `3.1.0`、每个 `$ref` 都有 `components.schemas` 目标、每个 `{param}` 都有同名必填 path 参数。任一条件不满足，禁止交付。

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
- [ ] 项目使用 `Authorization` 鉴权时，header 参数已声明。
- [ ] 每个已输出字段均有 `description` 与 `example`。
- [ ] Go 类型、`required`、状态码与 response envelope 均来自代码。
- [ ] JSON 可被 Apifox 直接导入。
- [ ] 输出完全来自当前代码。
- [ ] 已报告输出路径与校验结果。
