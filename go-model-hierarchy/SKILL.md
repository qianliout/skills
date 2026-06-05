---
name: go-model-hierarchy
description: "Go model 层级和数据模型专家。Use when designing, writing, refactoring, reviewing, or explaining domain models, GORM models, DTO/VO/entity structs, params, responses, cache/stat models, JSON/GORM tags, TableName, Check, Serialize/Deserialize, ToUpdater, Same, UniqueID, derived fields, model constants, or field lifecycle."
---

# Go Model Hierarchy

先定义模型层级和字段生命周期，再写 struct。Model 层负责 model、param、校验、序列化、反序列化、派生字段和更新字段选择；常量统一放到项目定义的 `consts` 目录。

## Workflow

1. 识别模型职责：实体、param、response/view、cache/statistic，或辅助值对象。
2. 加载 `references/go-model-conventions.md`；同时遵循当前任务触发的 `go-code-style`、`go-comment-style`、`go-logging`。
3. 先给模型树，再给 struct：实体优先，param/view/cache/statistic 跟随所属实体或业务域。
4. 定义字段契约：落库字段使用数据库兼容基础类型；普通持久化字段 `gorm` tag 只写 `column:...`；JSON tag 不写 `omitempty`；运行时字段使用 `gorm:"-"`。
5. 处理时间和数值：项目默认 `int64`；新表/新功能时间字段使用毫秒级 `int64` 时间戳。
6. 管理复杂结构：避免数据库 JSON/JSONB、数组、map、对象列；确需复杂结构时用文本列配合 `Serialize()` / `Deserialize()`。
7. 补齐模型行为：实体通常提供 `TableName()`、`Check()`、`Serialize()`、`Deserialize()`；更新提供 `ToUpdater() map[string]any`；比较提供 `Same()`。
8. 归属方法：领域规整统一收敛到拥有字段的公有 `Serialize()`；不新增 `Normalize()`、`FillDefault()` 或同职责私有 helper。

## Reference Loading

生成、重构或评审 model 层代码时，必须加载 `references/go-model-conventions.md`。

## Pre-Delivery Checklist

- [ ] 已说明模型层级和字段生命周期；实体、param、response/view、cache/statistic 归属清楚。
- [ ] Param、校验、序列化、反序列化、派生字段和更新字段选择都归属 model 层。
- [ ] 领域行为使用指针 receiver；Param receiver 为 `p`，其他 model 层对象 receiver 为 `vi`。
- [ ] 生命周期方法使用固定公有签名；`Serialize()` / `Deserialize()` 正确处理 nil receiver，调用方接收返回值。
- [ ] `Serialize()` / `Deserialize()` / `ToUpdater()` / `Check()` / `Same()` 不互相调用，组合顺序由外部决定。
- [ ] 落库字段、复杂结构、标准基础字段、`TableName()`、tag 和 `ToUpdater()` 符合 reference 约定。
- [ ] Model 层不依赖 API/service/DAL 等业务层。
