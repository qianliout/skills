# Go Model Hierarchy

Model 层拥有字段契约与生命周期。下列示例即合法形态；禁止偏离示例顺序与形状。model 定义方法；API/DAL/service 按调用归属表编排调用，禁止把实现挪进 handler 或 DAL。

## 边界与模型树

- 禁止依赖 API、service、DAL、DB 会话、HTTP request/context、handler。只允许：标准库、项目 `utils`、`time`、GORM tag 所需包。
- 禁止业务日志；例外仅当用户书面确认且原因写入变更说明。日志归 `$go-code-style`。
- 枚举/默认值/字段约束/常量必须进 `consts`，禁止散落各层或函数体。
- 字段生命周期归属拥有字段的 model。
- 写 struct 前固定顺序：列资源 → 持久化实体 → 写入口 Param → 读出口 Response/View → Cache/Statistic → 跨实体值对象（单独成节）。

## 类型与方法闭集

- 一旦提供某生命周期方法，签名/receiver/职责必须符合下文与示例。
- 持久化实体（有 `TableName()`）：必须 `Serialize`、`Deserialize`、`Check`；仅当存在全量更新写库路径时才提供 `ToUpdater`；仅当存在「相等则跳过写库」时才提供 `Same`。只做局部更新的实体禁止为对称而补空/半全量 `ToUpdater`。
- Param：必须 `Serialize`、`Check`；禁止 `ToUpdater`；无存储读取兼容则禁止 `Deserialize`。
- Response/View/Cache/Statistic/值对象：禁止生命周期方法；含须 trim/填默认/枚举校验的自有字段时只允许对应 `Serialize`/`Check`。禁止空壳方法。

## 生命周期契约

签名：`Serialize() *T`、`Deserialize() *T`、`ToUpdater() map[string]any`、`Check() error`、`Same(after *T) bool`。

- 五方法禁止互相调用。指针 receiver；Param 用 `p`，其余用 `vi`。
- `Serialize`/`Deserialize`：返回 receiver；nil 分配新对象，非 nil 原地改；调用方必须 `obj = obj.Serialize()`。
- `Serialize` 只做写入前规整（trim/默认值/派生/文本序列化/显示搜索字段/UniqueID/校验和）；slice/map 的 nil 必须收成 empty。禁止旧数据兼容。
- 禁止写 `Normalize`/`FillDefault`/`GenUniqueID`/`GenUUID`/`GenCheckSum` 及同职责私有 helper。
- `Deserialize` 只做存储读取兼容（旧枚举/秒→毫秒/历史默认/文本列还原）。
- `Check` 拒 nil；只校验不改写。只校验实际存在的身份（type/name/code/version）、范围（tenant/project/parent）、状态（`consts.TrueString`/`consts.FalseString`）、外部引用字段。
- `ToUpdater` 只服务全量更新：已初始化 map，显式列全量可更新列 + `updated_at: time.Now().UTC().UnixMilli()`；零值有效禁止跳过。禁止 `id`/`created_at`/主身份/`UniqueID`/checksum/派生列；禁止反射整 struct。禁止只列部分列、禁止按零值/参数条件增删 key——需要局部更新时由 service 自行组装 updater map 交给 DAL，不得让 `ToUpdater` 变成可变形状。
- model 禁止提供局部 updater 的组装方法（`ToStatusUpdater`/`ToUpdaterWith(fields)`/`PatchMap` 等）。
- `Same` 只比业务可变字段；禁止比 `ID`/`CreatedAt`/`UpdatedAt`/`DeletedAt`/`UniqueID`等。
- 返回 slice/map 的方法全路径非 nil 空集合。生命周期必须在一个公有方法内完成；工具函数仅当无 model 字段名/业务常量、本包或 `utils`≥2 处复用、且不读写 receiver。
- `TableName()` 返回字面量表名。

## 字段与标识

- `json` 禁止 `omitempty`；显式名或 `json:"-"`。JSON tag 字段名默认统一小驼峰（camelCase，如 `projectId`、`uniqueId`），项目已有明确命名约定时遵循项目约定。普通字段 `gorm` 只能 `column:...`。基础四字段 tag 以示例为准，禁止改写（唯一例外可含 `primaryKey`/`autoCreateTime:milli`/`autoUpdateTime:milli`）。
- 运行时字段 `gorm:"-"`。禁止 JSON/JSONB/数组/map/对象列；复杂结构用文本双字段（运行时 `gorm:"-"` + `string` backing `json:"-"`）或拆列/关联表。
- 数值与时间必须 `int64` 毫秒；`time.Now().UTC().UnixMilli()`。旧秒级只在 `Deserialize` 转毫秒。禁止 `uint`/`uint64`/超 `int64`/`big.Int`/decimal；超范围标识用 `string`。
- 业务身份：`UniqueID int64`；禁止 `DataID`/`UID`，除非仓库已有契约或用户明确要求。业务键=范围 ID + 稳定 name/code + 资源 type；禁止随机/请求时刻/进程态。不生成则类型上方 `// UniqueID: not generated because ...`。
- 禁止字段类型 `bool`；方法返回 `bool` 允许。二元状态字段类型为 `string`，取值必须是 `consts.TrueString`/`consts.FalseString`；`Serialize`/`Check` 禁止写 `"true"`/`"false"` 字面量。枚举/状态用基础类型 + `consts`；禁止无外部契约时新建命名包装类型。

## 调用归属

| 对象与动作 | 必须调用方 | 禁止 |
| --- | --- | --- |
| 入站 Param `Serialize`/`Check` | API handler（调 service 前） | 下游对同一 param 再调 |
| 写入实体 `Serialize`/`Check` | DAL（写库前） | service/API 对同一 data 再调 |
| 读出 `Deserialize` | DAL（`Find` 后逐行） | service/API 再调 |
| `ToUpdater`（仅全量更新） | DAL `Updates` | service/API |
| 局部更新 updater `map[string]any` | service 在调用点写 map 字面量，DAL 直接 `Updates` | model 提供组装方法；DAL 补列或清洗 |
| `Same` | service（且仅「相等则跳过写库」） | 被其他生命周期调用 |

禁止对同一对象重复 `Check()`。API/service/DAL 禁止重复实现 model 已有规整/校验/序列化逻辑。

## 合法示例

```go
type ResourceConfig struct {
	TimeoutMS int64 `json:"timeoutMs"`
}

type Resource struct {
	ID         int64          `gorm:"primaryKey;column:id" json:"id"`

	ProjectID  int64          `gorm:"column:project_id" json:"projectId"`
	Name       string         `gorm:"column:name" json:"name"`
	Status     string         `gorm:"column:status" json:"status"`
	UniqueID   int64          `gorm:"column:unique_id" json:"uniqueId"`
	Config     ResourceConfig `gorm:"-" json:"config"`
	ConfigJSON string         `gorm:"column:config" json:"-"`

	CreatedAt  int64          `gorm:"autoCreateTime:milli;column:created_at" json:"createdAt"`
	UpdatedAt  int64          `gorm:"autoUpdateTime:milli;column:updated_at" json:"updatedAt"`
	DeletedAt  int64          `gorm:"column:deleted_at" json:"deletedAt"`
}

func (vi *Resource) TableName() string { return "app_resource" }

func (vi *Resource) Serialize() *Resource {
	if vi == nil {
		return &Resource{}
	}
	vi.Name = strings.TrimSpace(vi.Name)
	if vi.Status == "" {
		vi.Status = consts.FalseString
	}
	vi.UniqueID = utils.StableUniqueID(vi.ProjectID, vi.Name, "resource")
	b, _ := json.Marshal(vi.Config)
	vi.ConfigJSON = string(b)
	return vi
}

func (vi *Resource) Deserialize() *Resource {
	if vi == nil {
		return &Resource{}
	}
	// UpdatedAt/DeletedAt: same second→milli rule
	if vi.CreatedAt > 0 && vi.CreatedAt < 1_000_000_000_000 {
		vi.CreatedAt *= 1000
	}
	if vi.ConfigJSON != "" {
		_ = json.Unmarshal([]byte(vi.ConfigJSON), &vi.Config)
	}
	return vi
}

func (vi *Resource) Check() error {
	if vi == nil {
		return fmt.Errorf("resource is nil")
	}
	if vi.ProjectID <= 0 {
		return fmt.Errorf("projectID must be positive")
	}
	if vi.Name == "" {
		return fmt.Errorf("name is required")
	}
	if vi.Status != consts.TrueString && vi.Status != consts.FalseString {
		return fmt.Errorf("status must be true or false")
	}
	return nil
}

// ToUpdater exists only because Resource has a full-update path, and its shape is fixed:
// every updatable column, always. Partial updates use a service-assembled map instead.
func (vi *Resource) ToUpdater() map[string]any {
	return map[string]any{
		"project_id": vi.ProjectID,
		"name":       vi.Name,
		"status":     vi.Status,
		"config":     vi.ConfigJSON,
		"updated_at": time.Now().UTC().UnixMilli(),
	}
}

func (vi *Resource) Same(after *Resource) bool {
	if vi == nil || after == nil {
		return false
	}
	return vi.ProjectID == after.ProjectID &&
		vi.Name == after.Name &&
		vi.Status == after.Status &&
		vi.ConfigJSON == after.ConfigJSON
}

// Param: Serialize/Check required; receiver p; same shape as entity methods; no ToUpdater.
type CreateResourceParam struct {
	ProjectID int64  `json:"projectId"`
	Name      string `json:"name"`
	Status    string `json:"status"`
}
```
