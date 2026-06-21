# Architecture Decision Records

编写和维护架构决策记录（ADR），保存重要技术决策的背景、选项和结果。用于记录重大技术决策、评审历史架构选择、建立决策流程。

## When To Load

- 需要记录重大技术决策（框架选型、数据库选择、API 设计模式、安全架构、集成方案）
- 需要评审历史架构选择、理解"当初为什么这么设计"
- 需要建立团队决策流程和 ADR 管理规范
- 新成员入职需要了解架构决策上下文
- 需要废弃或取代已有的架构决策

## ADR 生命周期

```
Proposed → Accepted → Deprecated → Superseded
              ↓
           Rejected
```

## 何时写 ADR

| 写 ADR                            | 不写 ADR                    |
| --------------------------------- | --------------------------- |
| 新框架/技术选型                   | 小版本升级                  |
| 数据库技术选型                    | Bug 修复                    |
| API 设计模式决策                  | 实现细节                    |
| 安全架构决策                      | 日常维护                    |
| 集成方案选型                      | 配置变更                    |

## 模板

### 标准 ADR（MADR 格式）

```markdown
# ADR-NNNN: 标题

## Status

Proposed / Accepted / Deprecated / Superseded / Rejected

## Context

描述要解决的问题、约束条件和相关利益方。说明为什么需要做这个决策。

## Decision Drivers

- **必须满足**：列出强制性需求
- **应该满足**：列出期望但非强制性需求

## Considered Options

### Option 1: [名称]

- **优点**：...
- **缺点**：...
- **团队经验**：...

### Option 2: [名称]

...（至少列出两个备选方案）

## Decision

明确写出选择了哪个方案。

## Rationale

解释为什么选择这个方案，权衡了哪些因素。

## Consequences

### 正面影响

- ...

### 负面影响

- ...

### 风险与缓解

- 风险：... → 缓解：...

## Implementation Notes

实施要点和注意事项。

## Related Decisions

- ADR-NNNN: 标题（关系说明）
```

### 轻量 ADR

适用于范围明确、争议较小的决策：

```markdown
# ADR-NNNN: 标题

**Status**: Accepted | **Date**: YYYY-MM-DD | **Deciders**: @人员列表

## Context

简要描述问题背景。

## Decision

明确写出决策。

## Consequences

**正面**: ...
**负面**: ...
**缓解**: ...
```

### Y-Statement 格式

适用于一句话摘要：

```markdown
在 **<上下文>** 的背景下，
面对 **<需要解决的问题>**，
我们选择了 **<决策方案>**，
而非 **<备选方案>**，
以达到 **<目标效果>**，
并接受 **<代价或权衡>**。
```

### 废弃 ADR

```markdown
# ADR-NNNN: 废弃 [旧方案] 改用 [新方案]

## Status

Accepted (Supersedes ADR-MMMM)

## Context

说明为什么旧决策不再适用。

## Decision

明确写出新决策。

## Migration Plan

1. Phase 1: ...
2. Phase 2: ...
3. Phase 3: ...

## Consequences

### 正面
- ...

### 负面
- ...

## Lessons Learned

从旧决策中学到的经验。
```

## ADR 管理

### 目录结构

```
docs/
├── adr/
│   ├── README.md           # 索引和编写指南
│   ├── template.md         # 团队 ADR 模板
│   ├── 0001-use-postgresql.md
│   ├── 0002-caching-strategy.md
│   └── ...
```

### ADR 索引示例

```markdown
# Architecture Decision Records

| ADR | Title | Status | Date |
| --- | ----- | ------ | ---- |
| [0001](0001-use-postgresql.md) | Use PostgreSQL as Primary Database | Accepted | 2024-01-10 |
| [0002](0002-caching-strategy.md) | Caching Strategy with Redis | Accepted | 2024-01-12 |
| [0003](0003-mongodb-user-profiles.md) | MongoDB for User Profiles | Deprecated | 2023-06-15 |
```

### 评审检查清单

- [ ] 上下文清晰地解释了问题
- [ ] 所有可行方案都被考虑
- [ ] 优缺点平衡且诚实
- [ ] 正负面后果都已记录
- [ ] 相关 ADR 已链接
- [ ] 至少 2 名资深工程师评审
- [ ] 安全影响已评估
- [ ] 成本影响已记录
- [ ] 可逆性已评估

## 最佳实践

**应该做：**
- 在实现之前写 ADR
- 保持简洁：1-2 页即可
- 坦诚记录权衡和真实的缺点
- 链接相关决策，构建决策图谱
- 当决策被取代时更新状态

**不应该做：**
- 不要修改已接受的 ADR——写新的来取代
- 不要跳过上下文——未来读者需要背景
- 不要隐藏失败——被拒绝的决策同样有价值
- 不要模糊——明确的决策，明确的后果
- 不要忘记实施——没有行动的 ADR 是浪费

## Upstream Tracking

- 原始 Skill 的仓库地址、上游路径和本地镜像目录见 `../../resources/README.md`。
- 如需核对原始行为，读取 `../../resources/architecture-decision-records/SKILL.md`。
