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

All service implementation methods use pointer receivers named `s`, such as `func (s *XxxSrv) SearchXxx(...)`. Do not use value receivers for service structs. Every method on the same service struct must use the same receiver form and name; do not mix `s`, `srv`, or `service` on one `XxxSrv`.

Service dependencies must be explicit. Inject DALs, other services, caches, clients, loggers, clocks, ID generators, config, or other long-lived collaborators through the constructor and store them in clearly named struct fields. Do not instantiate those dependencies inside public or private business methods; method bodies should orchestrate already-injected dependencies.

Service interfaces should stay broad enough to survive new callers and filters. Use resource/action methods such as `SearchXxx`, `UpdateXxx`, `CreateXxx`, and `DeleteXxx`; do not create caller-specific variants such as `SearchXxxForUser`, `UpdateXxxForProject`, or `CreateXxxForOrg` when the difference is only a filter, owner, tenant, project, or permission context. Put those constraints on typed params or command structs and validate them with `Check()`.

## Dependency Management

Manage dependencies in one place: the service struct declares what the service needs, and `NewXxxSrv(...)` wires those dependencies. Keep the field order and constructor parameter order aligned so the dependency graph is readable at a glance.

Common service dependency order:

1. DAL/repository interfaces for the primary model, then related models.
2. Other service interfaces used for cross-domain orchestration.
3. Cache, queue, lock, or other infrastructure handles.
4. External clients/gateways, such as HTTP/RPC/object storage clients.
5. Config, clock, ID generator, feature flags, or small stateless helpers.
6. Logger or log event.

Rules:

- Depend on interfaces when the project has service/DAL interfaces; otherwise follow the local constructor convention.
- Constructor parameters should match the struct field order and use meaningful names, such as `policyDal`, `projectSrv`, or `cache`.
- Initialize lightweight owned helpers in the constructor only when they do not hide external dependencies.
- Do not call `NewXxxDao`, `NewXxxSrv`, `NewClient`, `utils.NewLogEvent`, or similar dependency factories inside business methods.
- Method-local objects are allowed only when they are request-scoped values, params, result containers, transactions, timers, or other short-lived data.
- If adding a new dependency, update the struct, constructor signature, constructor assignment, and call sites together.
- Keep dependency direction clear: service may depend on DAL/repository interfaces, other service interfaces, cache/infrastructure, external clients, config/helpers, and logger; service must not import API/controller packages and must not bypass DAL to use DB/GORM/SQL directly.
- Do not use nil injected dependencies to skip business behavior. Branches such as `if s.cache != nil { ... }`, `if s.primaryDal == nil { return res, 0, nil }`, or `if s.log != nil { ... }` hide wiring errors; fix constructor/bootstrap/test setup instead.
- Ordinary input nil checks and model/param receiver nil handling are still allowed; this rule is only about long-lived service dependencies.

## Constructor Pattern

Constructor owns dependency wiring and logger/cache initialization:

```go
func NewXxxSrv(
    primaryDal store.PrimaryDal,
    relatedDal store.RelatedDal,
    relatedSrv service.RelatedService,
    cache cache.XxxCache,
    client gateway.XxxClient,
) *XxxSrv {
    srv := XxxSrv{
        primaryDal: primaryDal,
        relatedDal:  relatedDal,
        relatedSrv:  relatedSrv,
        cache:       cache,
        client:      client,
        log: utils.NewLogEvent(
            utils.WithModule("moduleName"),
            utils.WithSubModule("service"),
        ),
    }
    return &srv
}
```

Rules:

- Constructor parameters should show the service dependency graph clearly and keep the same order as the struct fields.
- Do dependency validation at construction/bootstrap time when the project requires it.
- Avoid repeating `s == nil` or dependency nil checks in every service method.
- Do not make service methods degrade or silently skip work when a DAL/service/cache/client/logger dependency is nil.
- Keep constructor side effects limited to lightweight initialization.

## Public Search Pattern

```go
func (s *XxxSrv) SearchXxx(ctx context.Context, param *model.SearchXxxParam) (
    []*model.XxxResponse, int64, error) {
    res := make([]*model.XxxResponse, 0)
    param = param.Serialize()
    if err := param.Check(); err != nil {
        return res, 0, err
    }

    paramLog := param.LogStr()
    s.log.Trace().Str("param", paramLog).Msg("SearchXxx")

    dalParam := param
    // Use param.ToXxxDalParam() instead when API fields need non-trivial mapping.
    data, cnt, err := s.primaryDal.SearchXxx(ctx, dalParam)
    if err != nil {
        dalParamLog := dalParam.LogStr()
        s.log.Err(err).Str("param", dalParamLog).Msg("SearchXxx.SearchXxx")
        searchErr := wrapSearchXxxErr(err)
        return res, 0, searchErr
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
- If a slice or map is part of the return values, initialize it before validation and return that initialized value on every path, including errors.
- Params with domain methods should be pointer types, such as `*model.SearchXxxParam`, so `Serialize()` can return a replacement object for nil receiver cases.
- Do not add separate search methods per caller scenario. Prefer one `SearchXxx(ctx, param)` method and fields such as `UserID`, `ProjectID`, `OwnerID`, `TenantID`, or status fields on the param.
- Call `param = param.Serialize()` before `param.Check()` at the public service boundary when the param type provides these methods.
- Keep trim/default/normalize/derive/fill logic on the model/param/result struct that owns those fields, unified under public `Serialize()`. Service may call `param = param.Serialize()`, `param.Check()`, or `data = data.Serialize()`, but should not host package-level normalization helpers, `Normalize()`, `FillDefault()`, or lower-case normalization methods for a specific struct.
- Use param conversion methods only for cross-type API/DAL DTO mapping when the mapping is non-trivial; conversion methods must not duplicate `Serialize()` / `Deserialize()` responsibilities such as trim, defaults, normalization, or derived fields.
- Passing the original param through is fine when it already matches the DAL contract.
- Log DAL errors with operation context according to project logging conventions.
- Return empty slices/maps instead of nil whenever slice/map values are returned.

## Update Pattern

```go
func (s *XxxSrv) UpdateXxx(ctx context.Context, param *model.UpdateXxxParam) error {
    param = param.Serialize()
    if err := param.Check(); err != nil {
        return err
    }
    if err := s.primaryDal.UpdateXxx(ctx, param.ID, param.Data); err != nil {
        paramLog := param.LogStr()
        s.log.Err(err).Str("param", paramLog).Msg("UpdateXxx")
        updateErr := wrapUpdateXxxErr(err)
        return updateErr
    }
    return nil
}
```

Rules:

- Do not add separate update methods per caller scenario, such as `UpdateXxxForProject`. Prefer a single update command/param that carries the ID, owner/project constraints, and update data, then validate the constraints before calling DAL.
- Service validates operation param when validation exists, then delegates persistence to DAL.
- Avoid manually building update maps in service; prefer model/DAL update contracts.
- Avoid mutating persistence fields that belong to model `Serialize()` / `ToUpdater()`.
- Avoid field normalization in service when the owning param/model can provide public `Serialize()`.

## Detail Aggregation Pattern

```go
func (s *XxxSrv) GetXxxDetail(ctx context.Context, param *model.XxxDetailParam) (*model.XxxDetailResponse, error) {
    param = param.Serialize()
    if err := param.Check(); err != nil {
        return nil, err
    }
    ans := &model.XxxDetailResponse{
        Items:   make([]*model.XxxItem, 0),
        Related: make([]*model.RelatedItem, 0),
        Extra:   make(map[string][]*model.ExtraData),
    }

    errs := make([]error, 0)
    baseErr := s.addBaseData(ctx, param, ans)
    errs = append(errs, baseErr)
    relatedErr := s.addRelatedData(ctx, param, ans)
    errs = append(errs, relatedErr)
    extraErr := s.addExtraData(ctx, param, ans)
    errs = append(errs, extraErr)

    errText := make([]string, 0)
    for i := range errs {
        if errs[i] != nil {
            s.log.Err(errs[i]).Msg("GetXxxDetail")
            errMsg := errs[i].Error()
            errText = append(errText, errMsg)
        }
    }
    if len(errText) > 0 {
        errMsg := strings.Join(errText, ",")
        ansErr := fmt.Errorf("%s", errMsg)
        return ans, ansErr
    }

    ans = ans.Serialize()
    return ans, nil
}
```

Rules:

- Initialize slice/map fields that may be returned to callers; never leave returned slice/map fields nil unless the field is explicitly pointer-optional by contract.
- Use `addXxxData` helpers when a detail method spans multiple data domains, not merely because a block is a few lines long.
- Return partial `ans` with aggregated error only when that is the established project behavior.
- Keep helper names private and specific.

## Helper Granularity

Service methods should keep the main business path readable without forcing unnecessary jumps.

The main method should usually present 3-7 ordered business steps at the same abstraction level, such as serialize/check param, load primary data, load related data, merge response, log/wrap errors, and return. If the method has many unrelated stages, split by data domain or side effect; if each helper only hides one obvious line, keep it inline.

Good helper boundaries:

- One helper owns one related data domain, such as base data, project data, policy data, or cache enrichment.
- One helper isolates a side effect, such as an external client call, transaction block, async enqueue, or cache refresh.
- One helper hides a complex branch whose name is a real business concept.
- One helper is reused by multiple public service methods with the same semantics.

Avoid helper boundaries:

- A helper that only forwards to one DAL/service call without adding business meaning.
- A helper that only appends one field, assigns one map entry, or wraps one error.
- A chain of private helpers where each helper only calls the next helper.
- Splitting validation, serialization, and one DAL call into separate private methods when the public method would be clearer inline.

When unsure, keep the code inline with semantic local variables. Split only after the block has a stable name that helps the reader understand the service workflow.

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

- Model: types, public `Serialize`, `Deserialize`, `ToUpdater`, `Check`, `Same`, and pure cross-type conversion methods that do not duplicate serialization/deserialization or normalization responsibilities.
- DAL: persistence, timeout, SQL/GORM, `AddFilter`, CRUD/search.
- Service: orchestration, cross-DAL aggregation, response composition, logging, error wrapping.
- Package-level helpers: only truly generic, domain-neutral utilities with no clear owning struct.
