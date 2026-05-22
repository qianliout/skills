---
name: go-model-hierarchy
description: "Go model 层级和数据模型专家。Use when designing, writing, refactoring, or reviewing domain models, GORM models, DTO/VO/entity structs, JSON/GORM tags, params, responses, cache/stat models, TableName, Check, Serialize/Deserialize, ToUpdater, UniqueID, derived fields, or model constants."
---

# Go Model Hierarchy

先定义模型层级和字段生命周期，再写 struct。model 层负责 model、param、model 常量、校验、序列化、反序列化、派生字段和更新字段选择；强关联方法优先作为具体 model/param 的 receiver 方法。

## Workflow

1. 识别模型职责：判断目标是实体、param、response/view/cache/statistic，还是辅助值对象。
2. 加载 `references/go-model-conventions.md`，按项目约定处理字段生命周期、tag、校验和序列化。
3. 建立层级：先给模型树，再给 struct；实体模型优先，param/view/cache/statistic 跟随所属实体或业务域。
4. 定义字段契约：落库字段使用数据库兼容基础类型和明确 `gorm` tag；API 字段使用稳定 `json` tag；运行时字段使用 `gorm:"-"`。
5. 处理复杂结构：避免数据库 JSON/JSONB、数组、map、对象列；需要时用文本列配合 `Serialize()` / `Deserialize()`。
6. 补齐模型行为：实体通常提供 `TableName()`、`Check()`、`Serialize()`、`Deserialize()`；更新提供 `ToUpdater()`，且返回 map 必须实例化；比较提供 `Same()`。
7. 归属方法和常量：强关联逻辑写成 receiver 方法；请求/参数规整放到 `Normalize()`；model 常量、枚举、默认值、字段约束放在 model 层。
8. 交付：信息不足时列出假设，不编造未知表名、枚举值或外部类型。

## Reference Loading

生成、重构或评审 model 层代码时，必须加载 `references/go-model-conventions.md`。

## Pre-Delivery Checklist

- [ ] 已说明模型层级和字段生命周期。
- [ ] param、model 常量、校验、序列化、反序列化等强关联能力都在 model 层，常量没有散落到其他层。
- [ ] 没有把明显属于某个 model/param/result struct 的行为写成以该 struct 为首参的裸 helper；此类逻辑已归属为 receiver 方法。
- [ ] 请求/参数 struct 的 `Normalize()` 是 receiver 方法，直接规整当前对象并返回自身，没有创建规整副本。
- [ ] `ToUpdater()` 或其他 map/slice 返回值已实例化，所有返回路径都不返回 nil map/slice。
- [ ] 二值/状态语义字段没有使用冗余 `Is` 前缀，除非项目既有约定或外部协议强制要求。
- [ ] model 层只依赖标准库、外部基础库和项目 utils；不依赖 API/service/DAL 等业务层。
- [ ] 落库字段没有使用 JSON/JSONB、数组、map、复杂对象等数据库复杂类型。
- [ ] 复杂结构已用 `ConfigJSON string` 这类文本列配合 `Serialize()` / `Deserialize()`，或按查询/更新/约束需求拆列/拆表。
- [ ] 每个落库实体都有 `TableName()`；运行时字段有 `gorm:"-"`；序列化文本字段有 `json:"-"`。
- [ ] 数值字段默认使用 Go 类型 `int64`；使用其他数值类型时有明确理由。
- [ ] 没有新增 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型。
- [ ] 二值状态字段是 `string`，取值约定为 `"true"` / `"false"`。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
