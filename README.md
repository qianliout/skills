# Skills

这个仓库同时维护 Skill 和 MCP。目标不是把所有能力都手写一遍，而是把可复用的公共 Skill 整理成稳定的本地入口，再统一安装到 `~/.agents/skills`。

当前仓库一共管理 34 个可安装 Skill：15 个本地入口 Skill，19 个通过 manifest 跟踪的公共 Skill；另外还有 7 个仅作为分类资源镜像保留的上游 Skill，不会直接安装。

## 这仓库在管什么

| 类型 | 位置 | 会不会安装到 `~/.agents/skills` | 作用 |
| ---- | ---- | ------------------------------- | ---- |
| 本地入口 Skill | `skills/<category>/<skill>/SKILL.md` | 会 | 按主题聚合后的正式入口 |
| manifest 公共 Skill | `skills/manifests/*.txt` + `.sources/<repo>` | 会 | 仍适合独立安装的上游 Skill |
| 分类资源镜像 | `skills/<category>/resources/` | 不会 | 给入口 Skill 提供上游设计参考和素材 |
| MCP 配置 | `mcps/` | 会安装到 `~/.agents/mcps` | 维护公共和私有 MCP 服务配置 |

安装目录是扁平命名空间：最终只有 `~/.agents/skills/<skill-name>`，不会保留分类层级。

## 目录结构

```text
mcps/
├── private/
├── public/
└── profiles.json
scripts/
├── check.sh
├── clean.sh
├── install-operations.sh
├── install.sh
└── update-public.sh
skills/
├── ai-learning/
├── architecture-planning/
├── code-quality/
├── documents/
├── frontend-web/
├── gin-openapi-json/
├── go-development/
├── manifests/
├── operations/
├── productivity/
└── skill-management/
```

`skills/` 和 `mcps/` 是两个独立边界。Skill 的安装清单只放在 `skills/manifests/`，MCP 的启动配置和 profile 只放在 `mcps/`。

## 当前可安装 Skill

### 本地入口 Skill

这些目录是仓库里直接维护、会被复制到安装目录的正式入口。

| 分类 | Skill |
| ---- | ----- |
| `operations` | `alibabacloud-sysom-diagnosis` |
| `gin-openapi-json` | `gin-openapi-json` |
| `architecture-planning` | `architecture-planning` |
| `code-quality` | `code-quality` |
| `documents` | `documents` |
| `go-development` | `go`、`go-api-layer`、`go-code-style`、`go-comment-style`、`go-gin-openapi-json`、`go-logging`、`go-model-hierarchy`、`go-query-dal`、`go-service-layer`、`go-test-writer` |

说明：

- `go` 是大而全的 Go 入口。
- `go-*` 是按职责拆分的细粒度 Go Skill，分别覆盖 API、Service、DAL、Model、日志、注释、测试和 Gin OpenAPI JSON。
- `gin-openapi-json` 是唯一没有分类目录包装的本地入口 Skill，直接位于 `skills/gin-openapi-json/`。

### manifest 公共 Skill

这些 Skill 的安装来源由 `skills/manifests/public-skills.txt` 决定，真实源码更新到 `.sources/`，不会提交到当前仓库。

| 分类 | Skill | 来源仓库 |
| ---- | ----- | -------- |
| `frontend-web` | `frontend-design`、`vercel-react-best-practices`、`web-design-guidelines` | `anthropics-skills`、`vercel-agent-skills` |
| `skill-management` | `find-skills` | `vercel-skills` |
| `ai-learning` | `sigma` | `sanyuan-code-review-expert` |
| `development` | `using-superpowers`、`brainstorming`、`writing-plans`、`test-driven-development`、`subagent-driven-development`、`requesting-code-review`、`systematic-debugging`、`finishing-a-development-branch`、`verification-before-completion`、`using-git-worktrees`、`receiving-code-review`、`dispatching-parallel-agents`、`writing-skills` | `obra-superpowers` |
| `productivity` | `grilling` | `mattpocock-skills` |

说明：

- `requesting-code-review` 当前既作为 `development` 的独立公共 Skill 安装，也被 `code-quality` 分类在 `resources/` 中镜像一份上游内容，供本地入口 Skill 提炼 reference。
- `skill-forge` 已不再安装，当前由 `writing-skills` 承担 Skill 编写方法论。

### 分类资源镜像

这些 Skill 保留在分类目录的 `resources/` 下，只用于同步、核对和追溯设计，不会直接安装。

| 分类 | 镜像 Skill | 说明 |
| ---- | ---------- | ---- |
| `architecture-planning` | `architecture-decision-records`、`architecture-patterns`、`project-planner` | `project-planner` 已冻结保留，上游已删除 |
| `code-quality` | `code-review-expert`、`requesting-code-review` | 用于本地入口 Skill 提炼评审 reference |
| `documents` | `lark-markdown`、`obsidian-markdown` | 用于本地入口 Skill 路由到对应文档场景 |

## 面向运维的常用组合

`install-operations.sh` 会从全部 Skill 中挑出一组偏运维的常用集合。它不改变仓库结构，只是提供一条更窄的安装路径。

| 场景 | 推荐 Skill |
| ---- | ---------- |
| 系统诊断 | `alibabacloud-sysom-diagnosis`、`systematic-debugging` |
| 变更规划 | `brainstorming`、`writing-plans`、`architecture-planning` |
| 并行执行 | `dispatching-parallel-agents`、`subagent-driven-development` |
| Go 平台开发 | `go`、`go-api-layer`、`go-service-layer`、`go-query-dal`、`go-model-hierarchy`、`go-logging`、`go-test-writer`、`gin-openapi-json`、`go-gin-openapi-json` |
| 质量与交付 | `code-quality`、`requesting-code-review`、`receiving-code-review`、`test-driven-development`、`verification-before-completion`、`finishing-a-development-branch` |
| 文档与知识 | `documents`、`find-skills`、`writing-skills`、`sigma` |

## 安装与更新

| 命令 | 作用 |
| ---- | ---- |
| `./scripts/install.sh` | 更新公共来源、校验仓库、清空并重装全部 Skill 和 MCP |
| `./scripts/install-operations.sh` | 只安装 `skills/manifests/operations-skills.txt` 中列出的运维相关 Skill，并同步 MCP |
| `./scripts/update-public.sh` | 只更新公共 Skill 源码和分类资源镜像，不执行安装 |
| `./scripts/check.sh` | 只读校验仓库状态，不修改任何文件 |
| `./scripts/clean.sh` | 只清空 `~/.agents/skills` |

安装流程说明：

1. `install.sh` 先执行 `update-public.sh`。
1. 然后执行 `check.sh`，确保 manifest、资源目录和安装名都合法。
1. 校验通过后清空 `~/.agents/skills`。
1. 再复制本地入口 Skill 和 manifest 公共 Skill 到扁平安装目录。
1. 最后复制 `mcps/` 到 `~/.agents/mcps`。

## 维护约定

- 只在这个仓库里修改 Skill 源码，不直接编辑 `~/.agents/skills`。
- 本地维护并需要安装的 Skill 必须包含 `SKILL.md`。
- 目录名必须对应最终安装名，且全局唯一。
- 仍以独立 Skill 安装的公共能力统一走 `skills/manifests/`，不要把上游源码直接提交进仓库。
- 已经入口化的分类，统一在分类目录下用 `resources/README.md` 和 `resources/update.sh` 跟踪上游素材。
- `resources/` 下的镜像内容不直接修改；需要调整行为时，改对应入口 Skill 下的 `references/`。
- 只同步真正需要的上游 Skill 子目录，不提交完整上游仓库，不使用 git submodule。
- 公共 Skill 必须保留 `README.md` 说明来源和用途。
- `skill-creator` 只使用工具内置版本，本仓库不再维护公共版本。
- `go-development/go` 与同目录 `go-*` Skill 中的同名 reference 文件是物理拷贝，修改其中一份后要同步所有副本。

## 开发工具约定

Trae、Zed、Reasonix 和 Warp 的 Skill 目录统一指向 `~/.agents/skills`。Codex 也会读取这个目录，但仍保留自己的内置 Skill 和插件 Skill。

`~/.agents/skills` 里保存的是部署副本，不反向链接回当前仓库。

## MCP

MCP 服务和配置统一维护在 `mcps/`。

| 位置 | 用途 |
| ---- | ---- |
| `mcps/public/<mcp-name>` | 公共 MCP |
| `mcps/private/<mcp-name>` | 私有 MCP |
| `mcps/profiles.json` | 不同客户端启用的 MCP 列表 |

每个 MCP 目录至少保留说明和不含密钥的启动配置。真实密钥通过环境变量注入。
