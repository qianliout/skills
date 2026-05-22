# Go Service Layer Conventions

Use this reference when generating general Go service layer code.

## Core Shape

A service file contains:

- A service interface named `XxxService` when the project uses service interfaces.
- A concrete implementation named `XxxSrv` or the local project convention.
- A constructor `NewXxxSrv(...) *XxxSrv`.
- Injected dependencies: DAL interfaces, other services, cache handles, logger, small in-memory state.
- Public methods that receive `ctx context.Context`.
- Private helper methods for domain-specific aggregation.

Service does not talk to the database directly. Persistence goes through DAL interfaces or established repository abstractions.

## Constructor Pattern

Constructor owns dependency wiring and logger/cache initialization:

```go
func NewXxxSrv(primaryDal store.PrimaryDal, relatedDal store.RelatedDal) *XxxSrv {
    srv := XxxSrv{
        primaryDal: primaryDal,
        relatedDal:  relatedDal,
        log: utils.NewLogEvent(
            utils.WithModule("moduleName"),
            utils.WithSubModule("service"),
        ),
    }
    return &srv
}
```

Rules:

- Do dependency validation at construction/bootstrap time when the project requires it.
- Avoid repeating `s == nil` or dependency nil checks in every service method.
- Keep constructor side effects limited to lightweight initialization.

## Public Search Pattern

```go
func (s *XxxSrv) SearchXxx(ctx context.Context, param model.SearchXxxParam) (
    []*model.XxxResponse, int64, error) {
    res := make([]*model.XxxResponse, 0)
    if err := param.Check(); err != nil {
        return res, 0, err
    }

    s.log.Trace().Str("param", param.LogStr()).Msg("SearchXxx")

    dalParam := param
    // Use param.ToXxxDalParam() instead when API fields need non-trivial mapping.
    data, cnt, err := s.primaryDal.SearchXxx(ctx, dalParam)
    if err != nil {
        s.log.Err(err).Str("param", dalParam.LogStr()).Msg("SearchXxx.SearchXxx")
        return nil, 0, wrapSearchXxxErr(err)
    }
    if len(data) == 0 {
        return res, 0, nil
    }

    for i := range data {
        item := data[i].ToResponse()
        res = append(res, &item)
    }
    return res, cnt, nil
}
```

Rules:

- Initialize result slices before validation.
- Call `param.Check()` at the public service boundary when the param type provides it.
- Use param conversion methods only when API and DAL params differ or the mapping is non-trivial.
- Passing the original param through is fine when it already matches the DAL contract.
- Log DAL errors with operation context according to project logging conventions.
- Return empty slices on successful empty list results.

## Update Pattern

```go
func (s *XxxSrv) UpdateXxx(ctx context.Context, param model.UpdateXxxParam) error {
    if err := param.Check(); err != nil {
        return err
    }
    if err := s.primaryDal.UpdateXxx(ctx, param.ID, param.Data); err != nil {
        s.log.Err(err).Str("param", param.LogStr()).Msg("UpdateXxx")
        return wrapUpdateXxxErr(err)
    }
    return nil
}
```

Rules:

- Service validates operation param when validation exists, then delegates persistence to DAL.
- Avoid manually building update maps in service; prefer model/DAL update contracts.
- Avoid mutating persistence fields that belong to model `Serialize()` / `ToUpdater()`.

## Detail Aggregation Pattern

```go
func (s *XxxSrv) GetXxxDetail(ctx context.Context, param model.XxxDetailParam) (*model.XxxDetailResponse, error) {
    if err := param.Check(); err != nil {
        return nil, err
    }
    ans := &model.XxxDetailResponse{
        Items:   make([]*model.XxxItem, 0),
        Related: make([]*model.RelatedItem, 0),
        Extra:   make(map[string][]*model.ExtraData),
    }

    errs := make([]error, 0)
    errs = append(errs, s.addBaseData(ctx, &param, ans))
    errs = append(errs, s.addRelatedData(ctx, &param, ans))
    errs = append(errs, s.addExtraData(ctx, &param, ans))

    errText := make([]string, 0)
    for i := range errs {
        if errs[i] != nil {
            s.log.Err(errs[i]).Msg("GetXxxDetail")
            errText = append(errText, errs[i].Error())
        }
    }
    if len(errText) > 0 {
        return ans, fmt.Errorf(strings.Join(errText, ","))
    }

    ans.Normalize()
    return ans, nil
}
```

Rules:

- Initialize slice/map fields that may be returned to callers.
- Use `addXxxData` helpers when a detail method spans multiple data domains.
- Return partial `ans` with aggregated error only when that is the established project behavior.
- Keep helper names private and specific.

## Batch Association Pattern

When enriching a list:

1. Collect IDs from the primary result.
2. Deduplicate IDs.
3. Query each related DAL once.
4. Build maps by ID.
5. Fill response objects from maps.

Avoid querying related DAL inside each item loop when the data can be batched.

## Logging And Errors

- Trace log public method input when useful; prefer safe `LogStr()` summaries over full struct logging.
- Error logs should include operation name and relevant param/ID context when available.
- Return user/API/service-level errors rather than leaking raw low-level wording when wrappers exist.
- Keep the original error visible in logs.

## Service vs DAL vs Model

- Model: types, `Check`, `Serialize`, `Deserialize`, `ToUpdater`, conversion helpers.
- DAL: persistence, timeout, SQL/GORM, `AddFilter`, CRUD/search.
- Service: orchestration, cross-DAL aggregation, response composition, logging, error wrapping.
