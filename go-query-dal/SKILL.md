---
name: go-query-dal
description: "Go DAL/DAO 数据访问层专家。Use when writing, refactoring, reviewing, or explaining store/DAL/DAO code, GORM queries, Create/Search/Update/Delete methods, pagination, Count + Find, context timeout, TableName, Serialize/Deserialize, ToUpdater, AddFilter, query params, update params, or PostgreSQL-compatible persistence."
---

# Go Query DAL

DAL 代码放在 `store` 目录/package，只编排持久化访问。一个 DAL 方法围绕一个主要数据 model；查询统一 `SearchXxx`；条件来自已校验的 model 层 param。

## Workflow

1. 确认 DAL 边界：`store` 目录/package、主要实体 model、model 层 param、目标表名、依赖 DAO/client、方法类型。
2. 加载 `references/go-query-dal-conventions.md`；同时遵循当前任务触发的 `go-code-style`、`go-model-hierarchy`、`go-logging`。
3. 定义接口和实现：公开方法第一个参数为 `ctx context.Context`；字段和构造参数按 DB、依赖 DAO/client、logger 顺序；实现 receiver 统一为 `dal`。
4. 处理 param/data：带领域方法的 param/data 使用指针类型；写入或查询前按需要执行 `Serialize()` / `Check()`。
5. 建立 DB 链路：每个 DB 方法创建 timeout context，并使用 `WithContext(cancelCtx)`；表名来自主要 model 的 `TableName()`。
6. 查询流程：初始化空结果切片；先业务过滤，再 `Count`，再 `AddFilter`，最后 `Find` 和 `Deserialize()`。
7. 写操作：Create 执行 `Serialize`/`Check`；Update 校验 ID、查原记录、校验不可变字段、使用 `ToUpdater()`；Delete 默认只按主键 ID 删除。

## Reference Loading

生成、重构或评审 DAL/DAO 查询层代码时，必须加载 `references/go-query-dal-conventions.md`。

## Pre-Delivery Checklist

- [ ] DAL/DAO 位于 `store` 目录/package；DAO 依赖由构造/初始化保证，方法体没有 nil 依赖跳过逻辑。
- [ ] DAO 字段、构造函数和方法 receiver 符合约定；receiver 统一为 `dal`。
- [ ] 接口保持资源/动作级 `Create/Search/Update/Delete`；没有主动新增 `FindXxx`、`GetXxx` 或场景化方法。
- [ ] 每个 DB 操作使用 timeout 和 `WithContext(cancelCtx)`。
- [ ] Param 定义在 model 同层；DAL 不重复清洗或校验领域字段。
- [ ] `Search` 初始化空结果 slice，链路按过滤、`Count`、`AddFilter`、`Find`、`Deserialize()` 顺序完整呈现。
- [ ] 一个 DAL 方法只围绕一个主要数据 model；跨表过滤优先子查询，没有不必要的 `Join`。
- [ ] 入库前执行 `Serialize()` / `Check()`；更新使用 `ToUpdater()`。
