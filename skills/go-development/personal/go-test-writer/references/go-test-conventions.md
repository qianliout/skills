# Go Test Conventions

Use this reference when creating or extending Go `_test.go` files.

## Default Library

默认使用 `https://github.com/stretchr/testify`。

- 结果比对、集合比对、错误语义和 Eventually/Never 断言优先用 `assert`。
- 当前 case 无法继续时，前置条件、关键错误、关键对象非 nil 等断言优先用 `require`。
- 需要验证接口交互时，优先用 `mock`。
- 默认不要用 `suite`；只有项目已统一使用，或确实需要共享 setup/teardown 生命周期时才引入。

选择规则：

- `assert` 失败后测试继续，适合同一 case 内收集多个结果差异。
- `require` 失败后当前 test/subtest 立即终止，适合 guard 条件。
- `require` 必须在运行该 test 或 benchmark 的 goroutine 中调用，不要在测试自行启动的 goroutine 里调用。
- `suite` 官方不支持并行测试；使用 `suite` 时不要再配合 `t.Parallel()`。

## Test Target

先验证行为，再考虑实现。一个测试应回答这几个问题：

- 输入是什么。
- 触发了什么行为。
- 期望输出、错误或副作用是什么。
- 为什么这个场景值得覆盖。

优先覆盖：

- 主流程和关键业务分支。
- 边界值、空值、非法输入。
- 错误返回和异常分支。
- 历史 bug 对应的回归场景。
- 容易被重构破坏的编排逻辑。

避免优先覆盖：

- 纯 getter/setter。
- 没有业务判断的薄封装。
- 只是在复述当前实现步骤的断言。
- 对外不可观察、且未来可自由重构的内部细节。

## File And Naming

- 测试文件名使用 `<name>_test.go`。
- 测试函数使用 `TestXxx`。
- 子场景优先使用 `t.Run("scenario", func(t *testing.T) {})`。
- 场景名写清楚输入和预期，例如 `invalid status returns error`、`empty result returns initialized slice`。
- 一个测试函数聚焦一类行为；不要把完全不相关的断言塞进同一个测试里。

## Preferred Shape

优先 table-driven test：

```go
import (
    "testing"

    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestCheckStatus(t *testing.T) {
    t.Parallel()

    cases := []struct {
        name    string
        input   string
        wantErr bool
    }{
        {
            name:    "valid status",
            input:   "enabled",
            wantErr: false,
        },
        {
            name:    "empty status",
            input:   "",
            wantErr: true,
        },
    }

    for _, tc := range cases {
        tc := tc
        t.Run(tc.name, func(t *testing.T) {
            t.Parallel()

            err := checkStatus(tc.input)
            if tc.wantErr {
                require.Error(t, err)
                assert.ErrorContains(t, err, "status")
                return
            }
            require.NoError(t, err)
            assert.NotEmpty(t, tc.input)
        })
    }
}
```

规则：

- 用例字段只保留对阅读有帮助的输入和期望。
- `name` 直接描述场景，不要写 `case1`、`test2`。
- 同一 case 里优先 `require` 前置、再 `assert` 结果。
- 断言信息必须包含关键输入和实际结果，方便定位失败原因。
- 是否使用 `t.Parallel()` 取决于测试是否共享状态、环境变量、临时目录、全局 mock 或数据库。

## Assertions

- 默认导入：

```go
import (
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)
```

- 同一个测试里断言较多时，优先使用 `as := assert.New(t)`、`req := require.New(t)`。
- 先断言错误，再断言结果值，避免在错误路径读取无效结果。
- 错误类型或包装链优先用 `require.ErrorIs`、`assert.ErrorIs`；稳定子串优先用 `assert.ErrorContains`。
- slice/map 长度优先用 `assert.Len`；无序集合优先用 `assert.ElementsMatch`。
- 复杂结构体优先断言关键字段；只有结构稳定且项目已有约定时才做整体 `assert.Equal`。
- 异步条件优先用 `assert.Eventually`、`assert.EventuallyWithT` 或 `assert.Never`，不要手写 sleep 轮询。
- `assert.NotNil` 返回 `bool`，只有确实要在对象非 nil 时继续细查时，才利用这个返回值做后续分支。

常见模式：

```go
func TestBuildUser(t *testing.T) {
    req := require.New(t)
    as := assert.New(t)

    user, err := BuildUser("u-1")
    req.NoError(err)
    req.NotNil(user)

    as.Equal(int64(1), user.Version)
    as.Equal("u-1", user.ID)
}
```

## Determinism

测试必须可重复、可并行控制、对环境敏感度低。

- 时间：优先注入时钟、固定时间戳或 stub `now` 方法。
- 随机：固定 seed，或注入随机源。
- IO/网络/DB：优先使用接口注入、fake、stub、fixture 或项目现有 mock 方式。
- 并发：不要依赖 `time.Sleep` 猜测时序，优先 `channel`、`WaitGroup`、context 或可观测同步点。
- 临时资源：使用 `t.TempDir()`、`t.Setenv()` 等测试隔离能力。

## Mocks And Fakes

- 先复用项目现有 mock 生成方式、手写 stub 模式或测试 helper；如果没有统一方案，默认可用 `testify/mock`。
- mock 只表达当前测试必需的交互，不把所有接口方法都实现成大而全模板。
- 基础模式是 `m.On("Method", args...).Return(...).Once()`，测试结束前调用 `m.AssertExpectations(t)`。
- 参数不稳定时优先用 `mock.MatchedBy(...)` 精确匹配关键字段；只有确实不关心参数时才用 `mock.Anything`。
- 需要验证参数类型时用 `mock.AnythingOfType("string")` 这类构造器，不直接依赖其底层实现类型。
- 需要修改传入指针或输入参数时，可用 `Run(func(args mock.Arguments) {})` 模拟副作用。
- 优先 stub 返回值和错误，不把调用顺序断言写得过细，除非顺序本身就是业务要求。
- 对外部依赖的断言应聚焦关键交互，例如是否调用、调用参数是否正确、错误是否上抛。

示例：

```go
type userRepoMock struct {
    mock.Mock
}

func (m *userRepoMock) Save(ctx context.Context, user *User) error {
    args := m.Called(ctx, user)
    return args.Error(0)
}

func TestCreateUser(t *testing.T) {
    repo := new(userRepoMock)
    repo.On("Save", mock.Anything, mock.MatchedBy(func(user *User) bool {
        return user != nil && user.Name == "alice"
    })).Return(nil).Once()

    err := CreateUser(context.Background(), repo, "alice")
    require.NoError(t, err)
    repo.AssertExpectations(t)
}
```

## Suite

- 默认不引入 `testify/suite`。
- 只有项目已经统一采用 suite 风格，或同一组测试确实需要稳定复用 setup/teardown、共享夹具对象时才使用。
- 使用 suite 时，优先通过 `SetupTest`、`TearDownTest`、`SetupSuite`、`TearDownSuite` 管理生命周期。
- suite 中优先使用 `s.Require()` 和 `s.Assert()` 获取断言上下文。
- 因为 `suite` 官方不支持并行测试，所以 suite 用例里不要再调用 `t.Parallel()`，也不要把它作为默认模板。

## Production Code Changes

为了可测性允许做最小改动，但必须满足：

- 不改变业务行为。
- 不为了测试暴露无必要的公开 API。
- 优先通过依赖注入、接口抽象、可替换时间源、helper 提取来提升可测性。
- 不在业务逻辑里加入只为测试存在的分支。

## Package Choice

- 默认与被测代码保持同包测试，便于访问未导出符号和复用现有测试风格。
- 只有明确需要从外部视角验证公开 API、避免访问私有实现，或项目已有统一约定时，才使用 `_test` 外部包。

## Review Heuristics

检查一个测试是否值得保留：

- 删掉它后，是否会失去对重要行为、边界或回归风险的保护。
- 它是否验证了对外可观察结果，而不是实现细节。
- 它是否稳定，不依赖偶然时序或环境。
- 它是否正确区分了 `require` 的终止型断言和 `assert` 的继续型断言。
- 它的 mock 是否只约束关键交互，而不是把实现细节全部硬编码。
- 失败时日志是否足够定位问题。
- 它是否和现有测试风格、命名、组织方式一致。
