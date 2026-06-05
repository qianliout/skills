---
name: go
description: "Go 代码整体入口和规则路由。Use whenever writing, refactoring, reviewing, debugging, testing, or explaining Go code, Go packages, Gin handlers, service/DAL/model layers, GORM queries, logging, comments, or repository-wide Go conventions. Start here, then load only the specific Go layer or feature skills actually involved."
---

# Go

先建立 Go 任务边界，再按需加载子 skill。不要因为任务是 Go 就一次性加载全部 Go skills。

## Workflow

1. 识别任务类型：实现、重构、评审、排查 bug、补测试、解释代码，或调整项目约定。
2. 读取就近上下文：相邻文件、接口、model/param/response、构造函数、调用方、测试和已有同层实现。
3. 默认加载 `go-code-style` 作为 Go 修改和评审的基础规则。
4. 只加载实际触及的专门 skill；跨层任务按职责组合，不把一个层的规则搬到另一层。
5. 修改 Go 文件后运行 `goimport`；能定位包或测试时运行相关 `go test`，不能运行则说明原因。

## Skill Routing

- `go-api-layer`：Gin/HTTP handler、request binding、query/body/header 参数、response DTO、分页响应、service 调用、JSONOK/JSONError。
- `go-service-layer`：service interface/struct、构造注入、业务编排、param.Check、DTO 转换、聚合、cache、错误包装、service 方法。
- `go-query-dal`：store/DAL/DAO、GORM 查询、Create/Search/Update/Delete、Count + Find、context timeout、AddFilter、ToUpdater、PostgreSQL 兼容查询。
- `go-model-hierarchy`：domain/GORM model、param/response/view/cache/stat struct、JSON/GORM tag、TableName、Check、Serialize/Deserialize、ToUpdater、UniqueID、派生字段、常量归属。
- `go-logging`：logger 初始化、module/subModule、LogStr、错误日志、panic recover、敏感信息、大 payload、重复日志、日志放置边界。
- `go-comment-style`：Go 注释、doc comment、字段/函数/struct/package 注释，或判断注释是否该保留。

## Cross-Layer Boundaries

- API 只做 HTTP 适配；复杂业务、聚合和响应组装放到 service。
- Service 只做业务编排和依赖调用；不直接访问 DB/GORM/SQL。
- DAL 只做持久化访问；不承载业务规则。
- Model 管理字段生命周期、参数规整、校验、序列化、反序列化和更新字段选择。
- 日志由拥有业务上下文的 API/service/goroutine 等边界记录；DAL/model 默认不新增日志。
- 代码注释使用中文，日志内容使用英文。
- 项目内数值类型默认使用 `int64`；只有外部协议、第三方库、明确性能/存储边界或既有兼容约束需要时才用其它数值类型。

## Pre-Delivery Checklist

- [ ] 只加载了任务需要的 Go skills，没有无差别加载全部。
- [ ] 代码符合 `go-code-style` 和已触发的专门 skill。
- [ ] API/service/DAL/model/logging/comment 职责没有互相侵入。
- [ ] 数值字段、参数和返回值默认使用 `int64`；例外有明确理由。
- [ ] 修改 Go 文件后已运行 `goimport`。
- [ ] 能运行测试时已运行相关 `go test`；不能运行时已说明原因。
