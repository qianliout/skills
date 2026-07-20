---
name: go-test-writer
description: "Go 测试编写 Skill。Use when creating, extending, reviewing, debugging, or explaining Go _test.go files, table-driven tests, testify assert/require/mock, mocks/fakes, deterministic tests, error-path tests, and package-level go test verification."
---

# Go Test Writer

用于创建、补全、评审和排查 Go `_test.go`。目标是覆盖真实业务分支、错误路径和边界条件，而不是机械凑覆盖率。

## Workflow

1. 确认测试目标：公开行为、输入输出、副作用、依赖边界、已有测试风格，以及是否只允许新增测试。
2. 读取 `references/test-writer.md` 和 `references/test-writer-conventions.md`。
3. 读取被测代码与相邻测试；测试对象属于 API、Service、DAL、Model 等层时，再按需使用对应 Go 分类 Skill。
4. 优先设计 table-driven test，覆盖主流程、错误返回、边界输入、分支条件和回归风险。
5. 默认使用 `testify`：普通结果断言用 `assert`，关键前置和必须终止当前 case 的断言用 `require`，接口交互用 `mock`。
6. 修改后运行最小必要范围 `go test`；能定位到包或单测名时优先精确执行。

## Test Boundaries

- 优先测试公开函数、公开方法和稳定领域行为，少测没有业务价值的私有实现细节。
- 避免脆弱断言：不要依赖 map 遍历顺序、未约定错误文案、sleep 时间窗或不稳定时间戳。
- 默认不使用 `testify/suite`，除非项目已有统一 suite 风格或确有稳定 setup/teardown 需求。
- 能不改生产代码就不改；必须为可测性调整时只做最小改动。

## Pre-Delivery Checklist

- 已读取本 Skill 的两个 reference、被测代码和相邻测试。
- 测试覆盖行为、错误路径和关键边界，而不是复述实现细节。
- 测试保持确定性，断言和 mock 期望最小化。
- 已运行最小必要范围 `go test`，或说明无法运行原因。
