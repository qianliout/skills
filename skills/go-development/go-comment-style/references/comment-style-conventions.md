# Go Comment Conventions

注释用于解释代码表达不了的原因、约束和边界，不用于翻译标识符。全部用英文，只写 why，尽量单行。

## Core Rules

- Language: English only. 不写中文注释，也不写中英混排。
- Content: why only. 写原因、约束、后果；不写代码在做什么。
- Length: 默认单行，最多两行。一条注释只说一件事。
- Placement: 紧贴被解释的代码；不为一条注释另起段落。

## When To Comment

加注释：
- 业务规则、历史兼容、外部协议、特殊单位。
- 性能、幂等、事务、缓存、并发等非常规约束。
- 看似可删或可简化，但实际不能动的逻辑。

不加注释：
- 字段名、函数名、类型名已经清楚。
- 注释只是复述代码或翻译标识符。
- 注释容易过期且不提供额外约束。

## Why, Not What

Avoid:

```go
// Increment retry count and call the API again.
retry++
return c.call(ctx, req)
```

Good:

```go
// Upstream returns 429 without Retry-After, so back off locally.
retry++
return c.call(ctx, req)
```

## Field Comments

model 常规字段不注释：

```go
ID        int64
UniqueID  string
Name      string
Status    string
CreatedAt int64
UpdatedAt int64
DeletedAt int64
```

需要注释时说明额外语义：

```go
// Raw third-party status; Status is the internal source of truth.
ExternalStatus string

// Millisecond timestamp; 0 means never expires.
ExpireAt int64
```

## Function And Type Comments

避免复述：

```go
func (s *UserSrv) GetUser(ctx context.Context, userID string) (*User, error)
```

说明约束：

```go
// Overwrites the tenant's existing index, so call it only after the import transaction commits.
func (s *UserSrv) RebuildIndex(ctx context.Context, tenantID string) error
```

类型承载状态机、生命周期、外部协议或特殊存储映射时才注释。

## Rewrite Patterns

删除或改写常见的复述型注释：

| 复述型注释 | 处理方式 |
| --- | --- |
| `// ID is the primary key` | 删除 |
| `// GetUser gets a user by ID` | 删除 |
| `// loop over items` | 删除 |
| `// set default value` | 改成为什么需要这个默认值，或删除 |
| `// 兼容老数据` | 改成英文并写清是哪一版行为：`// Rows written before v2 have no tenant_id.` |

## Review Heuristics

- 删除后是否会误解业务约束？
- 是否解释了代码无法表达的原因、边界或历史背景？
- 是否比改名、抽变量、拆函数更合适？
- 是否只是标识符的另一种说法？
- 是否能压到一行英文说完？
