---
name: go-model-hierarchy
description: "通用 Go 数据 model 层级定义专家，生成、重构、评审领域模型和数据模型。Use when user asks 定义数据模型、model 层级、领域模型、Go struct、GORM model、JSON tag、DTO/VO/Entity、Serialize/Deserialize、Check 校验、TableName、UniqueID、派生字段、缓存模型、统计模型、查询参数、更新参数、视图模型。Actions: design, create, refactor, review, define data model hierarchy."
---

# Go Model Hierarchy

先定义模型层级和字段生命周期，再写 struct。model 层负责 model、param、model 常量、校验、序列化、反序列化、派生字段和更新字段选择；强关联方法优先作为具体 model/param 的 receiver 方法。

## Workflow

- [ ] Step 1: 识别模型职责
  - 判断目标是实体、param、response/view/cache/statistic，还是辅助值对象。
  - 标出字段来源：DB、API、运行时、序列化文本、派生字段。
  - 加载 `references/go-model-conventions.md`，按项目约定落地。
- [ ] Step 2: 建立层级
  - 先给模型树，再给 struct。
  - 实体模型优先；param、view、cache、statistic 跟随所属实体或业务域。
  - 写清聚合、引用、运行时填充、序列化嵌入的边界。
- [ ] Step 3: 定义字段契约
  - 落库字段使用数据库兼容基础类型和明确 `gorm` tag。
  - API 字段使用稳定 `json` tag；运行时字段使用 `gorm:"-"`。
  - 复杂结构不要使用数据库 JSON/JSONB、数组、map、对象列；可用 `ConfigJSON string` 这类文本列配合 `Serialize()` / `Deserialize()`。
  - 不使用 `uint64` / `uint`、大于 `int64` 的数值类型、`bool`；二值状态用字符串 `"true"` / `"false"`。
- [ ] Step 4: 补齐模型行为
	- 实体通常提供 `TableName()`、`Check()`、`Serialize()`、`Deserialize()`。
	- 有更新需求时提供 `ToUpdater()`；有内容比较需求时提供 `Same()`。
	- 请求/参数 struct 如需统一清理空格、默认值、大小写、引用列表等输入规整逻辑，提供 receiver 方法 `Normalize()`，并直接修改当前 receiver 后返回自身指针；不要在 service/capability/handler 中写散落的 `strings.TrimSpace(req.Xxx)`。
	- `Normalize()` 不要新建 `normalized := *r` 这类副本；nil receiver 直接返回 nil。示例：`func (r *ChatRequest) Normalize() *ChatRequest { if r == nil { return nil }; r.Message = strings.TrimSpace(r.Message); return r }`。
	- model 相关常量、枚举、默认值、字段约束放在 model 层。
- [ ] Step 5: 交付
  - 若信息不足，列出假设，不编造未知表名、枚举值、外部类型。
  - 运行 Pre-Delivery Checklist。

## Reference Loading

生成、重构或评审 model 层代码时，必须加载 `references/go-model-conventions.md`。

## Pre-Delivery Checklist

- [ ] 已说明模型层级和字段生命周期。
- [ ] param、model 常量、校验、序列化、反序列化等强关联能力都在 model 层。
- [ ] 请求/参数 struct 的 `Normalize()` 是 receiver 方法，直接规整当前对象并返回自身，没有创建规整副本。
- [ ] model 层只依赖标准库、外部基础库和项目 utils；不依赖 API/service/DAL 等业务层。
- [ ] 落库字段没有使用 JSON/JSONB、数组、map、复杂对象等数据库复杂类型。
- [ ] 复杂结构已用 `ConfigJSON string` 这类文本列配合 `Serialize()` / `Deserialize()`，或按查询/更新/约束需求拆列/拆表。
- [ ] 每个落库实体都有 `TableName()`；运行时字段有 `gorm:"-"`；序列化文本字段有 `json:"-"`。
- [ ] 没有新增 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型。
- [ ] 二值状态字段是 `string`，取值约定为 `"true"` / `"false"`。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
