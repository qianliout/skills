# Go Query DAL Conventions

Use this reference when generating general Go DAL/DAO code.

## Core Shape

A DAL file contains:

- A narrow interface named `XxxDal`.
- A DAO implementation named `XxxDao`.
- A constructor `NewXxxDao(db *databases.RDBInstance) *XxxDao`.
- Methods that receive `ctx context.Context`.
- Constructors/initialization guarantee DAO dependencies are non-nil; methods do not defensively check `dal == nil` or `dal.db == nil`.
- Param structs live with models, not in the DAL package.
- No recommended `Get` method by default; use `Search(ctx, param)` unless the user explicitly asks for single-record lookup.
- GORM queries built from `dal.db.Get().WithContext(cancelCtx).Table(...)`.
- Model lifecycle calls: `Check`, `Serialize`, `Deserialize`, `ToUpdater`, `TableName`.

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
CreateResource(ctx context.Context, data *model.Resource) error
SearchResource(ctx context.Context, param model.SearchResourceParam) ([]*model.Resource, int64, error)
UpdateResource(ctx context.Context, id int64, data *model.Resource) error
DeleteResource(ctx context.Context, id int64) error
```

Rules:

- `Search` has exactly two inputs: `ctx` and `param`.
- `Search` has exactly three outputs: result slice, total count, error.
- `Update` has exactly three inputs: `ctx`, primary key ID, and model data.
- `Delete` has exactly two inputs: `ctx` and primary key ID; do not add param structs or extra condition arguments.
- `Create` has exactly two inputs: `ctx` and the data model pointer.
- Do not provide a `Get` method by default.

## Param Location Rule

Define all param types at the same package/directory layer as the data model:

```go
// model package
type SearchResourceParam struct {
    Filed  []string
    Type   string
    Enable string
    Filter Filter
}
```

DAL code imports and uses model params:

```go
SearchResource(ctx context.Context, param model.SearchResourceParam) ([]*model.Resource, int64, error)
```

Do not define `SearchResourceParam`, `UpdateResourceParam`, filter structs, sort structs, or pagination structs in the DAL package.

## Search Pattern

Template:

```go
func (dal *ResourceDao) SearchResource(ctx context.Context, param model.SearchResourceParam) (
    []*model.Resource, int64, error) {
    if err := param.Check(); err != nil {
        return nil, 0, err
    }
    cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*3)
    defer cancelFunc()
    res := make([]*model.Resource, 0)

    db := dal.db.Get().WithContext(cancelCtx).Table(new(model.Resource).TableName())
    if len(param.Filed) > 0 {
        db = db.Select(param.Filed)
    }
    if param.Type != "" {
        db = db.Where("type = ? ", param.Type)
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
        return nil, 0, err
    }

    db = model.AddFilter(db, param.Filter)
    err := db.Find(&res).Error
    if err != nil {
        return nil, 0, err
    }
    for i := range res {
        res[i].Deserialize()
    }

    return res, cnt, nil
}
```

Rules:

- Call `param.Check()` before creating query conditions.
- Put trim, format validation, ID normalization, optional-resource validation, default values, and derived query fields in `param.Check()` or param methods.
- Do not repeat parameter normalization or validation in DAL; DAL should only consume checked param fields.
- Do not check `dal == nil` or `dal.db == nil` inside DAL methods; initialization owns that guarantee.
- Build exact business filters before `Count`.
- Build GORM queries step by step with assignments like `db = db.Where(...)`; avoid long chained calls.
- Add `Where` clauses only when the param field is non-zero.
- If a zero value intentionally means "query all" or another special case, add a short comment at that branch.
- Apply sorting and pagination only through the model-layer `AddFilter(db, param.Filter)` after `Count`.
- Do not write `Order`, `Limit`, or `Offset` directly in DAL methods.
- Return `nil, 0, err` on query errors.
- Keep `Filed` spelling if the existing param uses it.
- Use string `"true"` / `"false"` status values; do not introduce `bool`.

## Create Pattern

```go
func (dal *ResourceDao) CreateResource(ctx context.Context, data *model.Resource) error {
    if err := data.Check(); err != nil {
        return err
    }
    data.Serialize()

    cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*10)
    defer cancelFunc()
    return dal.db.Get().WithContext(cancelCtx).Table(data.TableName()).Create(data).Error
}
```

If the domain requires version/cache maintenance after creation, call a private helper after the DB operation and decide explicitly whether helper errors block the operation.

## Update Pattern

```go
func (dal *ResourceDao) UpdateResource(ctx context.Context, id int64, data *model.Resource) error {
    if id <= 0 {
        return fmt.Errorf("not get id")
    }
    if err := data.Check(); err != nil {
        return err
    }
    data.Serialize()

    cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*3)
    defer cancelFunc()

    pre := &model.Resource{}
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
    return db.Updates(updater).Error
}
```

Rules:

- Fetch existing row before update.
- Validate immutable fields before updating.
- Use `ToUpdater()` instead of saving the full struct.

## Delete Pattern

```go
func (dal *ResourceDao) DeleteResource(ctx context.Context, id int64) error {
    if id <= 0 {
        return fmt.Errorf("not get id")
    }
    cancelCtx, cancelFunc := context.WithTimeout(ctx, time.Second*3)
    defer cancelFunc()

    pre := &model.Resource{}
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
    return db.Delete(&model.Resource{}).Error
}
```

## Private Maintenance Helpers

Use private helpers for derived cache/version records:

- Name them with lower camel case, such as `createResourceDBVersion`.
- Reuse existing DAL search methods when possible.
- Build update maps explicitly.
- Use a fresh timeout context for helper DB writes.
- If helper failure should not block the main operation, call it as `_ = helper(ctx)` so the choice is visible.
