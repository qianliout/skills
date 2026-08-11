# Go Query DAL

DAL 只做持久化。禁止业务规则、跨资源聚合、响应组装、业务日志、字段清洗/默认值/归一化/领域校验。一个方法只围绕一个主要 data model，只返回该表 model。下列示例即合法形态；禁止偏离示例顺序与形状。

## 结构

- 必须位于 `store`；接口 `XxxDal`，实现 `XxxDao`，构造 `NewXxxDao(db *databases.RDBInstance) *XxxDao` 或项目既有等价入口。
- 方法必须指针 receiver `dal`。禁止值 receiver，禁止混用 `dao`/`d`。
- 依赖必须 struct 字段注入；字段/构造参数顺序：DB/事务入口 → 关联 DAO → 外部 client/无状态依赖 → logger。
- 构造与测试装配必须保证长期依赖非 nil。禁止方法内 nil 判断或因 nil 跳过逻辑。禁止在 CRUD 内构造 DB/client/DAO/service。禁止 DAL 创建 service。
- 请求级 query builder、timeout、结果 slice、updater map 必须方法内创建。Param/filter/sort/pagination 必须在 model 同层。
- 新表时间字段必须 `int64` 毫秒；既有表保持既有单位，迁移后才可变更。
- 禁止 DAO 上任何 helper/私有拆分方法（含 `buildXxxWhere`/`countXxx`/`findXxx`/`createXxxDBVersion` 等）。一个公开 DAL 方法必须在方法体内写完全部执行逻辑，阅读该方法即可看到完整流程。派生持久化副作用必须内联在同一方法内，或做成独立公开 DAL 方法由 service 编排；禁止抽到私有方法。

## 签名与命名

既有非标准公开签名必须原样保留；仅用户明确要求时才能改形。新增必须：

```go
CreateXxx(ctx context.Context, data *model.Xxx) error
SearchXxx(ctx context.Context, param *model.SearchXxxParam) ([]*model.Xxx, int64, error)
UpdateXxx(ctx context.Context, id int64, data *model.Xxx) error
DeleteXxx(ctx context.Context, id int64) error
```

- 查询必须 `SearchXxx`。禁止 `FindXxx`/`GetXxx`/场景化后缀（`ForUser`/`ForProject` 等）。按 ID 取数必须 `SearchXxx` + 类型化 ID 条件；过滤必须进 typed param。
- 带 `Serialize`/`Check` 的 param/data 必须指针。跨 model 字段禁止裸 `ID`/`Type`/`Name`/`Keyword`，必须语义名（`ProjectID` 等）。

## 超时与表名

- 每个 DB 方法必须 `context.WithTimeout` + `dal.db.Get().WithContext(cancelCtx).Table(tb)`。
- timeout：`Create` 10s；普通 `Search`/`Update`/`Delete` 3s；小型全表参考 `Search` 10s。
- 表名必须主要 model `TableName()`。禁止硬编码。禁止返回原始 row、混合表 struct、业务 response。

## Search

GORM 必须逐步赋值。禁止长链。禁止 `Count` 前 `Select`。禁止 DAL 直接 `Order`/`Limit`/`Offset` 或自选默认排序。禁止 `Normalize`/`FillDefault`/lowercase/`NormalizeSearchXxxParam`。既有 `Filed` 拼写必须保留。状态条件必须 `"true"`/`"false"`，禁止 `bool`。成功与出错都必须返回非 nil 空 slice。Where/`Count`/`Select`/`AddFilter`/`Find`/`Deserialize` 必须留在本方法内，禁止外提。

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

`Update`/`Delete` 的 id 必须为正。`Update` 必须 `Updates(data.ToUpdater())`，禁止存完整 struct。不可变字段、权限、所有权、状态机、删除许可必须在调用 DAL 前由 model/service 处理。禁止 `return db.Xxx(...).Error`；一切 DB 调用必须先取 `err`，再 `if err != nil { return err }`，成功路径显式 `return nil`。

```go
func (dal *XxxDao) CreateXxx(ctx context.Context, data *model.Xxx) error {
	data = data.Serialize()
	if err := data.Check(); err != nil {
		return err
	}
	cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*10)
	defer cancelFunc()
	db := dal.db.Get().WithContext(cancelCtx).Table(data.TableName())
	if err := db.Create(data).Error; err != nil {
		return err
	}
	return nil
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
	db := dal.db.Get().WithContext(cancelCtx).Table(data.TableName())
	db = db.Where("id = ?", id)
	if err := db.Updates(data.ToUpdater()).Error; err != nil {
		return err
	}
	return nil
}

func (dal *XxxDao) DeleteXxx(ctx context.Context, id int64) error {
	if id <= 0 {
		return fmt.Errorf("id must be positive")
	}
	cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*3)
	defer cancelFunc()
	db := dal.db.Get().WithContext(cancelCtx).Table((&model.Xxx{}).TableName())
	db = db.Where("id = ?", id)
	if err := db.Delete(&model.Xxx{}).Error; err != nil {
		return err
	}
	return nil
}
```

## 跨表与 SQL

- 跨表过滤必须 `IN (subquery)` 或 `EXISTS`。仅子查询无法表达且项目既有模式要求时才可 `Join`，并必须写明原因。多主要实体操作必须移至 service。
- 条件只允许相等、范围、`IN`。禁止 window/CTE/复杂子查询/专有函数/JSON·array/全文/自定义 SQL 函数；无法避免时必须说明必要性、兼容性、替代方案、目标库。
- 禁止索引列上计算/函数/类型转换（`DATE`/`LOWER`/`CAST`/`amount+fee` 等）；无法避免时必须说明索引影响、数据量假设，以及未用归一化列/生成列/表达式索引/param 转换的原因。
