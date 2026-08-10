---
name: go-query-dal
description: "Go DAL/DAO/GORM 查询层 Skill。Use when writing, refactoring, reviewing, debugging, or explaining store packages, DAL interfaces, DAO implementations, GORM queries, CRUD, pagination, database timeouts, and persistence boundaries."
---

# Go Query DAL

用于 Go store、DAL、DAO、GORM 和持久化访问任务。DAL 只编排持久化访问，一个 DAL 方法围绕一个主要数据 model；查询统一 `SearchXxx`，条件来自 model 层 param。

## Workflow

1. 确认 DAL 边界、主要实体 model、param、目标表、依赖 DAO/client 和方法类型。
2. 读取 `references/query-dal.md` 和 `references/query-dal-conventions.md`。
3. 涉及 model、service、logging、code style 或测试时，再按需使用对应 Go 分类 Skill。
4. 定义窄接口和 DAO 实现；公开方法遵循本层标准签名（`Create/Search`=`ctx+data/param`，`Update`=`ctx+id+data`，`Delete`=`ctx+id`），receiver 统一为 `dal`。
5. 每个 DB 方法创建 timeout context，使用 `WithContext(cancelCtx)`，表名来自主要 model 的 `TableName()`。
6. 修改 Go 文件后运行 `goimport`；能定位包或测试时运行最小范围 `go test`。

## Layer Boundaries

- DAL 不承载业务规则，不重复清洗或校验领域字段。
- Param 定义在 model 同层，不放在 DAL package。
- 默认不新增 DAL 日志；确实需要时先说明原因并让用户决定。
- DAO 依赖由构造/初始化保证，方法体不做 nil 依赖跳过逻辑。

## Pre-Delivery Checklist

- 已读取本 Skill 的两个 reference。
- DAL 位于 `store` 目录/package，接口、DAO、constructor 和 receiver 符合约定。
- 查询、分页、CRUD、timeout、`Serialize()` / `Check()` / `Deserialize()` / `ToUpdater()` 调用顺序符合 reference。
- 修改 Go 文件后已运行 `goimport`；能运行时已执行相关 `go test`。
