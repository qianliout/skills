---
name: code-quality
description: "代码质量类任务唯一入口和按需规则路由。Use whenever reviewing code changes, assessing correctness, security, maintainability, or deciding when and how to request a code review before merge. Always start here and load only the reference files required by the task."
---

# Code Quality

把这个 Skill 作为全部代码质量任务的唯一入口。先识别当前任务是执行代码审查，还是组织一次代码审查，再只读取需要的 reference；不要一次性读取全部检查规则。

## Workflow

1. 识别任务类型：审查现有改动、评估风险、整理审查输出，或在完成实现后准备请求代码审查。
1. 读取最小必要上下文：`git status`、`git diff`、目标文件、相关测试、需求说明，以及与变更直接相关的调用链。
1. 根据下方路由只读取当前任务需要的 reference；跨场景任务只组合实际涉及的 reference。
1. 默认先给出审查结论和风险，不直接修改代码；只有用户明确要求修复时才进入实现。
1. 如需追溯上游公共 Skill 的原始设计，读取 `../resources/README.md` 与对应镜像目录，不把上游叶子 Skill 当作独立可安装 Skill。

## Reference Routing

- 用户要求 review、审查当前变更、找 bug、识别回归、安全问题、缺少测试、设计问题：读取 `references/code-review-expert.md`。
- 审查范围明确包含 SOLID、架构分层、职责划分、依赖反转：在 `references/code-review-expert.md` 之外补充读取 `references/solid-checklist.md`。
- 审查范围明确包含安全、并发、鉴权、输入输出边界、运行时风险：在 `references/code-review-expert.md` 之外补充读取 `references/security-checklist.md`。
- 审查范围明确包含错误处理、性能、边界条件、可维护性与静默失败风险：在 `references/code-review-expert.md` 之外补充读取 `references/code-quality-checklist.md`。
- 需要评估删除候选、冗余代码下线计划、分阶段移除方案：读取 `references/removal-plan.md`；如同时在做代码审查，再与 `references/code-review-expert.md` 组合。
- 用户要求在任务完成后主动发起代码审查、合并前自检、组织 reviewer prompt、准备审查模板：读取 `references/requesting-code-review.md` 和 `references/code-reviewer-template.md`。

## Routing Rules

- 不默认读取任何 reference；只在任务命中时读取。
- 不把 `resources/` 中的上游镜像目录当作可安装 Skill 或直接触发目标。
- 执行代码审查时，优先输出 findings；摘要、结论和建议放在后面。
- 组织代码审查请求时，目标是生成清晰的审查上下文，不是直接代替 reviewer 下结论。

## Boundaries

- `code-review-expert` 负责静态代码审查的范围界定、严重级别、输出结构和主要检查面。
- `solid-checklist`、`security-checklist`、`code-quality-checklist`、`removal-plan` 只在对应风险维度命中时补充读取。
- `requesting-code-review` 负责何时请求 review、如何准备 review prompt、如何记录评审结论。
- 如果用户明确要求直接修复问题，先完成审查判断，再切回对应技术分类 Skill 处理实现细节。

## Pre-Delivery Checklist

- 只读取了任务需要的代码质量 reference。
- 审查类回复先给出 findings，再给摘要或总评。
- 没有把请求代码审查的流程误当成直接修复流程。
- 如需追溯上游规则，已从 `resources/` 读取原始 Skill，而不是直接安装叶子 Skill。
