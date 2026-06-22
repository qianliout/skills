# Go Comment Conventions

注释用于解释代码表达不了的原因、约束和边界，不用于翻译标识符。

## When To Comment

加注释：
- 业务规则、历史兼容、外部协议、特殊单位。
- 性能、幂等、事务、缓存、并发等非常规约束。
- 看似可删或可简化，但实际不能动的逻辑。

不加注释：
- 字段名、函数名、类型名已经清楚。
- 注释只是中文翻译或复述代码。
- 注释容易过期且不提供额外约束。

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
// ExternalStatus 保留第三方原始状态，内部状态以 Status 为准。
ExternalStatus string

// ExpireAt 使用毫秒时间戳，0 表示永不过期。
ExpireAt int64
```

## Function And Type Comments

避免复述：

```go
func (s *UserSrv) GetUser(ctx context.Context, userID string) (*User, error)
```

说明约束：

```go
// RebuildIndex 会覆盖同租户的旧索引，只能在导入事务提交后调用。
func (s *UserSrv) RebuildIndex(ctx context.Context, tenantID string) error
```

类型承载状态机、生命周期、外部协议或特殊存储映射时才注释。

## Review Heuristics

- 删除后是否会误解业务约束？
- 是否解释了代码无法表达的原因、边界或历史背景？
- 是否比改名、抽变量、拆函数更合适？
- 是否只是字段名或函数名的中文翻译？
