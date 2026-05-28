# Go Model Conventions

Use this reference when generating general Go model layer definitions. The patterns are extracted from `image.go`, but they are domain-neutral.

## Core Shape

The sample models use rich domain structs rather than passive DTOs. A persistent entity usually owns:

- DB tags with explicit columns.
- JSON tags for API compatibility, without `omitempty`.
- Runtime-only fields marked `gorm:"-"`.
- Serialized text backing fields marked `json:"-"` when a runtime complex structure is stored in a string text column.
- Lifecycle methods: `Serialize`, `Deserialize`, `Check`, `TableName`.
- Derived identity, UUID, checksum, display/search, and compatibility fields are prepared inside `Serialize()`, not in extra same-purpose methods such as `GenUniqueID`, `GenUUID`, or `GenCheckSum`.

Model-layer ownership includes model structs, param structs, validation, serialization, deserialization, derived fields, normalization, default filling, and update field selection. These behaviors should usually be public methods on the specific model type, such as `(vi *Xxx) Check()` or `(vi *Xxx) Serialize()`, rather than loose helpers with no owner. Model-related constants are an exception to model-layer file ownership: define them in the project-defined `consts` directory.

Domain normalization belongs to the struct that owns the fields. If logic trims names, fills default status values, normalizes IDs, derives display/search fields, serializes backing text fields, or fixes compatibility values from a model/param/result's fields, put it on that model/param/result's `Serialize()` method. Do not create `Normalize()`, `FillDefault()`, lower-case normalization helpers, or package-level functions for logic that clearly belongs to one struct. Package-level functions are only for truly generic, domain-neutral tools with no clear field owner.

If `Serialize()` or `Deserialize()` exists for a struct, do not add another method or function with overlapping normalization, defaulting, derived-field, serialization, or deserialization responsibilities.

Common domain lifecycle methods must be exported and use these fixed signatures:

```go
func (vi *Xxx) Serialize() *Xxx
func (vi *Xxx) Deserialize() *Xxx
func (vi *Xxx) ToUpdater() map[string]interface{}
func (vi *Xxx) Check() error
func (vi *Xxx) Same(after *Xxx) bool
```

Do not change this lifecycle method group's signatures to omit the receiver return, accept context, accept external params, or use lower-case method names. This rule does not forbid framework or interface adapter methods with required signatures, such as GORM `TableName() string`, `MarshalJSON() ([]byte, error)`, or other established project adapter methods. `Serialize()` and `Deserialize()` return a receiver pointer. When the receiver is nil, they must create a new object and return it; when the receiver is non-nil, they mutate and return the original receiver. Callers must assign the return value back to the original variable, such as `data = data.Serialize()` or `item = item.Deserialize()`. Their method bodies do not create normalized copies or replacement objects except for the nil receiver allocation.

`Serialize()`、`Deserialize()`、`ToUpdater()`、`Check()`、`Same()` do not call each other internally. Their composition is fully controlled by external callers, such as API/service/DAL code deciding to run `param = param.Serialize()` and then `param.Check()`. Keep each domain method mostly self-contained in one function; do not split struct-specific normalization, validation, comparison, or updater logic into private helpers unless the helper is truly generic and has no field owner.

All model, param, response, and value-object methods use pointer receivers. Do not use value receivers, including for read-only methods such as `TableName()` or `LogStr()`. Every method on the same model-layer struct must use the same receiver form and name. Types whose names contain `Param` use receiver name `p`; other model-layer objects such as model/entity/result/view/cache/statistic use receiver name `vi`. Do not mix `p` and `param` on one param type, or `vi`, `m`, and `item` on one model type.

Model methods should stay readable without becoming either a packed script or a helper maze. Keep a single domain method top-to-bottom when it owns one field lifecycle task. Extract only truly generic, domain-neutral utilities or a reused block with a stable business meaning; do not split one struct's normalization, validation, comparison, or updater field selection into `normalizeXxx`, `checkXxx`, `sameXxx`, or `buildUpdater` helpers.

The model package should stay low-level. It may depend on the standard library, external foundational libraries, and project `utils`; it should not depend on API, service, DAL, or other business-layer packages.

## Database Compatibility

Model design must consider database compatibility first.

Rules:

- Do not use database complex types such as JSON/JSONB, arrays, maps, or object columns as persistent model fields.
- Persistent fields should use broadly compatible primitive database types: signed integers, strings/text, and simple status strings. For newly designed tables or features, time fields use `int64` millisecond timestamps stored in integer columns.
- Complex structures may be stored in `string` text columns with `Serialize()` / `Deserialize()`.
- Split complex structures into normal columns or relation tables when they need frequent filtering, indexing, partial update, or database constraints.
- Runtime complex fields must be marked `gorm:"-"`.

## JSON Tag Pattern

Do not write `omitempty` in any `json` tag.

Rules:

- Use explicit field names such as `json:"name"` or `json:"-"`.
- Do not write `json:"name,omitempty"` or `json:",omitempty"` on model, param, response/view, cache/statistic, or helper value-object structs.
- Keep zero values explicit in API responses and serialized data; absence semantics should be represented by the model contract or pointer/nullable field choice, not by hiding fields with `omitempty`.

## Serialized Text Pattern

When a complex runtime field is stored in one text column:

```go
Config     Config `gorm:"-" json:"config"`
ConfigJSON string `gorm:"column:config" json:"-"`
```

Rules:

- Public runtime object gets `gorm:"-"` and normal `json`.
- DB text string gets `gorm:"column:..."` and `json:"-"`; the field may be named `ConfigJSON` by project convention, but the database type is still string/text.
- Do not map the backing field to a database JSON/JSONB type.
- `Serialize()` marshals runtime object into DB string.
- `Deserialize()` unmarshals DB string into runtime object.
- Use split columns or relation tables instead when the data must be filtered, indexed, partially updated, or constrained by the database.

## ID Pattern

Do not use `uint64` in persistent models. PostgreSQL has no native unsigned 64-bit integer type.

Every persistent data model must include the standard unique data identifier:

```go
UniqueID int64 `gorm:"column:unique_id" json:"uniqueID"`
```

Use `UniqueID int64` to represent the globally unique data identity for the model. Do not omit it from a persistent data model, and do not rename it to another field such as `ID`, `DataID`, or `UID` unless an existing external contract explicitly requires compatibility.

Use `int64` for database-backed IDs and business identities that fit PostgreSQL `bigint`.

Do not introduce numeric types larger than `int64`. If an external identifier is larger than `int64`, produced by unsigned hashing, comes from a snowflake generator, or must preserve lexical form, model it as a separate opaque `string` identifier, not as a replacement for `UniqueID`:

```go
ExternalID string `gorm:"column:external_id" json:"externalID"`
```

Generate source-specific IDs from stable business keys:

- Tenant-scoped resource: tenant ID + business code + resource type.
- Parent-scoped resource: parent ID + name/code + version + resource type.
- Content-addressed resource: normalized display name + digest/checksum + resource type.

If a source type intentionally has no generated ID, document it.

Type rules:

- Model, param, response, and value-object fields should use plain primitive types by default.
- Avoid named primitive wrappers such as `type Kind string` for enum/status fields unless an external API, third-party library, meaningful method set, or strong type-safety boundary clearly requires it.
- Represent enum/status values with primitive fields plus named constants in `consts`.
- Numeric fields in structs use `int64` by default unless there is a clear exception.
- `int64`: PostgreSQL `bigint`, timestamps in milliseconds, counts, signed flags, numeric IDs inside signed range.
- `string`: UUID, snowflake IDs, unsigned hash output, external IDs, compound unique keys, and serialized text. These are opaque identifiers or text payloads, not numeric fields.
- Other numeric types require an explicit reason, such as external protocol compatibility, third-party library signatures, byte-size data, or an established local convention.
- never `uint64` / `uint`: avoid PostgreSQL incompatibility and silent overflow risks.
- never numeric types larger than `int64`: no `big.Int`, decimal big integer, custom large-number type, or unsigned 64-bit type in models.
- never database JSON/JSONB, arrays, maps, or complex object columns as persistent fields.
- never `bool`: binary status fields use `string` with values `"true"` / `"false"`.

## Time Field Pattern

For newly designed tables or features, every time-related value uses a millisecond timestamp.

Every persistent data model must include the standard lifecycle fields:

```go
CreatedAt int64 `gorm:"autoCreateTime:milli;column:created_at" json:"createdAt"` // milliseconds
UpdatedAt int64 `gorm:"autoUpdateTime:milli;column:updated_at" json:"updatedAt"` // milliseconds
DeletedAt int64 `gorm:"column:deleted_at" json:"deletedAt"`                     // milliseconds
```

Rules:

- Include `CreatedAt`, `UpdatedAt`, and `DeletedAt` on every persistent data model. Do not omit `DeletedAt` just because a feature has no active soft-delete flow yet.
- Use Go `int64` for time fields in model, param, response/view, cache/statistic, and helper value-object structs.
- Store time fields in the database as integer millisecond timestamps, usually PostgreSQL `bigint`; do not introduce second-level timestamp fields for new tables/features.
- Keep frontend/backend request params, response fields, service inputs/outputs, DAL query params, cache payloads, and serialized data in milliseconds.
- Use `time.Now().UTC().UnixMilli()` for current time values.
- Existing features keep their established time unit and storage shape unless the user explicitly asks for a migration or compatibility refactor.
- When reading old second-level data for compatibility, convert it to milliseconds in `Deserialize()` and keep the compatibility rule close to the owning model.

## Boolean Status Pattern

Do not define model fields as `bool`.

Use string fields for binary status:

```go
Enable    string `gorm:"column:enable" json:"enable"`
IsDefault string `gorm:"column:is_default" json:"isDefault"`
Deleted   string `gorm:"column:deleted" json:"deleted"`
```

Rules:

- Allowed values are exactly `"true"` and `"false"`.
- `Check()` validates binary status strings when the field is required.
- `Serialize()` may fill default values such as `"false"` before insert/update.
- Query params should also use string values so filtering can distinguish unset from `"false"`.

## Validation Pattern

`Check()` should:

1. Return an error for nil receiver.
2. Validate enum/type fields.
3. Require common identity fields such as name/code/type/version.
4. Require context-specific fields such as tenant ID, project ID, parent ID, or external ID.

`Check()` belongs with the model or param it validates. Do not repeat the same validation in API, service, or DAL. `Check()` does not trim, fill defaults, derive fields, mutate data, or call `Serialize()` / `Deserialize()` / `ToUpdater()` / `Same()`; callers decide when to run `Serialize()` before `Check()`.

## Serialization Pattern

`Serialize()` is the single place to trim, fill defaults, normalize, derive, and prepare fields:

- Default flag.
- Historical timestamp units.
- Serialized text backing fields.
- Display/search name.
- Unique ID and compact UUID.
- Denormalized grouping fields.
- Checksum.

Do not generate these model-derived values in API, service, or DAL. Upper layers should call `Serialize()` before `Check()` and before persistence/query/update code consumes the fields.

When the normalization is tied to request/query/update fields instead of persistent entity fields, still use the owning param or result struct's `Serialize()` method. Avoid `Normalize()`, `FillDefault()`, and package-level functions like `NormalizeSearchXxxParam(param *SearchXxxParam)` when the behavior clearly belongs to that param.

## Deserialization Compatibility

`Deserialize()` may contain compatibility rules for old data:

- Normalize legacy enum values.
- Convert second-level timestamps to milliseconds.
- Fill historical default values for fields added after old records were created.
- Rebuild runtime-only fields from serialized text backing columns.

Keep these rules close to the model because they define stored-data compatibility.

## Table and Update Pattern

`TableName()` returns a literal table name:

```go
func (vi *Resource) TableName() string {
    return "app_resource"
}
```

`ToUpdater()` returns an initialized map of explicitly updateable columns and updates `updated_at` with `time.Now().UTC().UnixMilli()`. Any model method returning a slice or map must return an initialized empty value instead of nil on every path.

## Layering Examples

- Entity: `Resource`, `Rule`, `CacheInfo`.
- Param/command: `SearchResourceParam`, `UpdateResourceParam`, `CreateRuleParam`.
- Detail/value object: `ResourceDetail`, `ConfigItem`, `ExternalRef`.
- Statistic/view: `ResourceStatistic`, `ResourceOverview`, `IssueStatic`, `Suggest`.
- Cache snapshot: `PrepareData`, `CacheInfo`.

## Constants And Dependencies

- Define model-related constants, enum values, default values, and field value constraints in the project-defined `consts` directory, not in model files.
- Organize constants inside `consts` by the model, param, or business responsibility that owns them.
- Do not scatter constants across model, API, service, DAL, helper files, or function bodies.
- Model and upper layers may reference `consts`; model should not import upper layers.
- If a helper needs service, DAL, request context, or framework types, it does not belong in the model layer.
