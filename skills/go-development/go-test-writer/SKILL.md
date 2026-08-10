---
name: go-test-writer
description: "用于创建、补全、评审、排查或解释 Go _test.go、表驱动测试、testify 或 mock 时。"
---

# Go Test Writer

测试必须覆盖真实分支、错误路径与边界。禁止为刷覆盖率写无断言测试。

## 强制工作流

1. 必须先经 `$go`。
2. 必须读 `references/test-writer.md`。
3. 被测对象属于某层时必须加载对应层 `go-*`。
4. 默认表驱动；`assert`/`require`/`mock` 按 reference 强制选用。
5. 修改后必须跑最小必要 `go test`；能定位包或单测名时必须精确执行。

## 禁止清单

- 禁止 `time.Sleep` 赌时序。
- 禁止无断言或只打印的测试。
- 禁止跳过错误路径。

## 交付门禁

- 已读 test-writer reference 与所需层 Skill。
- 相关 `go test` 已通过，或无法运行时已说明原因。
