# Go Test Writer

Go 测试必须验证可观察行为。每个测试必须覆盖输入、行为及输出、错误或副作用；无断言测试、只打印日志测试和只复述实现步骤的测试一律删除。

## 测试范围

- 必须先读被测代码与相邻测试，确认公开行为、输入输出、副作用、依赖边界和项目既有风格。
- 必须覆盖主流程、每个错误返回、关键边界、分支条件和历史 bug 回归场景。
- 错误路径必须断言错误存在；错误类型、包装链或稳定语义存在时，必须用 `ErrorIs`、`ErrorAs` 或 `ErrorContains` 验证。
- 必须断言返回值、状态变化或对外可观察副作用。只执行函数、只检查不 panic、只打印结果均不构成测试。
- 禁止为 getter/setter、纯转发薄封装、不可观察私有细节或实现顺序凑覆盖率。测试必须保护业务行为和回归风险。
- 生产代码可测性不足时，必须以依赖注入、接口、fake、stub、固定时钟或 helper 做最小调整；禁止新增只供测试调用的业务分支或无必要公开 API。

## 文件、命名与表驱动

- 测试文件必须命名为 `<name>_test.go`，测试函数必须命名为 `TestXxx`。
- 同类输入与预期必须写成 table-driven test；每个 case 必须有描述输入和预期的 `name`，禁止使用 `case1`、`test2`。
- 每个 case 必须通过 `t.Run` 独立执行，并声明必要输入和期望；禁止把不相关行为塞进同一个 case。
- 表中必须同时含成功、错误和边界 case；被测行为不存在错误路径时，必须明确该事实并覆盖可达边界。
- 测试是否并行必须由共享状态决定。读取或修改全局变量、环境变量、临时资源、mock、数据库或共享 fixture 时，禁止 `t.Parallel()`。

```go
func TestCheckStatus(t *testing.T) {
	cases := []struct {
		name    string
		input   string
		wantErr bool
	}{
		{name: "enabled status succeeds", input: "enabled"},
		{name: "empty status returns error", input: "", wantErr: true},
	}

	for _, tc := range cases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
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

## testify 断言

- 必须使用项目既有断言库；项目无硬约束时必须使用 `github.com/stretchr/testify`。
- `require` 只用于失败后当前 case 无法继续的前置条件、关键错误、关键对象非 nil 和依赖构造；`require` 失败后必须停止后续无效访问。
- `assert` 用于同一 case 内可继续收集的结果细节；必须断言真实结果，禁止把 `assert` 返回值当作已终止保护。
- `require` 必须在运行 test 或 subtest 的 goroutine 中调用；禁止在测试自行启动的 goroutine 中调用。
- 断言错误前必须先处理或断言错误；禁止在错误路径继续读取无效结果。
- 错误链必须用 `require.ErrorIs` 或 `assert.ErrorIs`；稳定错误文本必须用 `ErrorContains`，禁止断言未约定的完整错误文案。
- slice、map 和无序集合必须分别使用 `Len`、键值断言或 `ElementsMatch`；禁止依赖 map 遍历顺序。
- 结构体必须断言业务关键字段；整体 `Equal` 仅在完整结构是稳定外部契约时使用。

## mock、fake 与交互

- 外部依赖可用 fake、stub 或 fixture 覆盖时，禁止引入 mock；需要验证接口交互时必须使用 `testify/mock` 或项目既有 mock 方案。
- mock 期望必须只描述当前 case 必需的关键调用、参数和返回值；禁止把所有接口方法、内部调用顺序或实现细节镜像进 mock。
- 每个配置过期望的 mock 必须在 case 结束前执行 `AssertExpectations(t)`。
- 参数需验证时必须使用精确值或 `mock.MatchedBy`；`mock.Anything` 只允许用于业务确实不关心的参数。
- 错误返回必须由 mock/fake 显式构造并被测试断言上抛、转换或处理后的可观察结果。

## 确定性与并发

- 禁止使用 `time.Sleep`、循环等待或超时窗口赌同步时序。
- 并发同步必须使用 channel、`sync.WaitGroup`、`context`、可观测回调或受控同步点；异步结果必须有断言。
- 时间必须注入时钟、固定时间戳或 stub `now`；随机性必须固定 seed 或注入随机源。
- 网络、文件、数据库和 IO 必须使用接口注入、fake、stub、fixture 或项目既有测试设施；临时资源必须使用 `t.TempDir()`、`t.Setenv()` 等隔离能力。
- `assert.Eventually`、`EventuallyWithT` 或 `Never` 只能等待可观测条件，不能替代同步设计；条件本身必须包含断言。
- `testify/suite` 禁止作为新测试默认结构。项目统一使用 suite 或稳定共享生命周期确有必要时才可使用；使用 suite 时禁止 `t.Parallel()`。

## 包与交付

- 测试包必须保持与项目相邻测试一致；需要从外部视角验证公开 API 时才使用 `_test` 外部包。
- 修改后必须运行最小必要范围的 `go test`；能定位包或单测名时必须精确执行。
- 交付前必须确认：每个新增或修改 case 有断言，主流程、错误路径和关键边界均已覆盖，mock 期望已验证，测试不依赖偶然时序或环境。
