---
name: go-model-hierarchy
description: "Go model 层级和数据模型专家。Use when designing, writing, refactoring, or reviewing domain models, GORM models, DTO/VO/entity structs, JSON/GORM tags, params, responses, cache/stat models, TableName, Check, Serialize/Deserialize, ToUpdater, UniqueID, derived fields, or model constants."
---

# Go Model Hierarchy

先定义模型层级和字段生命周期，再写 struct。model 层负责 model、param、校验、序列化、反序列化、派生字段和更新字段选择；常量统一放到项目定义的 `consts` 目录下；强关联方法优先作为具体 model/param 的 receiver 方法。

## Workflow

1. 识别模型职责：判断目标是实体、param、response/view/cache/statistic，还是辅助值对象。
2. 加载 `references/go-model-conventions.md`，按项目约定处理字段生命周期、tag、校验和序列化。
3. 建立层级：先给模型树，再给 struct；实体模型优先，param/view/cache/statistic 跟随所属实体或业务域。
4. 定义字段契约：落库字段使用数据库兼容基础类型；普通持久化字段的 `gorm` tag 只写 `column:...`，标准基础字段使用固定的 `ID`、`CreatedAt`、`UpdatedAt`、`DeletedAt` tag；项目内数值类型默认统一使用 `int64`，model、param、response/view、cache/statistic 和辅助值对象的字段都遵循这个默认；除非外部协议、第三方库签名、明确性能/存储边界或既有兼容约束确有必要，不新增 `int`、`int32`、`uint`、`uint64` 等其它数值类型，也不要仅为兼容旧实现保留非 `int64` 数值类型；字段优先使用 `string`、`int64` 等基础类型，除非确有必要，避免新增基础包装类型，如 `type Kind string`；每个落库数据 model 都必须包含 `ID int64` 数据库主键字段，以及 `CreatedAt`、`UpdatedAt`、`DeletedAt` 三个 `int64` 毫秒级生命周期字段；新设计的表或功能中，所有时间相关字段统一使用 `int64` 毫秒级时间戳，数据库存储、前后端传参和层间传递都保持毫秒；API 字段使用稳定 `json` tag，且任何 `json` tag 都不能带 `omitempty`；运行时字段使用 `gorm:"-"`。
5. 处理复杂结构：避免数据库 JSON/JSONB、数组、map、对象列；需要时用文本列配合 `Serialize()` / `Deserialize()`。
6. 补齐模型行为：实体通常提供 `TableName()`、`Check()`、`Serialize()`、`Deserialize()`；更新提供 `ToUpdater() map[string]any`，返回 map 必须实例化，按可更新字段全量写入，不因字段是 0 值或空值跳过；比较提供 `Same()`。
7. 归属方法和常量：强关联逻辑写成 pointer receiver 方法，不能使用值接收者；同一个 model/param/result struct 的所有方法接收者必须一致；名字含 Param 的 receiver 统一命名为 `p`，其他 model 层对象如 model/entity/result/view/cache/statistic 的 receiver 统一命名为 `vi`；领域规整逻辑尽量挂到拥有这些字段的 struct 上，并统一收敛到公有 `Serialize()`；不要新增 `Normalize()`、`FillDefault()` 或小写规整方法；领域方法之间不互相调用，组合顺序由外部决定；包级函数只保留真正通用、无字段归属的工具；model 相关常量、枚举、默认值、字段约束统一放到项目定义的 `consts` 目录下。
8. 交付：信息不足时列出假设，不编造未知表名、枚举值或外部类型。

## Reference Loading

生成、重构或评审 model 层代码时，必须加载 `references/go-model-conventions.md`。

## Pre-Delivery Checklist

- [ ] 已同时符合 `go-code-style`、`go-logging` 以及调用层当前任务涉及的规则。
- [ ] 已说明模型层级和字段生命周期；实体、param、response/view/cache/statistic 归属清楚。
- [ ] Param、校验、序列化、反序列化、派生字段和更新字段选择都归属 model 层。
- [ ] 领域行为使用指针 receiver；Param receiver 为 `p`，其他 model 层对象 receiver 为 `vi`。
- [ ] 生命周期方法使用固定公有签名；`Serialize()` / `Deserialize()` 正确处理 nil receiver，调用方接收返回值。
- [ ] 规整逻辑统一在拥有字段的 `Serialize()` 中；没有 `Normalize()`、`FillDefault()` 或同职责私有 helper。
- [ ] 落库字段、复杂结构、标准基础字段、`TableName()`、tag 和 `ToUpdater()` 符合 reference 约定；`ToUpdater()` 返回 `map[string]any`，只包含可更新字段且不按 0 值跳过；普通持久化字段的 `gorm` tag 只包含 `column:...`。
- [ ] Model 层不依赖 API/service/DAL 等业务层。
