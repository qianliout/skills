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

Skill 分类目录不再把 `personal` 和 `public` 作为长期结构规则。已经迁移到新结构的分类，直接在分类目录下放入口 Skill 目录和 `resources/`；仍未迁移的历史目录会逐步清理。

有 Git 上游且仍以独立 Skill 安装的能力，继续通过 `skills/manifests/` 管理，源码拉取到项目根目录的 `.sources`。已经迁移为“分类入口 Skill + references”的分类，则在各自目录下使用 `resources/README.md` 和本地镜像目录跟踪上游 Git 仓库。Codex、Claude 等工具自带的 Skill 不在本仓库登记或维护。

## Skill 清单

| 分类 | 当前入口或已安装 Skill | Git 上游跟踪 |
| ---- | --------------------- | ------------ |
| `operations` | alibabacloud-sysom-diagnosis | - |
| `go-development` | go | - |
| `architecture-planning` | architecture-decision-records、architecture-patterns、project-planner | manifest |
| `code-quality` | code-quality | code-review-expert、requesting-code-review |
| `frontend-web` | frontend-design、vercel-react-best-practices、web-design-guidelines | manifest |
| `documents` | documents | lark-markdown、obsidian-markdown |
| `skill-management` | find-skills、skill-forge | manifest |
| `ai-learning` | sigma | manifest |

共维护 13 个不同名称的 Skill。Go 的 API、Service、DAL、Model、Logging、Comment、Test 和 OpenAPI 规则作为 `go` 的 references 按需加载，不再作为独立 Skill 安装。`documents` 已迁移为分类入口 Skill，通用 Markdown、飞书 Markdown 和 Obsidian 规则作为 `documents` 的 references 按需加载，上游仓库由 `skills/documents/resources/` 跟踪。`code-quality` 也已迁移为分类入口 Skill，代码审查与请求审查能力作为 `code-quality` 的 references 按需加载，上游仓库由 `skills/code-quality/resources/` 跟踪。

## 安装

更新公共源码并全量重新安装：

```bash
./scripts/install.sh
```

脚本首先更新公共 Skill 的 Git 上游。全部更新成功并确认 `SKILL.md` 存在后，才会清空 `~/.agents/skills`，再将本地入口 Skill 和公共源码复制到安装目录。分类目录不会出现在安装目录中。

只更新公共源码：

```bash
./scripts/update-public.sh
```

仍以公共 Skill 安装的 Git 仓库与 Skill 子目录映射维护在 `skills/manifests/`。拉取结果位于 `.sources/`，不会提交到当前 Git 仓库。分类入口 Skill 自己维护的上游仓库位于对应分类目录下的 `resources/README.md`、`resources/update.sh` 和同目录镜像副本中，目前包括 `skills/documents/resources/` 和 `skills/code-quality/resources/`。

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
- 已入口化分类的上游仓库通过分类目录下的 `resources/` 跟踪，不作为独立 Skill 安装。
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
