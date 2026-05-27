---
name: go-query-dal
description: "Go DAL/DAO 数据访问层专家。Use when writing, refactoring, or reviewing GORM queries, Search/Create/Update/Delete methods, pagination, Count + Find, context timeout, TableName, Serialize/Deserialize, ToUpdater, AddFilter, query params, update params, or PostgreSQL-compatible data access."
---

# Go Query DAL

DAL 只编排数据库访问，不承载业务规则。每个 DB 方法必须有 timeout；查询条件来自已校验的 model 层 param；排序分页必须统一使用专门定义的 model 层 `AddFilter` 方法。

## Workflow

1. 识别 DAL 边界：确认实体 model、model 层 param、目标表名、依赖 DAL 和方法类型。
2. 加载 `references/go-query-dal-conventions.md`，按项目约定处理 DB timeout、GORM 链路、过滤分页和序列化。
3. 定义接口：公开方法第一个参数是 `ctx context.Context`；字段和构造函数参数常见顺序为 DB/事务入口、依赖 DAO/repository、外部 client/helper、logger；DB、logger、依赖 DAO/client 等通过构造函数或明确字段注入；DAO 实现方法统一使用指针接收者，receiver 统一命名为 `dal`；默认提供 `Create`、`Search`、`Update`、`Delete`。
4. 实现查询：带领域方法的 param 使用指针类型；开头按 `param = param.Serialize()`、`param.Check()` 顺序处理；查询字段规整依赖拥有字段的 param 公有 `Serialize()`；创建 `context.WithTimeout` 并使用 `WithContext(cancelCtx)`。
5. 组织 GORM 链路：一个 DAL 方法里尽量从上到下完成完整查询链路，让使用者打开方法就能看懂查询方式；先初始化空结果切片，所有返回路径都不能返回 nil slice；表名来自 `TableName()`；先业务过滤，再 `Count`，再 `AddFilter`，最后 `Find` 和 `Deserialize()`。
6. 实现写操作：`Create` 执行 `Serialize`/`Check`；`Update` 校验 ID，执行 `Serialize`/`Check`，查原记录、校验不可变字段、`ToUpdater`；`Delete` 只按主键 ID 删除；查询链路优先线性保留，只有维护派生表/缓存/版本等独立副作用时才拆 helper。
7. 交付：缺少 model 方法或 param 字段时列出假设，不临时把类型写进 DAL。

## Reference Loading

生成、重构或评审 DAL/DAO 查询层代码时，必须加载 `references/go-query-dal-conventions.md`。

## Pre-Delivery Checklist

- [ ] 新写 DAL/DAO 代码同时符合 `go-code-style`、`go-model-hierarchy`、`go-logging` 中当前任务涉及的规则。
- [ ] DAO 依赖有效性由构造/初始化保证，方法体没有 `dal == nil` 或 `dal.db == nil` 判断。
- [ ] DAO 的字段和构造函数参数按 DB/事务入口、依赖 DAO/repository、外部 client/helper、logger 的常见顺序组织。
- [ ] DAO 的 DB/logger/依赖 DAO/client 等长期依赖通过构造函数或明确字段注入，没有在查询方法内临时创建。
- [ ] DAO 实现方法都使用指针接收者，receiver 统一命名为 `dal`，例如 `func (dal *XxxDao) SearchXxx(...)`，没有值接收者。
- [ ] 每个 DB 操作都使用 `context.WithTimeout` 和 `WithContext(cancelCtx)`。
- [ ] `Create/Search/Update/Delete` 签名符合约定；没有主动新增 `Get`。
- [ ] 所有 param 定义在 model 同层；字段命名语义化，能看出主 model 或关联 model 含义。
- [ ] DAL 涉及的 model/param/result struct 的 `json` tag 没有 `omitempty`。
- [ ] 新表或新功能的时间字段按毫秒级 `int64` 时间戳落库和查询；已有表/功能不因本规则强制迁移。
- [ ] `Search` 的 param 入参是指针类型，开头按 `param = param.Serialize()`、`param.Check()` 顺序处理，DAL 内没有重复参数清洗、UUID 校验或派生字段计算。
- [ ] DAL 内没有散落 trim/default/derive/fill 逻辑或以 param/model 为首参的规整 helper；这类逻辑已挂到拥有字段的 param/model 公有 `Serialize()` 上，没有 `Normalize()`、`FillDefault()` 或小写规整方法。
- [ ] DAL 作为外部调用方显式组合领域方法；不依赖 `Check()`、`ToUpdater()`、`Same()` 内部代调 `Serialize()` / `Deserialize()`。
- [ ] `Search` 的结果 slice 已在函数开头实例化，校验错误、查询错误和成功路径都返回该空 slice 而不是 nil。
- [ ] 查询链路在同一个 DAL 方法中自上而下完整呈现；where 只在 param 非零值时追加，零值特殊查询有注释。
- [ ] DAL 查询没有被拆成大量 `buildWhere`、`countXxx`、`findXxx` 之类无必要跳转；独立 helper 只用于清晰的维护副作用或复用查询片段。
- [ ] 查询兼容不同数据库，没有不必要的高阶 SQL、数据库特有函数、JSON/数组操作、全文检索等。
- [ ] where 条件没有对数据库列做计算、函数包裹或类型转换；确需使用时已有详细注释。
- [ ] `Search` 先 `Count`，再通过专门定义的 `AddFilter` 统一应用排序分页；DAL 没有手写 `Order/Limit/Offset` 或默认排序。
- [ ] 出库结果已 `Deserialize()`；入库前已按 `Serialize()` / `Check()` 顺序处理；更新使用 `ToUpdater()`。
- [ ] 没有新增 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
