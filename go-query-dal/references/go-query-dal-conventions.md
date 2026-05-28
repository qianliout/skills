# Go Query DAL Conventions

Use this reference when generating general Go DAL/DAO code.

## Core Shape

DAL/DAO code lives in the project `store` directory/package. A DAL file contains:

- A narrow interface named `XxxDal`.
- A DAO implementation named `XxxDao`.
- A constructor `NewXxxDao(db *databases.RDBInstance) *XxxDao`.
- Methods that receive `ctx context.Context`.
- DAO implementation methods use pointer receivers named `dal`, such as `func (dal *XxxDao) SearchXxx(...)`. Do not use value receivers. Every method on the same DAO struct must use the same receiver form and name; do not mix `dal`, `dao`, or `d` on one `XxxDao`.
- Constructors/initialization guarantee DAO dependencies are non-nil; methods do not defensively check `dal == nil` or `dal.db == nil`.
- Param structs live with models, not in the DAL package.
- No recommended `Get` method by default; use `Search(ctx, param)` unless the user explicitly asks for single-record lookup.
- GORM queries built from `dal.db.Get().WithContext(cancelCtx).Table(...)`.
- Model lifecycle calls: `Serialize`, `Check`, `Deserialize`, `ToUpdater`, `TableName`.
- JSON tags on DAL-related model/param/result structs must not use `omitempty`.
- For newly designed tables/features, time fields used by DAL filters, inserts, updates, and reads are `int64` millisecond timestamps stored in integer columns; existing tables keep their established unit unless explicitly migrated.

## Dependency Management

DAO dependencies are declared on the DAO struct and wired in `NewXxxDao(...)`. Keep constructor parameter order aligned with field order.

Common DAO dependency order:

1. DB or transaction entry, such as `*databases.RDBInstance`.
2. Related DAO/repository interfaces only when the DAL method genuinely composes persistence from another store.
3. External persistence clients or stateless helpers, when the local project permits them in DAL.
4. Logger.

Rules:

- Query methods use already-injected fields; do not call DB/client/DAO constructors inside `Create`, `Search`, `Update`, or `Delete`.
- Keep ordinary SQL/GORM query builders, timeout contexts, result slices, and updater maps method-local because they are request-scoped.
- Prefer keeping cross-domain orchestration in service. Add related DAO dependencies to DAL only when the local architecture already allows DAL-to-DAL composition.
- If adding a dependency, update the DAO struct, constructor signature, assignments, and bootstrap call sites together.
- DAL methods should not create services. If a query needs business orchestration or multiple stores with domain decisions, move that orchestration to service and keep DAL focused on persistence.

## Timeout Pattern

Every DB method must use an explicit timeout:

```go
cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*3)
defer cancelFunc()
```

Typical durations:

- `Create`: 10 seconds.
- `Search`: 3 seconds for normal paginated query, 10 seconds only for small full-table reference data when explicitly needed.
- `Update`: 3 seconds.
- `Delete`: 3 seconds.

## Method Signature Rules

Use these signatures unless the user explicitly overrides them:

```go
CreateXxx(ctx context.Context, data *model.Xxx) error
SearchXxx(ctx context.Context, param *model.SearchXxxParam) ([]*model.Xxx, int64, error)
UpdateXxx(ctx context.Context, id int64, data *model.Xxx) error
DeleteXxx(ctx context.Context, id int64) error
```

Rules:

- `Search` has exactly two inputs: `ctx` and pointer `param`.
- `Search` has exactly three outputs: result slice, total count, error.
- `Update` has exactly three inputs: `ctx`, primary key ID, and model data.
- `Delete` has exactly two inputs: `ctx` and primary key ID; do not add param structs or extra condition arguments.
- `Create` has exactly two inputs: `ctx` and the data model pointer.
- Do not provide a `Get` method by default.

## Param Location Rule

Define all param types at the same package/directory layer as the data model:

```go
// model package
type SearchXxxParam struct {
    Filed     []string
    Status    string
    ProjectID string
    UserID    string
    Filter    Filter
}
```

DAL code imports and uses model params:

```go
SearchXxx(ctx context.Context, param *model.SearchXxxParam) ([]*model.Xxx, int64, error)
```

Do not define `SearchXxxParam`, `UpdateXxxParam`, filter structs, sort structs, or pagination structs in the DAL package.

## Param Semantic Naming

Name query param fields after the model or related model concept they filter.

Good:

- `ProjectID`: filters by related project.
- `UserID`: filters by related user.
- `PolicyID`: filters by related policy.
- `Status`: filters the primary model status when the param only targets one model.
- `RelatedName`: filters a related object name.

Avoid vague fields such as `ID`, `Type`, `Name`, or `Keyword` when the query spans multiple models or associations. Use the vague form only when the param has a single obvious model context.

## Search Pattern

Prefer a complete top-to-bottom query chain in one DAL method. A reader should be able to open `SearchXxx` and immediately see how the query is built, counted, paginated, executed, and deserialized without jumping through private helpers.

Template:

```go
func (dal *XxxDao) SearchXxx(ctx context.Context, param *model.SearchXxxParam) (
    []*model.Xxx, int64, error) {
    res := make([]*model.Xxx, 0)
    param = param.Serialize()
    if err := param.Check(); err != nil {
        return res, 0, err
    }
    cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*3)
    defer cancelFunc()

    data := &model.Xxx{}
    tb := data.TableName()
    db := dal.db.Get().WithContext(cancelCtx).Table(tb)
    if len(param.Filed) > 0 {
        db = db.Select(param.Filed)
    }
    if param.Status != "" {
        db = db.Where("status = ? ", param.Status)
    }
    if param.Enable == consts.TrueString {
        db = db.Where("enable = ? ", consts.TrueString)
    } else if param.Enable == consts.FalseString {
        db = db.Where("enable = ? ", consts.FalseString)
    }
    if param.ProjectID != "" {
        db = db.Where("project_id = ? ", param.ProjectID)
    }

    var cnt int64
    if err := db.Count(&cnt).Error; err != nil {
        return res, 0, err
    }

    db = model.AddFilter(db, param.Filter)
    err := db.Find(&res).Error
    if err != nil {
        return res, 0, err
    }
    for i := range res {
        res[i] = res[i].Deserialize()
    }

    return res, cnt, nil
}
```

Rules:

- Params with domain methods should be pointer types, such as `*model.SearchXxxParam`, so `Serialize()` can return a replacement object for nil receiver cases.
- Call `param = param.Serialize()` before `param.Check()` and before creating query conditions.
- Initialize result slices before validation and return the initialized empty slice on every path.
- Put trim, ID normalization, default values, and derived query fields in the owning param's public `Serialize()`; put format and optional-resource validation in `Check()`.
- Query normalization belongs to the param struct that owns the query fields and is unified under public `Serialize()`. DAL should not define `Normalize()`, `FillDefault()`, lower-case normalization methods, or package-level helpers such as `NormalizeSearchXxxParam(param *SearchXxxParam)` when the behavior belongs on the param receiver.
- Do not repeat parameter normalization or validation in DAL; DAL should only consume checked param fields.
- Do not check `dal == nil` or `dal.db == nil` inside DAL methods; initialization owns that guarantee.
- Keep the full query chain in the method whenever practical: setup table, append business filters, count, apply filter/page, find, deserialize, return.
- Build exact business filters before `Count`.
- Build GORM queries step by step with assignments like `db = db.Where(...)`; avoid long chained calls.
- Add `Where` clauses only when the param field is non-zero.
- If a zero value intentionally means "query all" or another special case, add a short comment at that branch.
- Keep queries database-compatible. Prefer simple equality, range, and `IN` conditions over advanced SQL.
- Avoid window functions, CTEs, complex subqueries, database-specific functions, JSON operators, array operators, full-text-search syntax, and custom SQL functions in DAL queries. If unavoidable, add a detailed comment explaining why, compatibility impact, alternatives considered, and the target database.
- Do not apply calculations, SQL functions, or type casts to indexed columns in query conditions. Prefer comparing raw columns to normalized param values, such as `created_at >= ? AND created_at < ?`, `name = ?`, or `id = ?`.
- Avoid conditions such as `DATE(created_at) = ?`, `LOWER(name) = ?`, `CAST(id AS text) = ?`, or `amount + fee > ?` because they can make normal indexes unusable. If such a condition is unavoidable, add a detailed comment explaining why, the expected index impact, data size assumption, and why a normalized field, generated column, expression index, or param-side transformation is not used.
- Apply caller-provided sorting and pagination only through the project-defined model-layer `AddFilter(db, param.Filter)` after `Count`; `AddFilter` is the dedicated sorting/pagination entry point.
- DAL does not choose default ordering; callers decide ordering through `param.Filter`, and DAL applies it through `AddFilter`.
- Do not write `Order`, `Limit`, or `Offset` directly in DAL methods, and do not create local helper replacements for `AddFilter`.
- Return the initialized empty result slice on query errors, such as `return res, 0, err`; do not return `nil` for slice results.
- Keep `Filed` spelling if the existing param uses it.
- Use string `"true"` / `"false"` status values; do not introduce `bool`.

## Create Pattern

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
    err := db.Create(data).Error
    return err
}
```

If the domain requires version/cache maintenance after creation, call a private helper after the DB operation and decide explicitly whether helper errors block the operation.

## Update Pattern

```go
func (dal *XxxDao) UpdateXxx(ctx context.Context, id int64, data *model.Xxx) error {
    if id <= 0 {
        return fmt.Errorf("not get id")
    }
    data = data.Serialize()
    if err := data.Check(); err != nil {
        return err
    }

    cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*3)
    defer cancelFunc()

    pre := &model.Xxx{}
    tb := pre.TableName()
    db := dal.db.Get().WithContext(cancelCtx).Table(tb)
    db = db.Where("id = ?", id)
    if err := db.First(pre).Error; err != nil {
        return err
    }
    if pre.Type != data.Type {
        return fmt.Errorf("type is not correct")
    }

    updater := data.ToUpdater()
    db = dal.db.Get().WithContext(cancelCtx).Table(tb)
    db = db.Where("id = ?", id)
    err := db.Updates(updater).Error
    return err
}
```

Rules:

- Fetch existing row before update.
- Validate immutable fields before updating.
- Use `ToUpdater()` instead of saving the full struct.

## Delete Pattern

```go
func (dal *XxxDao) DeleteXxx(ctx context.Context, id int64) error {
    if id <= 0 {
        return fmt.Errorf("not get id")
    }
    cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*3)
    defer cancelFunc()

    pre := &model.Xxx{}
    tb := pre.TableName()
    db := dal.db.Get().WithContext(cancelCtx).Table(tb)
    db = db.Where("id = ?", id)
    if err := db.First(pre).Error; err != nil {
        return err
    }
    if pre.IsDefault == consts.TrueString {
        return fmt.Errorf("delete default data is not permitted")
    }

    db = dal.db.Get().WithContext(cancelCtx).Table(tb)
    db = db.Where("id = ?", id)
    err := db.Delete(&model.Xxx{}).Error
    return err
}
```

## Private Maintenance Helpers

Use private helpers for derived cache/version records:

- Name them with lower camel case, such as `createXxxDBVersion`.
- Reuse existing DAL search methods when possible.
- Build update maps explicitly.
- Use a fresh timeout context for helper DB writes.
- If helper failure should not block the main operation, call it as `_ = helper(ctx)` so the choice is visible.

Do not extract the normal `Search` pipeline into many tiny helpers by default. Query setup, conditional `Where` clauses, `Count`, `AddFilter`, `Find`, and `Deserialize` should stay in one method so the query is readable from top to bottom. Extract only when a query fragment is reused with the same semantics or an extracted block isolates a real maintenance side effect. Avoid `buildXxxWhere`, `countXxx`, or `findXxx` helpers that only wrap one or two GORM calls and force the reader to jump around.
