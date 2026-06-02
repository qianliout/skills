---
name: go
description: "Go 代码整体入口和规则路由。Use whenever writing, refactoring, reviewing, debugging, or explaining Go code, Go tests, Go packages, Gin/GORM/service/DAL/model code, or repository-wide Go conventions. Start with shared Go workflow, then load only the specific Go layer or feature skills that are actually involved."
---

# Go

这是 Go 代码任务的总入口。先用它建立通用工作流和 skill 选择，再按实际触及的层或功能加载专门 skill；不要一开始加载全部 Go skills。

## Workflow

1. 识别任务类型：写代码、改代码、重构、评审、排查 bug、补测试、解释现有实现，或调整项目约定。
2. 读取当前仓库上下文：优先看相邻文件、同层已有实现、接口定义、model/param/response、构造函数、测试和调用方。
3. 默认使用 `go-code-style` 作为所有 Go 代码修改和评审的基础规则。
4. 按任务实际涉及内容加载专门 skill；只加载需要的，不因为是 Go 任务就加载全部。
5. 修改 Go 文件后运行 `goimport`；能定位到相关包或测试时运行相关 `go test`。如果测试不可运行，说明原因。

## Skill Routing

- 触及 Gin/HTTP handler、request binding、query/body 参数、response DTO、分页响应、service 调用或 JSONOK/JSONError 时，使用 `go-api-layer`。
- 触及 service interface/struct、构造函数依赖注入、业务编排、param.Check、DTO 转换、聚合、cache、错误包装或 service 方法时，使用 `go-service-layer`。
- 触及 store/DAL/DAO、GORM 查询、Create/Search/Update/Delete、分页 Count + Find、context timeout、AddFilter、ToUpdater 或 PostgreSQL 兼容查询时，使用 `go-query-dal`。
- 触及 domain model、GORM model、param/response/view/cache/stat struct、JSON/GORM tag、TableName、Check、Serialize/Deserialize、ToUpdater、UniqueID、派生字段或常量归属时，使用 `go-model-hierarchy`。
- 触及 logger 初始化、module/subModule、LogStr、错误日志、panic recover、敏感信息、大 payload、重复日志或日志放置边界时，使用 `go-logging`。
- 触及 Go 注释、doc comment、字段/函数/struct/package 注释，或判断注释是否需要保留时，使用 `go-comment-style`。

## Cross-Layer Rules

- API 只做 HTTP 适配；复杂业务、聚合和响应组装放到 service。
- Service 只做业务编排和依赖调用；不直接访问 DB/GORM/SQL。
- DAL 只做持久化访问；不承载业务规则。
- Model 层管理字段生命周期、参数规整、校验、序列化、反序列化和更新字段选择。
- 日志由拥有业务上下文的 API/service/goroutine 等边界记录；DAL/model 默认不新增日志。
- 代码注释使用中文，日志内容使用英文。
- 项目内数值类型默认统一使用 `int64`；除非外部协议、第三方库签名、明确性能/存储边界或既有兼容约束确有必要，不新增 `int`、`int32`、`uint`、`uint64` 等其它数值类型，也不要仅为兼容旧实现保留非 `int64` 数值类型。

## Pre-Delivery Checklist

- [ ] 已根据任务只加载相关 Go skills，没有无差别加载全部。
- [ ] 代码符合 `go-code-style` 和已触发的专门 skill。
- [ ] 行为边界清楚：API/service/DAL/model/logging/comment 职责没有互相侵入。
- [ ] 数值字段、参数和返回值已默认统一为 `int64`；使用其它数值类型时有明确必要性。
- [ ] 修改 Go 文件后已运行 `goimport`。
- [ ] 能运行测试时已运行相关 `go test`；不能运行时已说明原因。
