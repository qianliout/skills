# Go Model Conventions

Use this reference when generating general Go model layer definitions. The patterns are extracted from `image.go`, but they are domain-neutral.

## Core Shape

The sample models use rich domain structs rather than passive DTOs. A persistent entity usually owns:

- DB tags with explicit columns.
- JSON tags for API compatibility.
- Runtime-only fields marked `gorm:"-"`.
- Serialized text backing fields marked `json:"-"` when a runtime complex structure is stored in a string text column.
- Lifecycle methods: `Serialize`, `Deserialize`, `Check`, `TableName`.
- Derived identity methods such as `GenUniqueID`, `GenUUID`, `GenCheckSum`.

Model-layer ownership includes model structs, param structs, model-related constants, validation, serialization, deserialization, derived fields, and update field selection. These behaviors should usually be methods on the specific model type, such as `(m *Xxx) Check()` or `(m *Xxx) Serialize()`, rather than loose helpers with no owner.

The model package should stay low-level. It may depend on the standard library, external foundational libraries, and project `utils`; it should not depend on API, service, DAL, or other business-layer packages.

## Database Compatibility

Model design must consider database compatibility first.

Rules:

- Do not use database complex types such as JSON/JSONB, arrays, maps, or object columns as persistent model fields.
- Persistent fields should use broadly compatible primitive database types: signed integers, strings/text, timestamps, and simple status strings.
- Complex structures may be stored in `string` text columns with `Serialize()` / `Deserialize()`.
- Split complex structures into normal columns or relation tables when they need frequent filtering, indexing, partial update, or database constraints.
- Runtime complex fields must be marked `gorm:"-"`.

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

Use `int64` for database-backed IDs and business identities that fit PostgreSQL `bigint`:

```go
UniqueID int64 `gorm:"column:unique_id" json:"uniqueID"`
```

Do not introduce numeric types larger than `int64`. If an external identifier is larger than `int64`, produced by unsigned hashing, comes from a snowflake generator, or must preserve lexical form, model it as an opaque `string` identifier, not as a number:

```go
UniqueID string `gorm:"column:unique_id" json:"uniqueID"`
```

Generate source-specific IDs from stable business keys:

- Tenant-scoped resource: tenant ID + business code + resource type.
- Parent-scoped resource: parent ID + name/code + version + resource type.
- Content-addressed resource: normalized display name + digest/checksum + resource type.

If a source type intentionally has no generated ID, document it.

Type rules:

- Numeric fields in structs use `int64` by default unless there is a clear exception.
- `int64`: PostgreSQL `bigint`, timestamps in milliseconds, counts, signed flags, numeric IDs inside signed range.
- `string`: UUID, snowflake IDs, unsigned hash output, external IDs, compound unique keys, and serialized text. These are opaque identifiers or text payloads, not numeric fields.
- Other numeric types require an explicit reason, such as external protocol compatibility, third-party library signatures, byte-size data, or an established local convention.
- never `uint64` / `uint`: avoid PostgreSQL incompatibility and silent overflow risks.
- never numeric types larger than `int64`: no `big.Int`, decimal big integer, custom large-number type, or unsigned 64-bit type in models.
- never database JSON/JSONB, arrays, maps, or complex object columns as persistent fields.
- never `bool`: binary status fields use `string` with values `"true"` / `"false"`.

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
3. Fill safe derived fields such as display name or unique ID.
4. Require common identity fields such as name/code/type/version.
5. Require context-specific fields such as tenant ID, project ID, parent ID, or external ID.

`Check()` belongs with the model or param it validates. Do not repeat the same validation in API, service, or DAL.

## Serialization Pattern

`Serialize()` is the single place to normalize and derive:

- Default flag.
- Historical timestamp units.
- Serialized text backing fields.
- Display/search name.
- Unique ID and compact UUID.
- Denormalized grouping fields.
- Checksum.

Do not generate these model-derived values in API, service, or DAL. Upper layers should call the model method and consume the normalized result.

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
func (m *Resource) TableName() string {
    return "app_resource"
}
```

`ToUpdater()` returns a map of explicitly updateable columns and updates `updated_at` with `time.Now().UTC().UnixMilli()`.

## Layering Examples

- Entity: `Resource`, `Rule`, `CacheInfo`.
- Param/command: `SearchResourceParam`, `UpdateResourceParam`, `CreateRuleParam`.
- Detail/value object: `ResourceDetail`, `ConfigItem`, `ExternalRef`.
- Statistic/view: `ResourceStatistic`, `ResourceOverview`, `IssueStatic`, `Suggest`.
- Cache snapshot: `PrepareData`, `CacheInfo`.

## Constants And Dependencies

- Define model-related constants, enum values, default values, and field value constraints in the model layer.
- Keep constants close to the model or param that owns them, and manage them in one consistent place by responsibility.
- Do not scatter model-related constants across API, service, DAL, helper files, or function bodies.
- Upper layers may reference model constants; model should not import upper layers.
- If a helper needs service, DAL, request context, or framework types, it does not belong in the model layer.
