---
name: architecture-planning
description: "架构与规划类任务唯一入口和按需规则路由。Use whenever writing Architecture Decision Records, designing or refactoring backend architecture (Clean/Hexagonal/DDD), or breaking down complex projects into tasks with timelines and milestones. Always start here and load only the reference files required by the task."
---

# Architecture Planning

把这个 Skill 作为全部架构设计与项目规划任务的唯一入口。先识别任务属于三种场景中的哪一种，再只读取当前任务需要的 reference；不要一次性读取全部架构规则。

## Workflow

1. 识别任务类型：编写或维护架构决策记录（ADR）、设计或重构后端架构（Clean Architecture / Hexagonal / DDD）、或将大型项目拆解为阶段、任务、依赖和里程碑。
1. 读取就近上下文：现有架构文档、项目结构、技术栈说明、团队规模与约束、已有决策记录。
1. 根据下方路由只读取当前任务需要的 reference；跨场景任务只组合实际涉及的 reference。
1. 输出前确认产物格式（ADR 模板、架构分层图、项目计划表）与用户预期一致。
1. 如需核对上游公共 Skill 的原始设计，读取 `../resources/README.md` 中记录的仓库与本地镜像目录，不直接把上游 Skill 当作可安装 Skill 使用。

## Reference Routing

- 需要记录重大技术决策、评审历史架构选择、建立决策流程、编写 ADR：读取 `references/architecture-decision-records.md`。
- 设计新服务或微服务的分层架构、重构单体应用为限界上下文、实现六边形或洋葱架构、调试层间依赖循环：读取 `references/architecture-patterns.md`。
- 进行项目范围定义、工作拆解（WBS）、任务依赖分析、时间线估算、里程碑规划、资源分配、风险评估：读取 `references/project-planner.md`。
- 架构设计完成后需要规划实施阶段和里程碑：先读取 `references/architecture-patterns.md` 完成设计，再读取 `references/project-planner.md` 完成计划。
- 项目计划中涉及架构决策：先读取 `references/project-planner.md` 确定规划框架，再读取 `references/architecture-decision-records.md` 记录关键决策。

## Routing Rules

- 不默认读取任何 reference；只在任务命中时读取。
- 不把 `resources/` 中跟踪的上游仓库当作直接可调用 Skill。
- 架构设计与项目规划的输出格式不同，不混用模板。
- ADR 面向决策记录和追溯，架构模式面向代码结构和依赖规则，项目规划面向时间线和资源分配——三者各司其职。

## Boundaries

- `architecture-decision-records` 负责 ADR 模板、状态流转、决策评审流程和最佳实践。
- `architecture-patterns` 负责 Clean Architecture 分层、六边形架构端口与适配器、DDD 战术模式（实体、值对象、聚合、领域事件）、限界上下文和防腐层。
- `project-planner` 负责项目阶段拆解、任务尺寸控制、依赖映射、时间估算、里程碑、风险矩阵和资源分配。
- 具体代码实现、框架选择、数据库设计等属于对应技术分类 Skill 的范围，不在本 Skill 内展开。

## Pre-Delivery Checklist

- 只读取了任务需要的架构或规划 reference。
- ADR 输出使用正确的模板格式和状态标记。
- 架构设计输出明确了分层、依赖方向和接口边界。
- 项目计划输出包含里程碑、任务依赖、风险矩阵和资源估算。
- 如需追溯上游规则，已从 `resources/` 读取原始 Skill，而不是直接安装叶子 Skill。
