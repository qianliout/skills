# Requesting Code Review

在完成任务、进入合并前、或希望用结构化 prompt 发起代码审查时使用。

## When To Use

- 完成一个明确任务后，希望在继续前先做一次审查。
- 完成较大功能、复杂重构、疑难 bug 修复后，需要第二视角检查。
- 准备合并前，希望确认实现满足需求且没有明显遗漏。

## Workflow

1. 先说明本次变更的目标、范围和需求来源。
1. 确定 review 范围，优先使用明确的 `git diff` 范围、提交区间或文件列表。
1. 使用 `references/code-reviewer-template.md` 组织 reviewer prompt。
1. 拿到 findings 后，区分必须立刻修复的问题和可以排期的建议。
1. 如果 reviewer 判断与事实不符，基于代码和测试进行澄清，而不是机械照单全收。

## Rules

- 请求 review 的目的，是让 reviewer 聚焦工作产物和需求，不是复述完整会话历史。
- prompt 中必须写清楚实现目标、需求来源和 review 边界。
- 如果变更很大，优先按模块或阶段拆分 review，而不是一次丢给 reviewer 全仓库。
- 未经用户确认，不要把“准备 review”自动升级为“直接修复所有问题”。
