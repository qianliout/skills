---
name: go
description: "Go 代码唯一入口和按需规则路由。Use whenever writing, refactoring, reviewing, debugging, testing, or explaining Go code, Go packages, Gin handlers, service/DAL/model layers, GORM queries, OpenAPI JSON, logging, comments, or repository-wide Go conventions. Always start here and load only the reference files required by the task."
---

# Go

把这个 Skill 作为全部 Go 任务的唯一入口。先识别任务涉及的层和领域，再读取对应 reference；不要一次性读取全部 Go reference。

## Workflow

1. 识别任务类型和范围：实现、重构、评审、排查、测试、解释或生成接口文档。
1. 读取就近代码：相邻文件、接口、model/param/response、构造函数、调用方、测试和同层实现。
1. 根据下方路由读取当前任务需要的 reference。跨层任务只组合实际修改或分析到的层。
1. 遵循项目现有约定；除非用户明确要求，不改变无关业务行为。
1. 修改 Go 文件后运行 `goimport`；能定位包或测试时运行最小范围的 `go test`，不能运行时说明原因。

## Reference Routing

- 新增或重构普通 Go 代码、审查可维护性、错误处理、命名和控制流：读取 `references/code-style.md` 和 `references/code-style-conventions.md`。
- Gin/HTTP handler、请求绑定、响应 DTO、分页和 response helper：读取 `references/api-layer.md` 和 `references/api-layer-conventions.md`。
- Service 接口、构造注入、业务编排、聚合、缓存和错误包装：读取 `references/service-layer.md` 和 `references/service-layer-conventions.md`。
- Store、DAL、DAO、GORM、CRUD、分页和数据库查询：读取 `references/query-dal.md` 和 `references/query-dal-conventions.md`。
- Domain/GORM model、param、response、字段生命周期和序列化：读取 `references/model-hierarchy.md` 和 `references/model-hierarchy-conventions.md`。
- Logger、错误日志、panic recover、敏感信息和日志边界：读取 `references/logging.md` 和 `references/logging-conventions.md`。
- Go 注释、doc comment、字段或函数注释：读取 `references/comment-style.md` 和 `references/comment-style-conventions.md`。
- `_test.go`、testify、mock、table-driven test 和覆盖错误路径：读取 `references/test-writer.md` 和 `references/test-writer-conventions.md`；测试对象属于特定层时再加载该层 reference。
- Gin OpenAPI、Apifox、`openapi.json` 和接口 schema：读取 `references/gin-openapi-json.md`、`references/gin-openapi-json-conventions.md`、`references/api-layer.md` 和 `references/api-layer-conventions.md`；需要模板时使用 `assets/openapi.json`。

## Routing Rules

- 不默认读取任何 reference；只在任务匹配时读取。
- 不因调用链存在某层就加载该层，只在任务实际修改、评审或解释该层时加载。
- 不把 reference 当作独立 Skill，也不搜索已移除的 `go-*` Skill 名称。
- 多层任务按职责组合 reference，不把一个层的规则搬到另一层。

## Layer Boundaries

- API 只做 HTTP 适配；复杂业务和聚合放到 Service。
- Service 只做业务编排和依赖调用；不直接访问 DB、GORM 或 SQL。
- DAL 只做持久化访问；不承载业务规则。
- Model 管理字段生命周期、校验、序列化、反序列化和更新字段选择。
- 日志由拥有业务上下文的 API、Service 或 goroutine 边界记录；DAL 和 Model 默认不新增日志。
- 代码注释使用中文，日志内容使用英文。

## Pre-Delivery Checklist

- 只读取了任务需要的 Go reference。
- API、Service、DAL、Model、Logging 和 Comment 职责没有互相侵入。
- 修改 Go 文件后已运行 `goimport`。
- 能运行测试时已运行相关 `go test`；不能运行时已说明原因。
