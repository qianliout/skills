# Skills

这个仓库统一维护 Skill 和 MCP。Skill 只包含自己编写的源码和有明确 Git 上游的公共源码，并安装到 `~/.agents/skills`；MCP 按公共和私有分别维护服务与配置。

## 目录结构

```text
mcps/
├── private/
├── public/
└── profiles.json
scripts/
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

每个功能分类包含以下来源目录：

- `personal`：自己编写和维护的 Skill
- `public`：有明确 Git 上游的公共 Skill

公共 Skill 目录中的 `README.md` 记录简介、来源和安装方案。公共 Skill 只提交 README，源码由 manifest 拉取到项目根目录的 `.sources`。Codex、Claude 等工具自带的 Skill 不在本仓库登记或维护。

## Skill 清单

| 分类 | Personal | Public |
| ---- | -------- | ------ |
| `operations` | alibabacloud-sysom-diagnosis | - |
| `go-development` | go、go-api-layer、go-code-style、go-comment-style、go-gin-openapi-json、go-logging、go-model-hierarchy、go-query-dal、go-service-layer、go-test-writer | - |
| `architecture-planning` | - | architecture-decision-records、architecture-patterns、project-planner |
| `code-quality` | - | code-review-expert、requesting-code-review |
| `frontend-web` | - | frontend-design、vercel-react-best-practices、web-design-guidelines |
| `documents` | md-style | lark-markdown、obsidian-markdown |
| `skill-management` | - | find-skills、skill-forge |
| `ai-learning` | - | sigma |

共维护 25 个不同名称的 Skill，其中 12 个是个人 Skill，13 个是公共 Skill。

## 安装

更新公共源码并全量重新安装：

```bash
./scripts/install.sh
```

脚本首先更新公共 Skill 的 Git 上游。全部更新成功并确认 `SKILL.md` 存在后，才会清空 `~/.agents/skills`，再将个人 Skill 和公共源码复制到安装目录。分类目录不会出现在安装目录中。

只更新公共源码：

```bash
./scripts/update-public.sh
```

Git 仓库与 Skill 子目录映射维护在 `skills/manifests/`。拉取结果位于 `.sources/`，不会提交到当前 Git 仓库。

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
- 个人 Skill 必须包含 `SKILL.md`。
- Git 来源的公共 Skill 目录只保留 README，安装前从 `.sources` 读取 `SKILL.md`。
- 公共 Skill 必须保留 `README.md`。
- 有 Git 上游的公共 Skill 通过 manifest 管理，不提交上游源码副本。
- 没有 Git 上游的公共 Skill 不进入本仓库。
- Codex、Claude 等工具自带的 Skill 由各工具自行维护。
- 本仓库不登记、不复制、不安装工具自带 Skill。
- `skill-creator` 只使用 Codex 内置版本，本仓库不再维护公共版本。
- 更新后运行 `./scripts/install.sh` 重新部署。
- 不直接编辑 `~/.agents/skills`。

## MCP

MCP 服务和配置维护在 `mcps/`：

- `mcps/public/<mcp-name>`：公共 MCP
- `mcps/private/<mcp-name>`：私有 MCP
- `mcps/profiles.json`：不同客户端启用的 MCP 列表

每个 MCP 使用独立目录，目录中至少保存说明和不含密钥的启动配置。真实密钥通过环境变量提供。
