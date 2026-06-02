---
name: go-query-dal
description: "Go DAL/DAO 数据访问层专家。Use when writing, refactoring, or reviewing GORM queries, Search/Create/Update/Delete methods, pagination, Count + Find, context timeout, TableName, Serialize/Deserialize, ToUpdater, AddFilter, query params, update params, or PostgreSQL-compatible data access."
---

# Go Query DAL

DAL 代码统一放在 `store` 目录/package，只编排数据库访问，不承载业务规则。每个 DB 方法必须有 timeout；查询条件来自已校验的 model 层 param；排序分页必须统一使用专门定义的 model 层 `AddFilter` 方法。

## Workflow

1. 识别 DAL 边界：确认 `store` 目录/package、实体 model、model 层 param、目标表名、依赖 DAL 和方法类型。
2. 加载 `references/go-query-dal-conventions.md`，按项目约定处理 DB timeout、GORM 链路、过滤分页和序列化。
3. 定义接口：公开方法第一个参数是 `ctx context.Context`；字段和构造函数参数常见顺序为 DB/事务入口、依赖 DAO/repository、外部 client/helper、logger；DB、logger、依赖 DAO/client 等通过构造函数或明确字段注入，不能因为依赖为 nil 就跳过查询、写入或维护逻辑；DAL 接口保持 `Create/Search/Update/Delete` 等资源/动作级方法，不新增 `SearchXxxForUser`、`UpdateXxxForProject` 这类场景化方法；同一个 DAO struct 的实现方法统一使用指针接收者，receiver 统一命名为 `dal`。
4. 实现查询：带领域方法的 param 使用指针类型；开头按 `param = param.Serialize()`、`param.Check()` 顺序处理；查询字段规整依赖拥有字段的 param 公有 `Serialize()`；创建 `context.WithTimeout` 并使用 `WithContext(cancelCtx)`。
5. 组织 GORM 链路：一个 DAL 方法里尽量从上到下完成完整查询链路，让使用者打开方法就能看懂查询方式；先初始化空结果切片，所有返回路径都不能返回 nil slice；表名来自 `TableName()`；先业务过滤，再 `Count`，再 `AddFilter`，最后 `Find` 和 `Deserialize()`。
6. 实现写操作：`Create` 执行 `Serialize`/`Check`；`Update` 校验 ID，执行 `Serialize`/`Check`，查原记录、校验不可变字段、`ToUpdater`；`Delete` 只按主键 ID 删除；查询链路优先线性保留，只有维护派生表/缓存/版本等独立副作用时才拆 helper。
7. 交付：缺少 model 方法或 param 字段时列出假设，不临时把类型写进 DAL。

## Reference Loading

生成、重构或评审 DAL/DAO 查询层代码时，必须加载 `references/go-query-dal-conventions.md`。

## Pre-Delivery Checklist

- [ ] 已同时符合 `go-code-style`、`go-model-hierarchy`、`go-logging` 中当前任务涉及的规则。
- [ ] DAL/DAO 位于 `store` 目录/package；DAO 依赖由构造/初始化保证，方法体没有依赖 nil 判断或 nil 跳过逻辑。
- [ ] DAO 字段、构造函数和方法 receiver 符合约定；receiver 统一为 `dal`。
- [ ] 只提供资源/动作级 `Create/Search/Update/Delete` 等接口；没有主动新增 `Get` 或 `SearchXxxForUser`、`UpdateXxxForProject` 等场景化方法。
- [ ] 每个 DB 操作使用 timeout 和 `WithContext(cancelCtx)`。
- [ ] Param 定义在 model 同层；DAL 只消费已 `Serialize()` / `Check()` 的 param，不重复清洗或校验。
- [ ] `Search` 初始化空结果 slice，链路按过滤、`Count`、`AddFilter`、`Find`、`Deserialize()` 顺序完整呈现。
- [ ] 查询保持数据库兼容；没有不必要的高阶 SQL、列计算、手写排序分页或 helper 拆碎查询链路。
- [ ] 入库前执行 `Serialize()` / `Check()`；更新使用 `ToUpdater()`。
