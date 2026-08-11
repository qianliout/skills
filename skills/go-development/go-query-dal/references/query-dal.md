# Go Query DAL

DAL 只做持久化访问。禁止业务规则、跨资源业务聚合、响应组装、业务日志、字段清洗、默认值、归一化或领域校验。一个 DAL 方法只围绕一个主要 data model，并只返回该表 model。

## 结构与依赖

- DAL/DAO 必须位于项目 `store` 目录/package。
- 接口必须为窄接口 `XxxDal`；实现必须为 `XxxDao`；构造函数必须为 `NewXxxDao(db *databases.RDBInstance) *XxxDao` 或项目既有等价入口。
- 全部方法必须使用指针 receiver `dal`。禁止值 receiver，禁止混用 `dao`、`d`。
- 依赖必须为 struct 字段，在构造函数或 bootstrap 注入。禁止在 `Create`/`Search`/`Update`/`Delete` 内构造 DB、client、DAO 或 service。
- 字段与构造参数顺序必须为：DB/事务入口 → 关联 DAO/repository → 外部持久化 client 或无状态 helper → logger。
- 构造、bootstrap、测试装配必须保证长期依赖非 nil。禁止在方法内对 `dal`、`dal.db` 或其他长期依赖做 nil 判断或因 nil 跳过逻辑。
- 请求级 query builder、timeout context、结果 slice、updater map 必须在方法内创建。
- DAL 禁止创建 service。多 store 业务决策或多主要实体聚合必须移至 service，并调用独立 DAL 方法。
- Param、filter、sort、pagination struct 必须定义在 model 同层，禁止定义在 DAL package。
- 新建表的过滤/写入/更新/读取时间字段必须使用 `int64` 毫秒。既有表必须保持既有时间单位，迁移后才可变更。

## 方法签名与命名

新增公开 CRUD 必须使用下列签名；既有非标准公开签名必须原样保留，只有用户明确要求时才能改形。

```go
CreateXxx(ctx context.Context, data *model.Xxx) error
SearchXxx(ctx context.Context, param *model.SearchXxxParam) ([]*model.Xxx, int64, error)
UpdateXxx(ctx context.Context, id int64, data *model.Xxx) error
DeleteXxx(ctx context.Context, id int64) error
```

- `SearchXxx` 输入只能是 `ctx` 与指针 `param`；输出必须是结果 slice、总数、error。
- `CreateXxx` 输入只能是 `ctx` 与 data 指针。
- `UpdateXxx` 输入只能是 `ctx`、主键 ID、data 指针。
- `DeleteXxx` 输入只能是 `ctx` 与主键 ID。
- 查询方法必须命名 `SearchXxx`。禁止新增 `FindXxx`、`GetXxx`、`SearchXxxForUser`、`SearchXxxForProject`、`UpdateXxxForUser`、`UpdateXxxForProject` 等调用方/所有者/租户/项目场景化方法。按 ID 取数必须走 `SearchXxx` + 类型化 ID 条件。
- 调用方、所有者、租户、项目、状态、权限过滤必须写入 typed model param。
- 带 `Serialize()`/`Check()` 的 param 与 data 必须使用指针。
- 跨 model 查询字段禁止使用含义不明的 `ID`、`Type`、`Name`、`Keyword`；必须使用 `ProjectID`、`UserID`、`PolicyID`、`RelatedName` 等语义名。单一明确 model 字段可使用 `Status` 等直接名称。

## DB 超时与表名

- 每个 DB 方法必须创建 timeout context，全部 DB 操作必须使用 `dal.db.Get().WithContext(cancelCtx).Table(tb)`。
- `Create` timeout 必须为 10 秒；普通分页 `Search`/`Update`/`Delete` 必须为 3 秒；显式需要的小型全表参考数据 `Search` 必须为 10 秒。
- 表名必须来自主要 model 的 `TableName()`。禁止硬编码表名，禁止用其他 model 表作主入口。
- 禁止返回原始 DB row、混合表 struct 或业务组装 response。

```go
cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*3)
defer cancelFunc()
```

## Search 流水线

`SearchXxx` 必须在同一方法内按下列顺序完成，禁止调换：

1. 初始化结果 slice（成功与出错路径都必须返回非 nil 空 slice，禁止返回 nil slice）
1. `param = param.Serialize()`，再 `param.Check()`
1. 创建 timeout context
1. `Table(主要 model.TableName())`
1. 按 param 非零字段追加 `Where`（零值表示查全部或特殊语义时，该分支必须有短注释）
1. `Count`
1. 若 `param.Filed` 非空：`db = db.Select(param.Filed)`（既有 `Filed` 拼写必须保留；禁止在 `Count` 前 `Select`）
1. `db = model.AddFilter(db, param.Filter)`（排序与分页只能经此进入；禁止 DAL 直接 `Order`/`Limit`/`Offset`，禁止自选默认排序，禁止本地替代 helper）
1. `Find`
1. 对每行 `Deserialize()`，返回

GORM query 必须逐步赋值（`db = db.Where(...)`）。禁止长链调用。禁止在 DAL 定义 `Normalize()`、`FillDefault()`、lowercase 或 `NormalizeSearchXxxParam`。状态条件必须使用字符串 `"true"`/`"false"`，禁止改成 `bool`。

```go
func (dal *XxxDao) SearchXxx(ctx context.Context, param *model.SearchXxxParam) ([]*model.Xxx, int64, error) {
	result := make([]*model.Xxx, 0)
	param = param.Serialize()
	if err := param.Check(); err != nil {
		return result, 0, err
	}

	cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*3)
	defer cancelFunc()

	tb := (&model.Xxx{}).TableName()
	db := dal.db.Get().WithContext(cancelCtx).Table(tb)

	if param.ProjectID > 0 {
		db = db.Where("project_id = ?", param.ProjectID)
	}
	// empty Status means all
	if param.Status != "" {
		db = db.Where("status = ?", param.Status)
	}

	var total int64
	if err := db.Count(&total).Error; err != nil {
		return result, 0, err
	}

	if len(param.Filed) > 0 {
		db = db.Select(param.Filed)
	}
	db = model.AddFilter(db, param.Filter)

	rows := make([]*model.Xxx, 0)
	if err := db.Find(&rows).Error; err != nil {
		return result, 0, err
	}
	for _, row := range rows {
		result = append(result, row.Deserialize())
	}
	return result, total, nil
}
```

## Create / Update / Delete

生命周期调用必须且只能为：

| 方法 | 必须调用 |
|------|----------|
| `CreateXxx` | data：`Serialize`、`Check`、`TableName` |
| `SearchXxx` | param：`Serialize`、`Check`；主要 model：`TableName`；每行：`Deserialize` |
| `UpdateXxx` | data：`Serialize`、`Check`、`ToUpdater`、`TableName` |
| `DeleteXxx` | 主要 model：`TableName` |

禁止在 DAL 重复实现 trim、ID 归一化、默认值、派生字段、lowercase、字段清洗或领域校验。不可变字段、默认记录、权限、所有权、状态机与删除许可必须由 model 或 service 在调用 DAL 前处理。

```go
func (dal *XxxDao) CreateXxx(ctx context.Context, data *model.Xxx) error {
	data = data.Serialize()
	if err := data.Check(); err != nil {
		return err
	}
	cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*10)
	defer cancelFunc()
	tb := data.TableName()
	db := dal.db.Get().WithContext(cancelCtx).Table(tb)
	return db.Create(data).Error
}

func (dal *XxxDao) UpdateXxx(ctx context.Context, id int64, data *model.Xxx) error {
	if id <= 0 {
		return fmt.Errorf("id must be positive")
	}
	data = data.Serialize()
	if err := data.Check(); err != nil {
		return err
	}
	cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*3)
	defer cancelFunc()
	tb := data.TableName()
	db := dal.db.Get().WithContext(cancelCtx).Table(tb)
	db = db.Where("id = ?", id)
	return db.Updates(data.ToUpdater()).Error
}

func (dal *XxxDao) DeleteXxx(ctx context.Context, id int64) error {
	if id <= 0 {
		return fmt.Errorf("id must be positive")
	}
	cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*3)
	defer cancelFunc()
	tb := (&model.Xxx{}).TableName()
	db := dal.db.Get().WithContext(cancelCtx).Table(tb)
	db = db.Where("id = ?", id)
	return db.Delete(&model.Xxx{}).Error
}
```

`UpdateXxx` 必须用 `Updates(data.ToUpdater())`，禁止保存完整 struct。

## 跨表与 SQL

- 跨表过滤必须使用 `WHERE ... IN (subquery)` 或 `EXISTS (subquery)`。仅当子查询无法表达且项目既有模式要求时才可 `Join`，并必须写明原因。
- 复杂跨 model 聚合、业务决策或多主要实体操作必须移至 service。
- 查询必须使用相等、范围、`IN`。禁止 window function、CTE、复杂子查询、数据库专有函数、JSON/array 操作、全文检索语法与自定义 SQL 函数；无法避免时必须说明必要性、兼容性影响、替代方案与目标数据库。
- 禁止在索引列条件中使用计算、SQL 函数或类型转换（如 `DATE(created_at)`、`LOWER(name)`、`CAST(id AS text)`、`amount + fee`）；无法避免时必须说明索引影响、数据量假设，以及未使用归一化字段、生成列、表达式索引或 param 转换的原因。

## 私有维护 helper

- 缓存或版本记录等派生持久化副作用必须使用私有 lower camel case helper（如 `createXxxDBVersion`）。
- helper 必须复用既有 DAL `Search`，并显式构建 update map。
- 每个 helper DB 写入必须创建新的 timeout context。
- helper error 阻断主操作时必须返回 error；不阻断时必须写成 `_ = helper(ctx)`。
- 正常 `Search` 流水线必须留在一个方法内。禁止拆成只包装一两个 GORM 调用的 `buildXxxWhere`/`countXxx`/`findXxx`。仅当片段以相同语义复用，或独立出真实维护副作用时才可提取。

## 验证

- DAL 禁止记录业务日志。
- 修改 Go 文件后必须 `goimport`。
- 可定位包或测试时必须跑最小范围 `go test`。
