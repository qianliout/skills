# Go Model Hierarchy

Model 层负责实体、param、response/view、cache、statistic 与值对象的字段契约和完整生命周期：校验、序列化、反序列化、派生字段与更新字段选择。先定义模型树，再定义 struct；实体优先，其他模型跟随实体或业务域。

## 层级与依赖边界

- Model 禁止依赖 API、service、DAL、DB 会话、HTTP request/context 或框架 handler 类型。
- Model 只依赖标准库、基础第三方库和项目 `utils`；需要 service、DAL、请求上下文或框架类型的逻辑禁止放入 model。
- Model 默认禁止记录业务日志；日志所有权遵循 `$go-code-style`。
- Model 相关枚举、默认值、字段约束和常量必须放入项目 `consts` 目录，禁止散落在 model、API、service、DAL、helper 或函数体中。
- Param、校验、序列化、反序列化、派生字段、规整、默认值和更新字段选择必须归属拥有字段的 model。

## 生命周期方法

生命周期方法必须为公开方法并使用以下固定签名：

```go
func (vi *Xxx) Serialize() *Xxx
func (vi *Xxx) Deserialize() *Xxx
func (vi *Xxx) ToUpdater() map[string]any
func (vi *Xxx) Check() error
func (vi *Xxx) Same(after *Xxx) bool
```

- `Serialize()`、`Deserialize()`、`ToUpdater()`、`Check()`、`Same()` 禁止互相调用。调用顺序完全由 API、service 或 DAL 外部调用方决定。
- `Serialize()` 与 `Deserialize()` 必须返回 receiver。nil receiver 必须分配并返回新对象；非 nil receiver 必须原地修改并返回自身。调用方必须接收返回值，例如 `data = data.Serialize()`。
- `Check()` 必须拒绝 nil receiver，且只验证字段；禁止规整、填默认值、派生字段、修改数据或调用其他生命周期方法。
- `Serialize()` 只负责写入前字段规整：trim、默认值、派生字段、文本序列化、显示/搜索字段、唯一标识和校验和；禁止处理旧枚举、旧时间单位、历史默认值或其他存储读取兼容。禁止新增 `Normalize()`、`FillDefault()`、`GenUniqueID()`、`GenUUID()`、`GenCheckSum()` 或同职责私有 helper。
- `Deserialize()` 专属存储读取兼容：旧枚举规整、秒级时间转毫秒、历史默认值补齐和文本列还原运行时字段。任何旧数据修正必须在拥有字段的 `Deserialize()` 中完成。
- `ToUpdater()` 必须返回已初始化的 `map[string]any`，显式列出全部允许更新的列，并写入 `updated_at: time.Now().UTC().UnixMilli()`。
- `Same()` 只比较字段，不校验、不规整、不序列化、不生成 updater。
- 返回 slice 或 map 的任意 model 方法必须在所有路径返回已初始化的空值，禁止返回 nil。

## Receiver 与方法组织

- 所有 model、param、response、view、cache、statistic 和值对象方法必须使用指针 receiver，包括 `TableName()`、`LogStr()` 等只读方法。
- 类型名含 `Param` 的 receiver 名必须为 `p`；其他 model 层对象 receiver 名必须为 `vi`。同一类型禁止混用 receiver 形式或名称。
- 一项结构体字段生命周期必须在一个公有方法内自上而下完成；禁止拆成 `normalizeXxx`、`checkXxx`、`sameXxx`、`buildUpdater` 等私有 helper。
- 仅真正通用、无字段所有者且可复用的逻辑允许提取为工具函数。
- `TableName()` 必须返回字面量表名。

```go
func (vi *Resource) TableName() string {
	return "app_resource"
}
```

## 字段、tag 与存储

- 任意 `json` tag 禁止使用 `omitempty`。必须使用显式字段名或 `json:"-"`；零值必须按字段契约输出，缺失语义必须由指针或 nullable 字段表达。
- 普通持久化字段的 `gorm` tag 只能声明 `column:...`；禁止写 `type`、`index`、`uniqueIndex`、`default`、`not null`、迁移或索引选项。
- 运行时字段必须使用 `gorm:"-"`。
- 持久化字段禁止使用 JSON/JSONB、数组、map 或对象列；必须使用兼容的有符号整数、string/text 或状态字符串。
- 复杂运行时结构存一个文本列时，运行时对象必须 `gorm:"-"`，文本 backing field 必须是 `string`、`gorm:"column:..."` 且 `json:"-"`；`Serialize()` 负责写入文本，`Deserialize()` 负责恢复对象。

```go
Config     Config `gorm:"-" json:"config"`
ConfigJSON string `gorm:"column:config" json:"-"`
```

- 需要筛选、索引、部分更新或数据库约束的复杂结构必须拆为普通列或关联表，禁止塞入文本或数据库复杂类型。

## 基础字段、标识与类型

每个持久化 model 必须包含以下基础字段，tag 形状不得修改：

```go
ID        int64 `gorm:"primaryKey;column:id" json:"id"`
CreatedAt int64 `gorm:"autoCreateTime:milli;column:created_at" json:"createdAt"`
UpdatedAt int64 `gorm:"autoUpdateTime:milli;column:updated_at" json:"updatedAt"`
DeletedAt int64 `gorm:"column:deleted_at" json:"deletedAt"`
```

- `ID` 必须为 `int64` 主键；`CreatedAt`、`UpdatedAt`、`DeletedAt` 必须为毫秒级 `int64` 时间戳。
- 新表、新功能及跨层时间字段必须使用毫秒；当前时间必须使用 `time.Now().UTC().UnixMilli()`。既有功能禁止在未明确迁移要求时改变既有时间单位或存储形状。
- 读取旧秒级数据时，必须在拥有字段的 `Deserialize()` 中转换为毫秒。
- 默认数值类型必须为 `int64`，覆盖 ID、时间、计数、分页、cache/statistic 与层间数值。
- 禁止使用 `uint`、`uint64`、大于 `int64` 的数值类型、`big.Int`、decimal 大整数或自定义大数类型。外部雪花、无符号 hash、超出 `int64` 或需保留字面量的标识必须为 `string`。
- 全局业务身份使用独立的 `UniqueID int64`；禁止用 `DataID` 或 `UID` 替代，除非外部兼容契约明确要求。
- 生成业务 ID 必须基于稳定业务键，同一来源类型的相同业务键必须生成相同 ID；禁止用随机值、请求时刻或进程状态作为 ID 来源。
- 租户范围资源的业务键必须包含 tenant ID、业务 code 和资源 type；父级范围资源必须包含 parent ID、name 或 code、version 和资源 type；内容寻址资源必须包含规整后的 display name、digest 或 checksum 和资源 type。
- 不生成业务 ID 的类型必须在类型定义或模型说明中写明不生成的业务原因；未说明原因禁止省略业务 ID。
- 枚举和状态默认使用基础类型字段与 `consts` 中的命名常量；禁止无外部边界时创建命名基础类型包装。
- 禁止使用 `bool` 字段。二元状态必须为 `string`，取值只能是 `"true"` 或 `"false"`；`Check()` 负责校验必填状态，`Serialize()` 负责填入默认 `"false"`。

## 校验、序列化与更新

- `Check()` 必须校验 enum/type、name/code/type/version 等身份字段，以及 tenant、project、parent、external ID 等上下文字段。
- API、service、DAL 禁止重复 model 的字段校验、规整、默认值、派生字段或复杂结构序列化。
- 调用方必须在持久化、查询或更新消费字段前执行 `Serialize()`，并在需要校验时由外部接续执行 `Check()`。
- `ToUpdater()` 必须完整覆盖契约允许更新的字段；`0`、`""`、`"false"`、空 slice 或空文本都是有效值，禁止因零值跳过。
- `ToUpdater()` 禁止写入 `id`、`created_at`、主身份字段和仅由 `Serialize()` 或持久化生命周期拥有的字段。
- `ToUpdater()` 禁止反射整个 struct 或无选择地序列化全部列。

## 交付检查

- 已确定实体、param、response/view、cache、statistic 与值对象的归属和字段生命周期。
- 已检查生命周期方法固定签名、nil receiver、指针 receiver、receiver 名称和外部组合顺序。
- 已检查所有 JSON/GORM tag、基础字段、数值、时间、状态、复杂结构和 updater 字段。
- 已确认 model 未侵入 API、service、DAL、日志或 DB 会话职责。
