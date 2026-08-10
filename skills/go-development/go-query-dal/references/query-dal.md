# Go Query DAL

DAL 只负责持久化访问。禁止承载业务规则、跨资源业务聚合、响应组装、业务日志、字段清洗、默认值、归一化或领域校验。一个 DAL 方法只能围绕一个主要 data model。

## 结构与依赖

- DAL/DAO 必须位于项目 `store` 目录/package。
- 项目定义接口时，必须定义窄接口 `XxxDal`；实现必须为 `XxxDao`；构造函数必须为 `NewXxxDao(db *databases.RDBInstance) *XxxDao` 或项目既有等价入口。
- DAO 全部实现方法必须使用指针 receiver `dal`。禁止值 receiver，禁止在同一 `XxxDao` 混用 `dao`、`d` 等 receiver。
- DAO 依赖必须声明为 struct 字段，并在构造函数或 bootstrap 注入。禁止在 `Create`、`Search`、`Update`、`Delete` 内调用 DB、client、DAO 或 service 构造函数。
- 字段与构造参数必须按 DB/事务入口、关联 DAO/repository、外部持久化 client 或无状态 helper、logger 的顺序声明。
- 构造函数、bootstrap 与测试装配必须保证长期依赖非 nil。禁止在方法内检查 `dal`、`dal.db` 或其他长期依赖是否为 nil；禁止因依赖为 nil 跳过查询、写入、更新、删除、索引维护或日志。
- 请求级 query builder、timeout context、结果 slice 与 updater map 必须在方法内创建。
- DAL 禁止创建 service。需要业务编排、多 store 业务决策或多主要实体聚合时，必须移至 service 并调用独立 DAL 方法。
- Param、filter、sort、pagination struct 必须定义在 model 同层，禁止定义在 DAL package。
- DAL 相关 model、param、result struct 的 JSON tag 禁止使用 `omitempty`。
- 新建表的 DAL 过滤、写入、更新、读取时间字段必须使用整数列中的 `int64` 毫秒时间戳。既有表必须保持既有时间单位，迁移后才可变更。

## 方法签名与命名

- 新增公开 CRUD 方法必须使用下列签名：

```go
CreateXxx(ctx context.Context, data *model.Xxx) error
SearchXxx(ctx context.Context, param *model.SearchXxxParam) ([]*model.Xxx, int64, error)
UpdateXxx(ctx context.Context, id int64, data *model.Xxx) error
DeleteXxx(ctx context.Context, id int64) error
```

- 新增 `SearchXxx` 必须只有 `ctx` 与指针 `param` 两个输入，且必须返回结果 slice、总数、error 三个输出。
- 新增 `CreateXxx` 必须只有 `ctx` 与 data model 指针两个输入。
- 新增 `UpdateXxx` 必须只有 `ctx`、主键 ID、data model 指针三个输入。
- 新增 `DeleteXxx` 必须只有 `ctx` 与主键 ID 两个输入。
- 查询方法必须命名为 `SearchXxx`。禁止新增 `FindXxx`、`GetXxx`、`SearchXxxForUser`、`SearchXxxForProject`、`UpdateXxxForUser`、`UpdateXxxForProject` 等调用方、所有者、租户或项目场景化方法。
- 调用方、所有者、租户、项目、状态、权限过滤必须写入 typed model param。既有非标准公开签名必须原样保留；只有用户明确要求时才能改形。
- 带 `Serialize()`、`Check()` 等领域方法的 param 与 data 必须使用指针类型。
- 查询字段必须按被过滤的 model 或关联 model 命名。跨 model 查询禁止使用含义不明的 `ID`、`Type`、`Name`、`Keyword`；必须使用 `ProjectID`、`UserID`、`PolicyID`、`RelatedName` 等语义字段。单一明确 model 的字段可使用 `Status` 等直接名称。

## DB 链路与超时

- 每个 DB 方法必须创建 timeout context，并在全部 DB 操作中使用 `dal.db.Get().WithContext(cancelCtx).Table(tb)`。

```go
cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*3)
defer cancelFunc()
```

- `Create` timeout 必须为 10 秒。
- 普通分页 `Search`、`Update`、`Delete` timeout 必须为 3 秒。
- 显式需要的小型全表参考数据 `Search` timeout 必须为 10 秒。
- 查询入口表名必须来自主要 model 的 `TableName()`。禁止硬编码表名，禁止使用其他 model 的表作为主入口。
- 每个 DAL 方法必须只操作一个主要 model，并返回该表 model。禁止返回原始 DB row、混合表 struct 或业务组装 response。
- DB 方法禁止无 timeout，禁止漏用 `WithContext(cancelCtx)`。

## 数据生命周期与查询

- DAL 只能调用当前 CRUD 操作需要的 model/param 生命周期方法：`CreateXxx` 调用 `Serialize()`、`Check()`、`TableName()`；`SearchXxx` 调用 param 的 `Serialize()`、`Check()`、主要 model 的 `TableName()`，并对每条结果调用 `Deserialize()`；`UpdateXxx` 调用 `Serialize()`、`Check()`、`ToUpdater()`、`TableName()`；`DeleteXxx` 只调用 `TableName()`。不得要求每个 DAL 方法调用全部生命周期方法。
- 禁止在 DAL 重复 trim、ID 归一化、默认值、派生查询字段、lowercase、字段清洗或领域校验。
- `SearchXxx` 必须先执行 `param = param.Serialize()`，再执行 `param.Check()`，再创建查询条件。
- `SearchXxx` 必须在校验前初始化结果 slice。成功返回时 slice 必须非 nil；无记录时返回空 slice。参数校验或查询出错时必须返回该初始化空 slice，禁止返回 nil slice。
- 参数归一化必须由所属 param 的公开 `Serialize()` 完成。禁止在 DAL 定义 `Normalize()`、`FillDefault()`、lowercase 方法或 `NormalizeSearchXxxParam` 等 package helper。
- `SearchXxx` 必须在同一方法内按下列顺序完成：建表、追加查询条件、`Count`、`model.AddFilter(db, param.Filter)`、`Find`、逐行 `Deserialize()`、返回结果。
- `Count` 前必须完成全部查询条件；`AddFilter` 必须在 `Count` 后调用。
- GORM query 必须逐步赋值，例如 `db = db.Where(...)`。禁止长链调用。
- `Where` 必须只在 param 字段非零时追加。零值表示查询全部或特殊语义时，必须在该分支写短注释。
- 调用方排序与分页必须只经 model 层 `AddFilter(db, param.Filter)` 进入查询。DAL 禁止自行选择默认排序，禁止直接调用 `Order`、`Limit`、`Offset`，禁止定义替代 `AddFilter` 的本地 helper。
- 既有 param 使用 `Filed` 拼写时必须保留该拼写。
- `param.Filed` 非空时必须执行 `db = db.Select(param.Filed)`，再继续 `Count` 与 `Find`；不得忽略字段投影。
- 状态字段必须使用字符串 `"true"`/`"false"`，禁止改为 `bool`。

## 跨表与 SQL 约束

- 跨表过滤必须使用 `WHERE ... IN (subquery)` 或 `EXISTS (subquery)`。仅当子查询无法表达且项目既有模式要求时才可使用 `Join`，并必须写明原因。
- 复杂跨 model 聚合、业务决策或多主要实体操作必须移至 service。
- 查询必须使用数据库兼容的相等、范围、`IN` 条件。禁止 window function、CTE、复杂子查询、数据库专有函数、JSON/array 操作、全文检索语法与自定义 SQL 函数；无法避免时必须说明必要性、兼容性影响、替代方案与目标数据库。
- 禁止在索引列条件中使用计算、SQL 函数或类型转换。禁止 `DATE(created_at)`、`LOWER(name)`、`CAST(id AS text)`、`amount + fee` 等表达式；无法避免时必须说明索引影响、数据量假设，以及未使用归一化字段、生成列、表达式索引或 param 转换的原因。

## 写入、更新与删除

- `CreateXxx` 必须先执行 `data = data.Serialize()` 和 `data.Check()`，再创建 10 秒 timeout、从 `data.TableName()` 取表名并执行 `Create`。
- `UpdateXxx` 必须校验主键 ID 为正数，先执行 `data = data.Serialize()` 和 `data.Check()`，再创建 3 秒 timeout、从主要 model 的 `TableName()` 取表名、按 ID 过滤并使用 `data.ToUpdater()` 执行 `Updates`。禁止保存完整 struct。
- `DeleteXxx` 必须校验主键 ID 为正数，创建 3 秒 timeout、从主要 model 的 `TableName()` 取表名并只按主键 ID 删除。
- 不可变字段、默认记录、权限、所有权、状态机与删除许可属于业务规则，DAL 禁止判断；必须由 model 或 service 在调用 DAL 前处理。

## 私有维护 helper

- 缓存或版本记录等派生持久化副作用必须使用私有 lower camel case helper，例如 `createXxxDBVersion`。
- 维护 helper 必须复用既有 DAL `Search` 方法，并显式构建 update map。
- 每个 helper DB 写入必须创建新的 timeout context。
- helper error 是否阻断主操作必须显式编码：阻断时返回 error；不阻断时必须写为 `_ = helper(ctx)`。
- 正常 `Search` 流水线必须保留在一个方法内。禁止拆成只包装一两个 GORM 调用的 `buildXxxWhere`、`countXxx`、`findXxx` helper。仅当片段以相同语义复用或独立出真实维护副作用时才可提取。

## 日志与验证

- DAL 禁止记录业务日志。日志所有权属于拥有完整业务上下文的 API、service 或 goroutine 边界。
- 修改 Go 文件后必须运行 `goimport`。
- 可定位包或测试时必须运行最小范围 `go test`。
