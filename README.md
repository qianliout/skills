# Skills

这个仓库是个人 Skill 的统一维护仓库。所有 Skill 按功能和来源分类维护，再通过简单的 Shell 脚本统一安装到 `~/.agents/skills`。

## 目录结构

```text
manifests/
├── public-repositories.txt
└── public-skills.txt
scripts/
├── clean.sh
├── install.sh
└── update-public.sh
skills/
├── ai-learning/
├── architecture-planning/
├── browser-automation/
├── code-quality/
├── documents/
├── frontend-web/
├── go-development/
├── operations/
└── skill-management/
```

每个功能分类包含以下来源目录：

- `personal`：自己编写和维护的 Skill
- `public`：来自社区、Codex 系统或 Codex 插件的公共 Skill

公共 Skill 目录中的 `README.md` 记录简介、来源和安装方案。有 Git 上游的公共 Skill 只提交 README，源码由 manifest 拉取到项目根目录的 `.sources`；没有稳定 Git 上游的公共 Skill 继续在目录中保存完整源码。

## Skill 清单

| 分类 | Personal | Public |
| ---- | -------- | ------ |
| `operations` | alibabacloud-sysom-diagnosis | - |
| `go-development` | go、go-api-layer、go-code-style、go-comment-style、go-gin-openapi-json、go-logging、go-model-hierarchy、go-query-dal、go-service-layer、go-test-writer | - |
| `architecture-planning` | - | architecture-decision-records、architecture-patterns、project-planner |
| `code-quality` | - | code-review-expert、requesting-code-review、ponytail、ponytail-audit、ponytail-debt、ponytail-help、ponytail-review |
| `frontend-web` | - | frontend-design、vercel-react-best-practices、web-design-guidelines |
| `documents` | md-style | lark-markdown、obsidian-markdown、documents、pdf、presentations、spreadsheets |
| `skill-management` | - | find-skills、skill-creator、skill-forge、plugin-creator、skill-installer |
| `browser-automation` | - | control-in-app-browser、control-chrome |
| `ai-learning` | - | sigma、imagegen、openai-docs |

共维护 41 个不同名称的 Skill，其中 12 个是个人 Skill，29 个是公共 Skill。

## 安装

更新公共源码并全量重新安装：

```bash
./scripts/install.sh
```

脚本首先更新有 Git 上游的公共 Skill。全部更新成功并确认 `SKILL.md` 存在后，才会清空 `~/.agents/skills`，再将个人 Skill、公共源码和本地快照复制到安装目录。分类目录不会出现在安装目录中。

只更新公共源码：

```bash
./scripts/update-public.sh
```

Git 仓库与 Skill 子目录映射维护在 `manifests/`。拉取结果位于 `.sources/`，不会提交到当前 Git 仓库。

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
- 个人 Skill 和本地公共快照必须包含 `SKILL.md`。
- Git 来源的公共 Skill 目录只保留 README，安装前从 `.sources` 读取 `SKILL.md`。
- 公共 Skill 必须保留 `README.md`。
- 有 Git 上游的公共 Skill 通过 manifest 管理，不提交上游源码副本。
- 没有稳定 Git 上游的公共 Skill 在 `public` 目录中保留源码快照。
- 更新后运行 `./scripts/install.sh` 重新部署。
- 不直接编辑 `~/.agents/skills`。

## MCP

原有 MCP 配置工具保留在 `agent-stack/`，与 Skill 安装流程相互独立。
