# Go Model Conventions

Use this reference when generating general Go model layer definitions. The patterns are extracted from `image.go`, but they are domain-neutral.

## Core Shape

The sample models use rich domain structs rather than passive DTOs. A persistent entity usually owns:

- DB tags with explicit columns.
- JSON tags for API compatibility.
- Runtime-only fields marked `gorm:"-"`.
- Serialized backing fields marked `json:"-"`.
- Lifecycle methods: `Serialize`, `Deserialize`, `Check`, `TableName`.
- Derived identity methods such as `GenUniqueID`, `GenUUID`, `GenCheckSum`.

## Field Pair Pattern

When a complex field must be stored in one DB column:

```go
Config     Config `gorm:"-" json:"config"`
ConfigJSON string `gorm:"column:config" json:"-"`
```

Rules:

- Public runtime object gets `gorm:"-"` and normal `json`.
- DB string gets `gorm:"column:..."` and `json:"-"`.
- `Serialize()` marshals runtime object into DB string.
- `Deserialize()` unmarshals DB string into runtime object.

## ID Pattern

Do not use `uint64` in persistent models. PostgreSQL has no native unsigned 64-bit integer type.

Use `int64` for database-backed IDs and business identities that fit PostgreSQL `bigint`. Return `int64` to the frontend as a JSON number; do not add `,string` to the JSON tag:

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

- `int64`: PostgreSQL `bigint`, timestamps in milliseconds, counts, signed flags, numeric IDs inside signed range.
- `string`: UUID, snowflake IDs, unsigned hash output, external IDs, compound unique keys. These are opaque identifiers, not numeric fields.
- never `uint64` / `uint`: avoid PostgreSQL incompatibility and silent overflow risks.
- never numeric types larger than `int64`: no `big.Int`, decimal big integer, custom large-number type, or unsigned 64-bit type in models.
- never `json:",string"` on `int64`: signed integers are returned as JSON numbers.
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

## Serialization Pattern

`Serialize()` is the single place to normalize and derive:

- Default flag.
- Historical timestamp units.
- JSON backing fields.
- Display/search name.
- Unique ID and compact UUID.
- Denormalized grouping fields.
- Checksum.

## Deserialization Compatibility

`Deserialize()` may contain compatibility rules for old data:

- Normalize legacy enum values.
- Convert second-level timestamps to milliseconds.
- Fill historical default values for fields added after old records were created.
- Rebuild runtime-only fields from JSON backing columns.

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
