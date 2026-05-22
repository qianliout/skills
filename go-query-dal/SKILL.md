---
name: go-query-dal
description: "Go DAL/DAO 数据访问层专家。Use when writing, refactoring, or reviewing GORM queries, Search/Create/Update/Delete methods, pagination, Count + Find, context timeout, TableName, Serialize/Deserialize, ToUpdater, AddFilter, query params, update params, or PostgreSQL-compatible data access."
---

# Go Query DAL

DAL 只编排数据库访问，不承载业务规则。每个 DB 方法必须有 timeout；查询条件来自已校验的 model 层 param；排序分页由外部调用方通过 model 层 `AddFilter` 决定。

## Workflow

1. 识别 DAL 边界：确认实体 model、model 层 param、目标表名、依赖 DAL 和方法类型。
2. 加载 `references/go-query-dal-conventions.md`，按项目约定处理 DB timeout、GORM 链路、过滤分页和序列化。
3. 定义接口：公开方法第一个参数是 `ctx context.Context`；默认提供 `Create`、`Search`、`Update`、`Delete`。
4. 实现查询：开头调用 `param.Check()`；创建 `context.WithTimeout` 并使用 `WithContext(cancelCtx)`。
5. 组织 GORM 链路：初始化空结果切片，表名来自 `TableName()`；先业务过滤，再 `Count`，再 `AddFilter`，最后 `Find` 和 `Deserialize()`。
6. 实现写操作：`Create` 执行 `Check`/`Serialize`；`Update` 校验 ID/data、查原记录、校验不可变字段、`Serialize`、`ToUpdater`；`Delete` 只按主键 ID 删除。
7. 交付：缺少 model 方法或 param 字段时列出假设，不临时把类型写进 DAL。

## Reference Loading

生成、重构或评审 DAL/DAO 查询层代码时，必须加载 `references/go-query-dal-conventions.md`。

## Pre-Delivery Checklist

- [ ] DAO 依赖有效性由构造/初始化保证，方法体没有 `dal == nil` 或 `dal.db == nil` 判断。
- [ ] 每个 DB 操作都使用 `context.WithTimeout` 和 `WithContext(cancelCtx)`。
- [ ] `Create/Search/Update/Delete` 签名符合约定；没有主动新增 `Get`。
- [ ] 所有 param 定义在 model 同层；字段命名语义化，能看出主 model 或关联 model 含义。
- [ ] `Search` 开头调用 `param.Check()`，DAL 内没有重复参数清洗、UUID 校验或派生字段计算。
- [ ] 查询链路按步骤拆开；where 只在 param 非零值时追加，零值特殊查询有注释。
- [ ] 查询兼容不同数据库，没有不必要的高阶 SQL、数据库特有函数、JSON/数组操作、全文检索等。
- [ ] where 条件没有对数据库列做计算、函数包裹或类型转换；确需使用时已有详细注释。
- [ ] `Search` 先 `Count`，再通过 `AddFilter` 应用排序分页；DAL 没有手写 `Order/Limit/Offset` 或默认排序。
- [ ] 出库结果已 `Deserialize()`；入库前已 `Check()` / `Serialize()`；更新使用 `ToUpdater()`。
- [ ] 没有新增 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
