# Task 9 Report

- 已将 `go-test-writer` 收敛为单个中文硬规则 reference，并删除 `test-writer-conventions.md`。
- `SKILL.md` 已改为 `$go` 路由、强制工作流、禁止清单与交付门禁；OpenAI 元数据已更新。
- reference 覆盖表驱动、`testify/assert`、`require`、`mock`、同步禁用 `time.Sleep`、错误路径和断言门禁。
- 已确认无旧 conventions 引用，且无断言与只打印测试均被禁止。
- Ruby YAML 校验与 `git diff --check` 通过。
- `bash scripts/check.sh` 仍因既有独立 `skills/gin-openapi-json` 被全局门禁拒绝，与本任务无关。
- 已提交 `87ba1df`：`Consolidate go-test-writer into a single Chinese hard-rule reference.`
- 已修正 `assert.Eventually`：`func() bool` 回调禁止断言；等待中断言必须使用 `EventuallyWithT` 的 `CollectT`。
- 已区分 `ErrorIs` 的 sentinel/包装身份匹配与 `ErrorAs` 的 typed error 提取验证。
- 已限制 `t.Parallel()` 禁令至共享可变状态或非隔离资源；case-local mock 与 `t.TempDir()` 隔离资源必须允许并行。
