---
name: go-service-layer
description: "通用 Go service/service layer 业务编排层专家，生成、重构、评审服务层代码。Use when user asks 写 service、写业务服务层、service interface、service struct、依赖注入、构造函数、调用 DAL/DAO、参数校验、param.Check、DTO 转换、聚合响应、private helper、日志、错误包装、缓存读取、列表查询、详情聚合、Create/Update/Delete service。Actions: design, create, refactor, review, implement service layer."
---

# Go Service Layer

service 层负责业务编排、参数校验入口、必要模型转换、结果聚合、日志和错误包装；不直接访问 DB/GORM/SQL，不把 DAL 或 model 的职责搬进 service。

## Workflow

- [ ] Step 1: 识别 service 边界
  - 确认公开方法、param、response、依赖 DAL/service/cache/logger。
  - 判断方法类型：列表、详情聚合、创建、更新、删除、缓存、外部调用、异步维护。
  - 加载 `references/go-service-conventions.md`，按项目约定落地。
- [ ] Step 2: 定义结构
  - 项目使用 interface 时同步更新 interface 和实现 struct。
  - 涉及 DAL/cache/外部 I/O 的公开方法，第一个参数使用 `ctx context.Context`。
  - 依赖通过构造函数注入；需要日志/cache 状态时在构造函数初始化。
  - 依赖有效性通常由构造/初始化保证，方法体不重复写 nil 防御判断。
- [ ] Step 3: 实现公开方法
  - param 有 `Check()` 时在入口调用；清洗、默认值、派生查询字段放 param 层。
  - 成功空结果返回空切片/map。
  - 只有在 API param 与 DAL param 不一致、映射复杂或复用价值明确时才抽转换方法。
  - 调用 DAL/service/cache，错误按项目约定记录上下文并返回上层语义错误。
- [ ] Step 4: 拆分 helper
  - 复杂详情或跨资源聚合按数据域拆成私有 helper。
  - helper 只补充一个清晰数据域，错误向上返回；是否记录日志遵循日志规范。
  - 可批量获取的关联数据先收集 ID、去重、批量查，再用 map 回填。
- [ ] Step 5: 交付
  - 缺少 DAL/model/param 方法时列出假设，不编造外部类型。
  - 运行 Pre-Delivery Checklist。

## Reference Loading

生成、重构或评审 service 层代码时，必须加载 `references/go-service-conventions.md`。

## Pre-Delivery Checklist

- [ ] 符合项目 service interface/struct/constructor 约定。
- [ ] 涉及 I/O 的公开 service 方法第一个参数是 `ctx context.Context`。
- [ ] 方法体没有重复的 `s == nil` 或依赖 nil 防御判断。
- [ ] 有 param 校验方法时入口调用 `param.Check()`；无重复清洗、ID 校验或派生字段计算。
- [ ] service 没有直接 DB/GORM/SQL 操作。
- [ ] 没有在 service 文件中临时定义 param/response/model struct。
- [ ] 列表/聚合成功空结果返回空集合。
- [ ] 复杂聚合已按数据域拆分，或有明确理由保持在一个方法内。
- [ ] 可批量获取的数据没有在循环里逐条查询。
- [ ] 错误日志和包装遵循 `go-logging` 与项目约定。
- [ ] 没有新增 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
