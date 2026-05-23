---
name: go-service-layer
description: "Go service 层业务编排专家。Use when writing, refactoring, or reviewing service interfaces/structs, dependency injection, constructors, DAL/DAO calls, param.Check, DTO conversion, aggregation, helpers, logging, error wrapping, cache reads, list/detail/create/update/delete services."
---

# Go Service Layer

service 层负责业务编排、参数校验入口、必要模型转换、结果聚合、日志和错误包装；不直接访问 DB/GORM/SQL，不把 DAL 或 model 的职责搬进 service。

## Workflow

1. 识别 service 边界：确认公开方法、param、response、依赖 DAL/service/cache/logger 和方法类型。
2. 加载 `references/go-service-conventions.md`，按项目约定处理 interface、struct、constructor 和错误语义。
3. 定义结构：项目使用 interface 时同步更新 interface 和实现；依赖通过构造函数注入；service 方法统一使用指针接收者。
4. 实现公开方法：涉及 I/O 的公开方法第一个参数使用 `ctx context.Context`；入口调用 `param.Check()`。
5. 编排依赖：调用 DAL/service/cache；slice/map 作为返回值时先实例化，所有返回路径都不能返回 nil slice/map；错误按项目约定记录和包装。
6. 拆分 helper：复杂详情或跨资源聚合按数据域拆成私有 helper；批量取数先收集 ID、去重、批量查、map 回填。
7. 交付：缺少 DAL/model/param 方法时列出假设，不编造外部类型。

## Reference Loading

生成、重构或评审 service 层代码时，必须加载 `references/go-service-conventions.md`。

## Pre-Delivery Checklist

- [ ] 符合项目 service interface/struct/constructor 约定。
- [ ] service 实现方法都使用指针接收者，例如 `func (s *XxxSrv) SearchXxx(...)`，没有值接收者。
- [ ] 涉及 I/O 的公开 service 方法第一个参数是 `ctx context.Context`。
- [ ] 方法体没有重复的 `s == nil` 或依赖 nil 防御判断。
- [ ] 有 param 校验方法时入口调用 `param.Check()`；无重复清洗、ID 校验或派生字段计算。
- [ ] service 没有直接 DB/GORM/SQL 操作。
- [ ] 没有在 service 文件中临时定义 param/response/model struct。
- [ ] 列表/聚合的 slice/map 返回值已实例化，成功和错误路径都返回空集合而不是 nil。
- [ ] 复杂聚合已按数据域拆分，或有明确理由保持在一个方法内。
- [ ] 可批量获取的数据没有在循环里逐条查询。
- [ ] 错误日志和包装遵循 `go-logging` 与项目约定。
- [ ] 没有新增 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
