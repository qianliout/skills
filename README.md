# Skills

这个仓库统一维护 Skill 和 MCP。Skill 的目标是：尽量复用公共 Skill，按能力类型整理成本地入口，最后通过一个命令安装到 `~/.agents/skills`；MCP 按公共和私有分别维护服务与配置。

## 维护目标

1. 公共优先：已有可靠公共 Skill 时，优先跟踪上游，不重复手写。
2. 类型整理：面向 Agent 安装的是按类型聚合后的入口 Skill；细粒度公共 Skill 可以作为入口 Skill 的 `references/` 或 `resources/`。
3. 一键安装：`./scripts/install.sh` 是唯一安装入口，负责更新公共来源、校验、清空并重装 `~/.agents/skills`。

## 目录结构

```text
mcps/
├── private/
├── public/
└── profiles.json
scripts/
├── check.sh
├── clean.sh
├── install.sh
└── update-public.sh
skills/
├── ai-learning/
├── architecture-planning/
├── code-quality/
├── documents/
├── frontend-web/
├── go-development/
├── manifests/
├── operations/
└── skill-management/
```

`skills/` 和 `mcps/` 是两个独立的维护边界。Skill manifest 只放在 `skills/manifests/`，MCP 配置只放在 `mcps/`。

Skill 分类目录不再把 `personal` 和 `public` 作为长期结构规则。已经迁移到新结构的分类，直接在分类目录下放入口 Skill 目录和 `resources/`；仍未迁移的历史目录会逐步清理。

有 Git 上游且仍以独立 Skill 安装的能力，继续通过 `skills/manifests/` 管理，源码拉取到项目根目录的 `.sources`。已经迁移为“分类入口 Skill + references”的分类，则在各自目录下使用 `resources/README.md`、`resources/update.sh` 和本地镜像目录跟踪上游 Skill 目录。Codex、Claude 等工具自带的 Skill 不在本仓库登记或维护。

## 来源模型

| 类型 | 位置 | 是否安装 | 是否提交上游源码 | 用途 |
| ---- | ---- | -------- | ---------------- | ---- |
| 本地入口 Skill | `skills/<category>/<skill>/SKILL.md` | 是 | 是 | 按类型聚合后的 Agent 入口 |
| manifest 公共 Skill | `skills/manifests/*.txt` + `.sources/<repo>` | 是 | 否 | 仍适合独立安装的公共 Skill |
| 分类资源 Skill | `skills/<category>/resources/` | 否 | 是，仅同步所需上游 Skill 子目录 | 给入口 Skill 追溯设计、提炼 reference |
| 工具内置 Skill | Codex/Claude/插件目录 | 否 | 否 | 由对应工具维护 |

安装目录是扁平命名空间：`~/.agents/skills/<skill-name>`。分类目录不会被复制到安装目录。

## Skill 清单

| 分类 | 当前入口或已安装 Skill | Git 上游跟踪 |
| ---- | --------------------- | ------------ |
| `operations` | alibabacloud-sysom-diagnosis | - |
| `go-development` | go、go-api-layer、go-code-style、go-comment-style、go-gin-openapi-json、go-logging、go-model-hierarchy、go-query-dal、go-service-layer、go-test-writer | - |
| `architecture-planning` | architecture-planning | architecture-decision-records、architecture-patterns、project-planner |
| `code-quality` | code-quality | code-review-expert、requesting-code-review |
| `frontend-web` | frontend-design、vercel-react-best-practices、web-design-guidelines | manifest |
| `documents` | documents | lark-markdown、obsidian-markdown |
| `skill-management` | find-skills | manifest |
| `ai-learning` | sigma | manifest |
| `development` | brainstorming、dispatching-parallel-agents、finishing-a-development-branch、receiving-code-review、requesting-code-review、subagent-driven-development、systematic-debugging、test-driven-development、using-git-worktrees、using-superpowers、verification-before-completion、writing-plans、writing-skills | manifest（obra/superpowers） |

当前安装 33 个不同名称的 Skill：15 个本地入口 Skill + 18 个 manifest 公共 Skill。Superpowers 是一套完整的软件开发方法论，包含 brainstorming（需求澄清）→ writing-plans（计划编写）→ subagent-driven-development（子代理驱动开发）→ requesting-code-review（代码审查）→ finishing-a-development-branch（完成分支）的完整工作流，外加 systematic-debugging（系统化调试）、test-driven-development（TDD）、writing-skills（Skill 编写）等辅助能力。`executing-plans` 因与 `subagent-driven-development` 功能重叠且仅适用于无子代理的工具，未纳入安装清单。

`go-development/go` 保持为大而全的 Go 入口 Skill；同目录新增的 `go-*` Skill 是按职责拆分后的细粒度入口，分别覆盖通用风格、API、Service、DAL、Model、日志、注释、测试和 Gin OpenAPI JSON。安装目录是扁平命名空间，因此这些拆分后的 Skill 使用全局唯一名称。

`skill-forge` 已被 Superpowers 的 `writing-skills` 替代，不再单独安装。

## 面向运维工作的分类视图

这部分不改变安装结构，只作为日常选择 Skill 的场景索引。运维任务优先从“诊断、变更、交付、复盘”四类进入，再按实际技术栈补充开发和文档能力。

| 运维场景 | 推荐 Skill | 使用边界 |
| -------- | ---------- | -------- |
| 云主机系统诊断 | `alibabacloud-sysom-diagnosis` | ECS CPU、内存、IO、网络、负载、内核和稳定性问题，优先使用 SysOM 诊断结论 |
| 故障排查方法 | `systematic-debugging` | 面对异常现象、测试失败、线上问题时，先收集证据再定位根因 |
| 变更前规划 | `brainstorming`、`writing-plans` | 新增能力、调整架构、复杂运维自动化前，先明确目标、约束和步骤 |
| 并行推进任务 | `dispatching-parallel-agents`、`subagent-driven-development` | 多个独立排查、验证或改造任务可以拆开并行处理 |
| Go 运维平台开发 | `go`、`go-api-layer`、`go-service-layer`、`go-query-dal`、`go-model-hierarchy`、`go-logging`、`go-test-writer`、`gin-openapi-json`、`go-gin-openapi-json` | 维护 Go 后端、Gin 接口、GORM 查询、日志、测试和 OpenAPI 文档 |
| 架构与方案设计 | `architecture-planning` | 设计监控、诊断、发布、自动化平台等系统方案或 ADR |
| 代码质量与评审 | `code-quality`、`requesting-code-review`、`receiving-code-review` | 合并前审查正确性、安全性、可维护性，或处理 reviewer 反馈 |
| 交付前验证 | `test-driven-development`、`verification-before-completion` | 重要修复和变更完成前，补齐测试和验证证据 |
| 分支收尾 | `finishing-a-development-branch`、`using-git-worktrees` | 分支完成后整理提交、PR、合并或隔离实验工作区 |
| 运维文档沉淀 | `documents` | 编写故障复盘、操作手册、变更说明、飞书 Markdown 或 Obsidian 笔记 |
| Skill 体系维护 | `find-skills`、`writing-skills` | 查找可复用 Skill，或把高频运维流程沉淀为新的 Skill |
| 学习与知识补齐 | `sigma` | 系统学习云原生、Linux、网络、数据库、SRE 方法论等主题 |

### 运维优先级建议

日常使用时，优先把 `alibabacloud-sysom-diagnosis` 作为线上 ECS 性能和稳定性问题入口；把 `systematic-debugging` 作为通用排障方法入口；把 `documents` 作为故障复盘和操作文档入口。

涉及代码改动时，再组合 `go`、`code-quality`、`test-driven-development` 和 `verification-before-completion`。涉及方案设计、自动化平台或流程建设时，再组合 `architecture-planning`、`writing-plans` 和 `subagent-driven-development`。

## 安装

更新公共源码并全量重新安装：

```bash
./scripts/install.sh
```

脚本首先更新公共 Skill 的 Git 上游。全部更新成功并确认 `SKILL.md` 存在后，才会清空 `~/.agents/skills`，再将本地入口 Skill 和公共源码复制到安装目录。分类目录不会出现在安装目录中。

只安装运维相关 Skill：

```bash
./scripts/install-operations.sh
```

脚本读取 `skills/manifests/operations-skills.txt`，只安装运维分类视图中需要的诊断、排障、规划、代码质量、文档和 Skill 维护能力。它同样会先更新公共 Skill、运行仓库检查、清空 `~/.agents/skills`，再安装清单中的 Skill。

只更新公共源码：

```bash
./scripts/update-public.sh
```

仍以公共 Skill 安装的 Git 仓库与 Skill 子目录映射维护在 `skills/manifests/`。拉取结果位于 `.sources/`，不会提交到当前 Git 仓库。分类入口 Skill 自己维护的上游仓库位于对应分类目录下的 `resources/README.md`、`resources/update.sh` 和同目录镜像副本中，目前包括 `skills/architecture-planning/resources/`、`skills/code-quality/resources/` 和 `skills/documents/resources/`。

只检查仓库维护状态：

```bash
./scripts/check.sh
```

这个脚本不修改文件，只检查安装名重复、manifest 指向、入口 Skill、资源同步说明和错误的 gitlink/submodule 状态。

## 卸载

只清空 `~/.agents/skills`：

```bash
./scripts/clean.sh
```

该脚本不会删除或修改这个仓库中的源码。

## 开发工具

Trae、Zed、Reasonix 和 Warp 的 Skill 目录统一指向 `~/.agents/skills`。Codex 原生读取 `~/.agents/skills`，同时继续保留自己的 `.system` 和插件 Skill。`~/.agents/skills` 中保存部署副本，不链接回当前仓库。

## 维护规则

- 只在这个仓库中修改 Skill 源码。
- Skill 目录名必须全局唯一。
- 本地维护并需要安装的 Skill 必须包含 `SKILL.md`。
- Git 来源的公共 Skill 目录只保留 README，安装前从 `.sources` 读取 `SKILL.md`。
- 已入口化分类的上游 Skill 通过分类目录下的 `resources/` 跟踪，不作为独立 Skill 安装。
- 公共 Skill 必须保留 `README.md`。
- 仍独立安装的公共 Skill 通过 manifest 管理，不提交上游源码副本。
- 入口 Skill 使用的公共资源只同步需要的上游 Skill 子目录，不提交完整上游仓库，不使用 git submodule。
- 没有 Git 上游的公共 Skill 不进入本仓库。
- Codex、Claude 等工具自带的 Skill 由各工具自行维护。
- 本仓库不登记、不复制、不安装工具自带 Skill。
- `skill-creator` 只使用 Codex 内置版本，本仓库不再维护公共版本。
- 更新或安装前可运行 `./scripts/check.sh` 做只读校验。
- 更新后运行 `./scripts/install.sh` 重新部署。
- 不直接编辑 `~/.agents/skills`。

## MCP

MCP 服务和配置维护在 `mcps/`：

- `mcps/public/<mcp-name>`：公共 MCP
- `mcps/private/<mcp-name>`：私有 MCP
- `mcps/profiles.json`：不同客户端启用的 MCP 列表

每个 MCP 使用独立目录，目录中至少保存说明和不含密钥的启动配置。真实密钥通过环境变量提供。
