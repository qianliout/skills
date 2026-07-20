# Go Gin OpenAPI JSON

只为用户明确指定的接口生成文档。以当前 Go 代码为事实来源，不因扫描到相邻路由就把它们加入最终文档。

## Rule Priority

- 现有路由、handler、DTO、校验和 response helper 决定真实 HTTP 契约。
- `references/api-layer.md` 和 `references/api-layer-conventions.md` 用于理解项目默认约定；现有代码有明确证据时，以代码为准。
- 解析现有 `PATCH` 或 path 参数只是记录真实接口，不代表允许新接口绕过 API 层设计约定。
- 无法从代码确认的路由、响应模型或 envelope 不得猜测。

## Workflow

1. 确认目标接口范围、Go 项目根目录和输出路径。
1. 目标范围缺失或存在多个合理匹配时，要求用户提供 route、method + path、handler、route group 或 module 中最小可用的 selector。
1. 加载 `references/gin-openapi-json-conventions.md`、`references/api-layer.md` 和 `references/api-layer-conventions.md`。
1. 用户要求 Apifox 兼容、示例对齐或项目没有专用模板时，读取 `assets/openapi.json`。
1. 优先用项目代码图工具定位选定路由、handler、model 和 response helper；图工具不足时再使用 `rg`、Go AST 和直接文件读取。
1. 只追踪选定接口需要的参数来源、DTO、校验、序列化、service 返回类型和响应 envelope。
1. 只为选定 operation 构建 `paths` 和被引用的 `components.schemas`。
1. 生成 OpenAPI `3.1.0` JSON，使用两空格缩进写入一个最终文件。
1. 验证 JSON 可解析、所有 `$ref` 有目标、path 参数完整、请求和响应结构与代码一致。
1. 返回输出路径、operation 数量、schema 数量、验证结果和仍未解析的事实。

## Reference Loading

生成、刷新、评审或解释 Gin OpenAPI、Apifox、`openapi.json` 和接口 schema 时，必须加载 `references/gin-openapi-json-conventions.md`、`references/api-layer.md` 和 `references/api-layer-conventions.md`。

`assets/openapi.json` 是输出结构示例，不是需要完整加载并照搬的规范。只在生成任务需要示例对齐或缺少项目模板时读取。

## Pre-Delivery Checklist

- [ ] 目标接口范围明确，最终 `paths` 不包含未选中的路由。
- [ ] 真实代码与默认 API 约定不一致时，文档忠实反映代码。
- [ ] 输出只有 JSON，`openapi` 为 `3.1.0`，并且可成功解析。
- [ ] 请求参数、body、响应 envelope 和 schema 均有代码依据。
- [ ] 所有 `$ref`、path 参数和 request body schema 完整有效。
- [ ] 最终只写入一个完整文档，并报告验证结果。
