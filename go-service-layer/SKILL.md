---
name: go-service-layer
description: "通用 Go service/service layer 业务编排层专家，生成、重构、评审服务层代码。Use when user asks 写 service、写业务服务层、service interface、service struct、依赖注入、构造函数、调用 DAL/DAO、参数校验、param.Check、DTO 转换、聚合响应、private helper、日志、错误包装、缓存读取、列表查询、详情聚合、Create/Update/Delete service。Actions: design, create, refactor, review, implement service layer."
---

# Go Service Layer

核心约束：service 层负责业务编排、参数校验入口、模型转换、结果聚合、日志和错误包装；不直接拼 SQL、不直接访问数据库，不把 DAL 的职责搬到 service。
Service 依赖有效性通常由构造/初始化阶段保证；除非项目已有明确约定，方法体内不写 `s == nil`、`s.xxxDal == nil` 这类防御判断。

## Workflow

- [ ] Step 1: 识别 service 边界 ⚠️ REQUIRED
  - [ ] 确认公开服务方法、入参 param、返回 DTO/Response、依赖 DAL/service/cache/log等。
  - [ ] 判断方法类型：列表查询、详情聚合、更新动作、缓存读取、跨资源关联查询、异步维护。
  - [ ] 确认 param 和 response 类型属于 model/API 层，不在 service 文件中临时定义。
- [ ] Step 2: 定义结构
  - [ ] 如果项目使用 service interface，先写 `XxxService interface`，再写 `XxxSrv` 或既有项目约定的实现 struct。
  - [ ] 涉及 DAL/cache/外部 I/O 的公开方法第一个参数使用 `ctx context.Context`。
  - [ ] service struct 优先只持有依赖：DAL、其他service、cache、logger、轻量内存状态等。
  - [ ] 构造函数注入必需依赖；如方法需要日志/cache 状态，在构造函数中初始化。
- [ ] Step 3: 实现公开方法
  - [ ] 有 param 且 param 提供 `Check()` 时，在入口调用；参数清洗、格式校验、默认值、派生查询字段放在 param 层。
  - [ ] 返回列表/聚合结果时初始化切片/map，避免成功路径返回 nil slice。
  - [ ] 需要转换时再将 API param 转为 DAL param；简单透传可直接使用原 param。
  - [ ] 调用 DAL/service 获取数据，出错时按项目约定记录日志并包装成上层语义错误。
  - [ ] 组装 response，只在 service 层做跨 DAL 聚合和 DTO 转换。
- [ ] Step 4: 拆分私有 helper
  - [ ] 复杂详情聚合优先拆成 `addXxxData(ctx, param, ans)` 这类私有方法。
  - [ ] helper 只补充一个清晰数据域，错误向上返回。
  - [ ] 多个 helper 的错误可聚合；聚合错误前逐个记录必要上下文日志。
- [ ] Step 5: 交付检查
  - [ ] 运行 Pre-Delivery Checklist。
  - [ ] 如果缺少 DAL/model/param 方法，列出假设，不编造外部类型。

## Reference Loading

需要生成或评审 Go service 层代码时，加载 `references/go-service-conventions.md`。

## Common Patterns

接口和实现结构：

```go
type XxxService interface {
    SearchXxx(ctx context.Context, param model.SearchXxxParam) ([]*model.XxxResponse, int64, error)
    UpdateXxx(ctx context.Context, param model.UpdateXxxParam) error
}

type XxxSrv struct {
    primaryDal store.PrimaryDal
    relatedDal store.RelatedDal
    log        *utils.LogEvent
}
```

构造函数：

```go
func NewXxxSrv(primaryDal store.PrimaryDal, relatedDal store.RelatedDal) *XxxSrv {
    return &XxxSrv{
        primaryDal: primaryDal,
        relatedDal:  relatedDal,
        log: utils.NewLogEvent(
            utils.WithModule("moduleName"),
            utils.WithSubModule("service"),
        ),
    }
}
```

公开查询方法常见顺序：

1. 初始化空结果。
2. 如有 param 校验方法，调用 `param.Check()`。
3. 记录必要 trace 日志。
4. 如有需要，转换 DAL param。
5. 调用 DAL。
6. 错误日志 + 上层语义错误包装。
7. 空数据早返回空结果。
8. 聚合补充数据或转换 response。
9. 返回结果和 count。

复杂聚合方法常见顺序：

1. 如有 param 校验方法，调用 `param.Check()`。
2. 初始化完整 response，切片/map 都使用空集合。
3. 调用必要的前置 helper。
4. 按功能域调用 `addXxxData` helper。
5. 收集 helper 错误并记录日志。
6. 执行 response 后处理，如去重、过滤、内存分页、summary 计算。
7. 返回完整 response。

## Service Responsibilities

- 参数校验入口：公开 service 方法调用 `param.Check()`。
- 参数转换：只有当 API param 与 DAL param 不一致、映射复杂或多处复用时才抽转换方法；简单透传不需要额外转换。
- 编排：调用多个 DAL/service/cache，控制顺序和短路条件。
- 聚合：将多份底层数据合并成 response。
- 错误：记录底层错误细节，返回上层语义错误。
- 日志：在入口、关键 DAL 调用失败、聚合失败处记录必要上下文。
- 缓存：可读取/更新 service 级缓存，但缓存细节不要污染 DAL。

## Anti-Patterns

- 不要在 service 中直接访问数据库、拼 SQL、调用 GORM。
- 不要在 service 方法体中重复写 `s == nil` 或依赖为 nil 的防御判断；依赖完整性优先由构造/初始化阶段保证。
- 不要在 service 中重复参数清洗、格式校验、ID 规范化或派生查询值计算；放进 `param.Check()` 或 param 方法。
- 不要在 service 文件里定义 param、response、model struct；这些类型属于 model/API 层。
- 避免把复杂详情聚合写成一个超长公开方法；优先按数据域拆 helper。
- 不要吞掉 DAL 错误；按项目约定记录日志并返回错误。
- 列表/聚合查询成功时优先返回空切片，避免返回 nil slice。
- 避免在循环中重复查询可批量获取的数据；能批量时先收集 ID，去重后批量查，再用 map 回填。
- 不要把排序分页写在 service 中，除非明确是内存聚合后的二次过滤，并且注释说明原因。
- 不要新增 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型；类型约束遵循 model 层规则。

## Pre-Delivery Checklist

- [ ] 符合项目约定：有 service interface 时接口和实现 struct 都已更新。
- [ ] 涉及 DAL/cache/外部 I/O 的公开 service 方法第一个参数是 `ctx context.Context`。
- [ ] 构造函数注入必需依赖；需要 logger/cache 时已初始化。
- [ ] 方法体没有重复的 `s == nil` 或依赖 nil 防御判断。
- [ ] 有 param 校验方法时，公开方法入口调用 `param.Check()`，无重复参数清洗/ID 校验。
- [ ] service 没有直接 DB/GORM/SQL 操作。
- [ ] DAL 调用错误按项目约定记录日志并返回错误。
- [ ] 列表/聚合查询成功空结果返回空切片，不返回 nil slice。
- [ ] 复杂聚合已按数据域拆分或有明确理由保持在一个方法内。
- [ ] 可批量获取的关联数据先收集 ID、去重、批量查询、map 回填。
- [ ] 没有在 service 文件定义 param/response/model struct。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
