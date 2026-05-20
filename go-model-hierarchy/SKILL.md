---
name: go-model-hierarchy
description: "通用 Go 数据 model 层级定义专家，生成、重构、评审领域模型和数据模型。Use when user asks 定义数据模型、model 层级、领域模型、Go struct、GORM model、JSON tag、DTO/VO/Entity、Serialize/Deserialize、Check 校验、TableName、UniqueID、派生字段、缓存模型、统计模型、查询参数、更新参数、视图模型。Actions: design, create, refactor, review, define data model hierarchy."
---

# Go Model Hierarchy

核心约束：先定义模型层级和字段生命周期，再写 struct；不要把数据库字段、接口字段、运行时派生字段混在一起却不说明边界。

PostgreSQL 约束：不要在 model 中使用 `uint64`。PostgreSQL 没有原生 `uint64`，持久化 ID 默认用 `int64` 对应 `bigint`。model 中不允许设计比 `int64` 更大的数值类型；外部超大标识、无符号哈希、雪花 ID 只能作为不参与数值运算的 `string` 标识存储和传输。

布尔值约束：不要在 model 中使用 `bool`。二值状态统一使用字符串 `"true"` / `"false"`，字段类型为 `string`，便于 API、查询参数、数据库存储和三态扩展保持一致。

## Workflow

- [ ] Step 1: 识别模型职责 ⚠️ REQUIRED
  - [ ] 判断目标是实体模型、查询参数、统计视图、缓存载体、策略检测结果，还是辅助值对象。
  - [ ] 标出哪些字段来自 DB，哪些字段来自 API，哪些字段仅运行时使用。
- [ ] Step 2: 建立层级
  - [ ] 先给出模型树，再给出每个 struct。
  - [ ] 实体模型放在最上层，派生/视图/统计/缓存模型跟随其后。
  - [ ] 对跨层关系写清楚：聚合、引用、序列化嵌入、运行时填充。
- [ ] Step 3: 定义字段契约 ⚠️ REQUIRED
  - [ ] 为持久化字段添加 `gorm:"column:..."` 或主键/时间戳 tag。
  - [ ] 为接口字段添加稳定 `json:"..."` tag。
  - [ ] 禁止使用 `uint64`；数据库 ID、业务 ID、计数字段优先用 `int64`。
  - [ ] `int64` 字段返回前端时保持 JSON 数值类型，不要使用 `json:",string"`。
  - [ ] 禁止使用比 `int64` 更大的数值类型，包括 `big.Int`、`uint64`、`uint`、自定义大整数数值类型。
  - [ ] 外部超大 ID、哈希、雪花 ID 使用 `string`，并明确它是标识，不是数值字段。
  - [ ] 禁止使用 `bool`；启用/禁用、是否默认、是否删除等二值状态使用 `string`，取值 `"true"` / `"false"`。
  - [ ] 对运行时字段使用 `gorm:"-"`，对落库 JSON 原文使用 `json:"-"`。
- [ ] Step 4: 补齐模型行为
  - [ ] 实体模型需要 `Serialize()`、`Deserialize()`、`Check()`、`TableName()`。
  - [ ] 有唯一标识的模型需要 `GenUniqueID()` 或明确唯一键组成。
  - [ ] 有派生字段的模型需要在 `Serialize()` 中集中生成。
  - [ ] 有深拷贝需求的聚合/统计模型提供 `DeepCopy()`。
- [ ] Step 5: 输出结果
  - [ ] 先输出层级说明，再输出 Go 代码。
  - [ ] 若信息不足，列出假设；不要编造未知表名、枚举值、外部类型。
  - [ ] 交付前运行 Pre-Delivery Checklist。

## Reference Loading

需要从样本文件抽象通用约定时，加载 `references/go-model-conventions.md`。

## Required Patterns

实体模型字段分组顺序：

1. 主键和唯一标识：`ID`、`UniqueID`。
2. JSON 落库字段和运行时字段成对出现：`ConfigJSON` + `Config`，`DetailJSON` + `Detail`。
3. 审计时间：`CreatedAt`、`UpdatedAt`，毫秒时间戳。

类型选择：

- `ID int64`: 自增主键，PostgreSQL `bigint`。
- `UniqueID int64`: 可落库的业务唯一 ID，值域必须确认不超过 `int64`。
- `UniqueID string`: 哈希、雪花、外部系统 ID、无符号数迁移字段；它是 opaque 标识，不是数值类型。
- `Count int64`: 计数、统计、毫秒时间戳等数值字段。
- `Flag int64`: 状态位字段；如果需要超过 63 个 bit，改用 `string`、`[]string` 或独立关系表。
- `Enable string`: 二值状态字段，取值只允许 `"true"` / `"false"`，不要使用 `bool`。
- `IsDefault string`: `is_*` 语义字段也使用字符串二值，不要使用 `bool`。

方法职责：

- `Serialize()`: 归一化输入，入库前执行。
- `Deserialize()`: 从 JSON 落库字段恢复运行时字段，修正兼容逻辑和历史数据等，出库后执行。
- `Check()`: 只检查必要信息是否完整
- `TableName()`: 返回固定表名，不从外部输入拼接。
- `ToUpdater()`: 只返回允许更新的列，更新时间使用 `time.Now().UTC().UnixMilli()`。
- `Same(after T)`: 检查两条数据内容是否相同

## Output Format


## Anti-Patterns

- 不要只给 struct，不解释层级和字段生命周期。
- 不要让同一个字段既落库又标 `gorm:"-"`。
- 不要把 `json:"-"` 的落库 JSON 字段直接暴露给前端。
- 不要在 DAO 层临时生成 `UniqueID`、`Flag`、展示名、checksum 等 model 派生字段。
- 不要用字符串拼接模拟 JSON 序列化；使用 `json.Marshal` / `json.Unmarshal`。
- 不要使用 `uint64`、`uint` 作为持久化 model 字段；PostgreSQL 不支持原生无符号 64 位整数。
- 不要使用比 `int64` 更大的数值类型，包括 `big.Int`、`uint64`、`uint`、自定义大整数类型。
- 不要把外部超大 ID 当作数值字段；它只能是 `string` 标识，不允许参与大小比较、加减乘除或数值范围查询。
- 不要给 `int64` 字段添加 `json:",string"`；`int64` 对外仍是 JSON 数值。
- 不要使用 `bool` 作为 model 字段；二值状态使用 `"true"` / `"false"` 字符串。
- 不要混用 `true` 布尔字面量和 `"true"` 字符串；model 层统一字符串取值。
- 不要改变已有 JSON tag 的大小写风格，尤其是前端已依赖的字段。

## Pre-Delivery Checklist

- [ ] 每个落库实体都有 `TableName()`。
- [ ] 每个运行时字段都有 `gorm:"-"`。
- [ ] 每个 JSON 落库原文字段都有 `json:"-"`。
- [ ] `Serialize()` 和 `Deserialize()` 成对处理 JSON 字段。
- [ ] `Check()` 覆盖类型枚举和上下文相关必填 ID。
- [ ] 没有任何新增 `uint64` 或 `uint` model 字段。
- [ ] 没有任何比 `int64` 更大的数值类型，如 `big.Int`、decimal 大整数、自定义大整数。
- [ ] 没有任何新增 `bool` model 字段。
- [ ] 二值状态字段类型为 `string`，取值约定为 `"true"` / `"false"`。
- [ ] `int64` 字段的 JSON tag 没有使用 `,string`。
- [ ] 外部超大 ID、哈希、雪花 ID 使用 `string`，并且没有作为数值参与运算。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
