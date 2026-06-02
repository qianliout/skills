---
name: go-service-layer
description: "Go service 层业务编排专家。Use when writing, refactoring, or reviewing service interfaces/structs, dependency injection, constructors, DAL/DAO calls, param.Check, DTO conversion, aggregation, helpers, logging, error wrapping, cache reads, list/detail/create/update/delete services."
---

# Go Service Layer

service 层负责业务编排、参数校验入口、必要模型转换、结果聚合、日志和错误包装；不直接访问 DB/GORM/SQL，不把 DAL 或 model 的职责搬进 service。

## Workflow

1. 识别 service 边界：确认公开方法、param、response、依赖 DAL/service/cache/logger 和方法类型。
2. 加载 `references/go-service-conventions.md`，按项目约定处理 interface、struct、constructor 和错误语义。
3. 定义结构：项目使用 interface 时同步更新 interface 和实现；按依赖顺序声明字段和构造函数参数，常见顺序为 DAL/repository、其他 service、cache、外部 client、配置/时钟/ID 生成器、logger；长期依赖通过构造函数或明确字段注入，不能在业务方法内临时创建，也不能因为依赖为 nil 就跳过业务分支；同一个 service struct 的方法统一使用指针接收者，receiver 统一命名为 `s`。
4. 实现公开方法：涉及 I/O 的公开方法第一个参数使用 `ctx context.Context`；公开接口和方法名保持资源/动作级别，不新增 `SearchXxxForUser`、`UpdateXxxForProject` 这类按调用场景拆分的方法；带领域方法的 param 使用指针类型，入口按 `param = param.Serialize()`、`param.Check()` 顺序处理。
5. 编排依赖：调用 DAL/service/cache；slice/map 作为返回值时先实例化，所有返回路径都不能返回 nil slice/map；错误按项目约定记录和包装；领域规整逻辑优先调用拥有字段的 model/param/result 的公有 `Serialize()`。
6. 平衡 helper 粒度：复杂详情或跨资源聚合按数据域拆成私有 helper；批量取数先收集 ID、去重、批量查、map 回填；不要按一两行操作拆成一串薄 helper，主流程应保留 3-7 个清晰业务步骤。
7. 交付：缺少 DAL/model/param 方法时列出假设，不编造外部类型。

## Reference Loading

生成、重构或评审 service 层代码时，必须加载 `references/go-service-conventions.md`。

## Pre-Delivery Checklist

- [ ] 已同时符合 `go-code-style`、`go-logging`、`go-model-hierarchy`、`go-query-dal` 中当前任务涉及的规则。
- [ ] Service interface/struct/constructor 符合项目约定；依赖顺序清晰，由构造注入，业务方法内没有临时创建或 nil 跳过逻辑。
- [ ] 实现方法使用指针接收者，receiver 统一为 `s`；公开方法第一个参数是 `ctx context.Context`。
- [ ] 公开接口保持资源/动作级别；没有 `SearchXxxForUser`、`UpdateXxxForProject` 等场景化窄接口。
- [ ] Param 入参按需要执行 `param = param.Serialize()`、`param.Check()`；service 不重复清洗、校验或派生字段。
- [ ] Service 不直接访问 DB/GORM/SQL，不临时定义 param/response/model struct。
- [ ] 列表/聚合返回值已初始化为空集合；复杂聚合按数据域拆分且无循环逐条查询。
- [ ] 错误日志和包装遵循 `go-logging` 与项目约定。
