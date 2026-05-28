---
name: go-service-layer
description: "Go service 层业务编排专家。Use when writing, refactoring, or reviewing service interfaces/structs, dependency injection, constructors, DAL/DAO calls, param.Check, DTO conversion, aggregation, helpers, logging, error wrapping, cache reads, list/detail/create/update/delete services."
---

# Go Service Layer

service 层负责业务编排、参数校验入口、必要模型转换、结果聚合、日志和错误包装；不直接访问 DB/GORM/SQL，不把 DAL 或 model 的职责搬进 service。

## Workflow

1. 识别 service 边界：确认公开方法、param、response、依赖 DAL/service/cache/logger 和方法类型。
2. 加载 `references/go-service-conventions.md`，按项目约定处理 interface、struct、constructor 和错误语义。
3. 定义结构：项目使用 interface 时同步更新 interface 和实现；按依赖顺序声明字段和构造函数参数，常见顺序为 DAL/repository、其他 service、cache、外部 client、配置/时钟/ID 生成器、logger；长期依赖通过构造函数或明确字段注入，不能在业务方法内临时创建；同一个 service struct 的方法统一使用指针接收者，receiver 统一命名为 `s`。
4. 实现公开方法：涉及 I/O 的公开方法第一个参数使用 `ctx context.Context`；带领域方法的 param 使用指针类型；入口按 `param = param.Serialize()`、`param.Check()` 顺序处理。
5. 编排依赖：调用 DAL/service/cache；slice/map 作为返回值时先实例化，所有返回路径都不能返回 nil slice/map；错误按项目约定记录和包装；领域规整逻辑优先调用拥有字段的 model/param/result 的公有 `Serialize()`。
6. 平衡 helper 粒度：复杂详情或跨资源聚合按数据域拆成私有 helper；批量取数先收集 ID、去重、批量查、map 回填；不要按一两行操作拆成一串薄 helper，主流程应保留 3-7 个清晰业务步骤。
7. 交付：缺少 DAL/model/param 方法时列出假设，不编造外部类型。

## Reference Loading

生成、重构或评审 service 层代码时，必须加载 `references/go-service-conventions.md`。

## Pre-Delivery Checklist

- [ ] 新写 service 代码同时符合 `go-code-style`、`go-logging`、`go-model-hierarchy`、`go-query-dal` 中当前任务涉及的规则。
- [ ] 符合项目 service interface/struct/constructor 约定。
- [ ] service 依赖关系清晰，字段和构造函数参数按 DAL/repository、其他 service、cache、外部 client、配置/时钟/ID 生成器、logger 的常见顺序组织。
- [ ] DAL/service/cache/client/logger 等长期依赖通过构造函数或明确字段注入，没有在业务方法内临时 new。
- [ ] 同一个 service struct 的所有实现方法都使用指针接收者，receiver 统一命名为 `s`，例如 `func (s *XxxSrv) SearchXxx(...)`，没有值接收者或其它 receiver 名。
- [ ] 涉及 I/O 的公开 service 方法第一个参数是 `ctx context.Context`。
- [ ] 方法体没有重复的 `s == nil` 或依赖 nil 防御判断。
- [ ] 有 param 领域方法时，param 入参是指针类型，入口按 `param = param.Serialize()`、`param.Check()` 顺序处理；无重复清洗、ID 校验或派生字段计算。
- [ ] service 内没有散落 trim/default/derive/fill 逻辑或以 struct 为首参的规整 helper；这类逻辑已挂到拥有字段的 model/param/result 的公有 `Serialize()` 上，没有 `Normalize()`、`FillDefault()` 或小写规整方法。
- [ ] service 作为外部调用方显式组合领域方法；不依赖 `Check()`、`ToUpdater()`、`Same()` 内部代调 `Serialize()` / `Deserialize()`。
- [ ] service 没有直接 DB/GORM/SQL 操作。
- [ ] 没有在 service 文件中临时定义 param/response/model struct。
- [ ] 所有常量统一放到项目定义的 `consts` 目录下，没有散落在 service 或函数体中。
- [ ] 如确需调整 model/param/response struct，其 `json` tag 没有 `omitempty`。
- [ ] 新功能在 service 入参、出参和层间传递中统一使用毫秒级 `int64` 时间戳；已有功能不被无意迁移。
- [ ] 没有新增不必要的基础包装类型，如 `type Kind string`；service 入参、出参和局部状态优先使用基础类型或明确 struct。
- [ ] 列表/聚合的 slice/map 返回值已实例化，成功和错误路径都返回空集合而不是 nil。
- [ ] 复杂聚合已按数据域拆分，或有明确理由保持在一个方法内。
- [ ] service 方法没有极端冗长，也没有拆成需要连续跳转才能理解的薄 helper 链。
- [ ] 可批量获取的数据没有在循环里逐条查询。
- [ ] 错误日志和包装遵循 `go-logging` 与项目约定。
- [ ] 没有新增 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
