---
name: go-query-dal
description: "通用 Go 数据查询 DAL/DAO 层专家，生成、重构、评审数据库访问层。Use when user asks 写 DAL、写 DAO、数据查询、GORM query、Search 方法、Create/Update/Delete、分页查询、Count + Find、context timeout、TableName、Serialize/Deserialize、ToUpdater、AddFilter、查询参数、更新参数、PostgreSQL 数据访问层。Actions: design, create, refactor, review, implement data access layer."
---

# Go Query DAL

核心约束：DAL 只负责编排数据库访问，不承载业务规则；每个 DB 方法必须有超时时间；入库前调用 model 的 `Check()` / `Serialize()`，出库后调用 `Deserialize()`，查询条件必须从明确的 param 字段构造。
DAO 的依赖有效性由构造/初始化阶段保证；DAL 方法体内不要写 `dal == nil` 或 `dal.db == nil` 防御判断。

## Workflow

- [ ] Step 1: 识别 DAL 边界 ⚠️ REQUIRED
  - [ ] 确认实体 model、查询 param、更新 param、依赖 DAL、目标表名来源。
  - [ ] 各种 param 类型必须定义在 model 同层包/目录；DAL 只引用 param，不在 DAL 文件中定义 param。
  - [ ] 判断要生成的是 `Create`、`Search`、`Update`、`Delete`，还是组合维护方法。
- [ ] Step 2: 定义接口
  - [ ] 先写 `XxxDal interface`，再写 `XxxDao struct`。
  - [ ] 所有公开方法第一个参数必须是 `ctx context.Context`。
  - [ ] `Create` 只有两个入参：`ctx context.Context` 和 `data *Model`。
  - [ ] `Search` 只有两个入参：`ctx context.Context` 和 `param SearchParam`；出参固定为 `([]*Model, int64, error)`。
  - [ ] `Update` 只有三个入参：`ctx context.Context`、主键 `id int64`、`data *Model`。
  - [ ] `Delete` 只有两个入参：`ctx context.Context` 和主键 `id int64`。
  - [ ] 默认不要提供 `Get` 方法；除非用户明确要求单条查询。
- [ ] Step 3: 实现查询
  - [ ] 先调用 `param.Check()`；参数合法性、trim、UUID 校验、默认值、派生查询字段都在 param 层完成。
  - [ ] 每个 DB 方法创建 `context.WithTimeout`，并 `defer cancelFunc()`。
  - [ ] 使用 `dal.db.Get().WithContext(cancelCtx).Table(model.TableName())` 起查询。
  - [ ] 可选字段投影使用 `Select(param.Filed)`，保持现有拼写兼容时不要擅自改名。
  - [ ] GORM 查询链路必须单步拆开，使用 `db = db.Where(...)` 逐步追加条件，不要写很长的连续链式调用。
  - [ ] param 字段非零值时才追加 where；如果零值代表查询全部或特殊含义，必须写注释说明。
  - [ ] 查询条件中不要对数据库列做计算、函数包裹或类型转换，避免索引隐式失效；确实必须使用时，写清楚原因、索引影响和数据规模假设。
  - [ ] 先拼业务 where，再 `Count(&cnt)`，再调用 model 层的 `AddFilter(db, param.Filter)` 应用外部传入的排序分页，最后 `Find(&res)`。
  - [ ] DAL 不决定默认排序；排序由外部调用方通过 `param.Filter` 指定。
  - [ ] 出库后对每条数据调用 `Deserialize()`。
- [ ] Step 4: 实现写操作
  - [ ] `Create`: `Check()` 后 `Serialize()`，再 `Create(data)`。
  - [ ] `Update`: 校验 ID 和 updater，先查原记录，必要时校验不可变字段，再 `Serialize()` + `ToUpdater()` + `Updates(updater)`。
  - [ ] `Delete`: 校验 ID，先查原记录，校验不可删除条件，再删除。
- [ ] Step 5: 交付检查
  - [ ] 运行 Pre-Delivery Checklist。
  - [ ] 如果缺少 model 方法或 param 字段，列出假设，不编造外部类型。

## Reference Loading

需要生成或评审 Go DAL/DAO 查询层代码时，加载 `references/go-query-dal-conventions.md`。

## Required Patterns

接口和 DAO 结构：

```go
type XxxDal interface {
    CreateXxx(ctx context.Context, data *model.Xxx) error
    SearchXxx(ctx context.Context, param model.SearchXxxParam) ([]*model.Xxx, int64, error)
    UpdateXxx(ctx context.Context, id int64, data *model.Xxx) error
    DeleteXxx(ctx context.Context, id int64) error
}

type XxxDao struct {
    db *databases.RDBInstance
}
```

查询方法顺序：

1. 调用 `param.Check()`。
2. 创建 timeout context。
3. 初始化结果切片为空切片，不返回 nil slice。
4. 从 model 的 `TableName()` 获取表名。
5. 按 param 非零字段逐步拼接精确条件。
6. `Count(&cnt)`。
7. 调用 model 层 `AddFilter(db, param.Filter)` 应用外部传入的排序和分页。
8. `Find(&res)`。
9. 对结果执行 `Deserialize()`。
10. 返回 `res, cnt, err`。

写方法顺序：

- `Create`: `Check()` -> `Serialize()` -> `Create()` -> 可选维护附属版本/缓存。
- `Update`: 参数校验 -> 查询原记录 -> 不可变字段校验 -> `Serialize()` -> `ToUpdater()` -> `Updates()`。
- `Delete`: 参数校验 -> 查询原记录 -> 保护规则校验 -> `Delete()` -> 可选维护附属版本/缓存。

方法签名约束：

- `CreateXxx(ctx context.Context, data *model.Xxx) error`
- `SearchXxx(ctx context.Context, param model.SearchXxxParam) ([]*model.Xxx, int64, error)`
- `UpdateXxx(ctx context.Context, id int64, data *model.Xxx) error`
- `DeleteXxx(ctx context.Context, id int64) error`
- 不主动生成 `GetXxx`；需要单条查询时优先通过 `Search` 的 param 约束实现，除非用户明确要求。

Param 定义位置：

- `SearchXxxParam`、`UpdateXxxParam`、过滤/排序/分页 param 都定义在 model 同层包/目录。
- DAL 文件只 import model 包并使用 `model.SearchXxxParam`，不要在 DAL 包里新增 param struct。
- 如果 param 尚不存在，交付时说明需要在 model 层补充；不要为了让 DAL 编译而把 param 临时写进 DAL 文件。

Param 语义命名：

- 查询参数尽量语义化，字段名要说明它过滤的是主查询 model 还是关联 model。
- 与主 model 相关的条件使用主 model 语义，如 `Status`、`OwnerID`、`CreatedBy`。
- 与关联 model 相关的条件在字段名里带出关联对象语义，如 `ProjectID`、`UserID`、`PolicyID`、`RelatedName`。
- 避免只有 `ID`、`Type`、`Name`、`Keyword` 这类过泛字段；除非 param 只面向单一明确模型且语义不会歧义。
- 一个 param 同时查询多个关联对象时，字段名必须能看出来源对象，避免让 DAL 读者反推 where 条件含义。

## Type And Value Rules

- ID 参数使用 `int64`，不使用 `uint64` / `uint`。
- 不使用比 `int64` 更大的数值类型；外部超大 ID 只作为 `string` 标识。
- 二值查询参数和状态字段使用 `string`，取值 `"true"` / `"false"`，不使用 `bool`。

## Anti-Patterns

- 不要在 DAL 中生成 model 派生字段；派生字段属于 `Serialize()`。
- 不要在 DAL 方法体中判断 `dal == nil` 或 `dal.db == nil`；构造函数必须保证 DAO 可用。
- 不要在 DAL 中做参数清洗、格式校验、ID 规范化或派生查询值计算；这些逻辑统一放进 `param.Check()` 或 param 的规范化字段，DAL 只消费校验后的 param。
- 不要在查询中直接拼接用户输入 SQL；使用 `Where("field = ?", value)`。
- 不要写很长的 GORM 连续链式调用；每个 `Where` 和最终 `Find` 单独成步，便于阅读和插入条件。
- 不要用零值 param 直接过滤，如 `Where("project_id = ?", param.ProjectID)`；先判断非零值。若零值是“查询全部”等特殊场景，必须写注释说明。
- 不要在查询条件里对列做计算、函数包裹或类型转换，如 `DATE(created_at)`、`LOWER(name)`、`CAST(id AS text)`、`amount + fee`；这些写法容易让普通索引隐式失效。确实必须使用时，必须补充详细注释说明原因、索引影响、数据规模和替代方案不可行的原因。
- 不要在 DAL 中手写 `Order`、`Limit`、`Offset`；所有排序分页必须通过 model 层 `AddFilter`。
- 不要在 DAL 中设置默认排序或决定怎么排序；排序由外部调用方通过 `param.Filter` 决定。
- 不要把分页和排序放在 `Count()` 之前。
- 不要返回未 `Deserialize()` 的 model 给上层。
- 不要在 `Update` 中直接全量保存 struct；使用 `ToUpdater()` 控制可更新列。
- 不要忽略 `Count()` 错误后继续查询。
- 不要使用 `context.Background()` 替代传入的 `ctx`。
- 不要在 DAL 方法里吞掉主操作错误；附属维护失败若允许忽略，必须显式 `_ = helper(ctx)`。
- 不要主动新增 `Get` 方法；不要为 `Search`、`Update`、`Delete` 增加额外入参。
- 不要在 DAL 包/文件中定义 `SearchXxxParam`、`UpdateXxxParam` 或分页过滤参数；param 属于 model 层。
- 不要设计语义含混的查询参数字段；字段名应关联到主 model 或关联 model 的业务概念。

## Pre-Delivery Checklist

- [ ] 所有公开 DAL 方法第一个参数是 `ctx context.Context`。
- [ ] 构造函数保证 `db` 非空，方法体没有 `dal == nil` / `dal.db == nil` 判断。
- [ ] 每个 DB 操作都必须使用 `context.WithTimeout` 和 `WithContext(cancelCtx)`。
- [ ] `Create` 签名是 `CreateXxx(ctx context.Context, data *model.Xxx) error`。
- [ ] `Search` 签名是 `SearchXxx(ctx context.Context, param model.SearchXxxParam) ([]*model.Xxx, int64, error)`。
- [ ] `Update` 签名是 `UpdateXxx(ctx context.Context, id int64, data *model.Xxx) error`。
- [ ] `Delete` 签名是 `DeleteXxx(ctx context.Context, id int64) error`，没有额外参数。
- [ ] 没有主动提供 `Get` 方法，除非用户明确要求。
- [ ] 所有 param 类型都位于 model 同层包/目录，DAL 文件没有定义 param struct。
- [ ] 查询 param 字段命名语义化，能看出过滤的是主 model 还是关联 model。
- [ ] 查询结果切片用 `make([]*T, 0)` 初始化。
- [ ] 表名来自 `TableName()`，没有硬编码散落在查询里。
- [ ] `Search` 开头调用 `param.Check()`，且 DAL 内没有重复参数清洗/UUID 校验。
- [ ] GORM 查询按步骤拆开，没有长链式调用。
- [ ] where 条件只在 param 字段非零值时追加；零值特殊查询有明确注释。
- [ ] where 条件没有对数据库列做计算、函数包裹或类型转换；如必须使用，已有详细注释说明索引影响和原因。
- [ ] `Search` 先 `Count`，再调用 model 层 `AddFilter` 应用外部排序分页，再 `Find`。
- [ ] DAL 内没有手写 `Order`、`Limit`、`Offset`。
- [ ] DAL 没有设置默认排序；排序只来自外部传入的 `param.Filter`。
- [ ] 查询返回前调用 `Deserialize()`。
- [ ] `Create` 调用 `Check()` 和 `Serialize()`。
- [ ] `Update` 使用 `ToUpdater()`，没有全量覆盖 struct。
- [ ] 没有新增 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
