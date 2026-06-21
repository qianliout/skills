# Architecture Planning Resources

这个目录用于跟踪 `architecture-planning` 分类依赖的上游 Git Skill。这里保存的是原始上游 Skill 内容镜像，只用于同步、核对和追溯设计，不会被直接安装到 `~/.agents/skills`。

## Managed Skills

### architecture-decision-records

- Source Repository: `https://github.com/wshobson/agents.git`
- Upstream Skill Path: `plugins/documentation-generation/skills/architecture-decision-records`
- Local Mirror Directory: `skills/architecture-planning/resources/architecture-decision-records`
- Local Reference: `skills/architecture-planning/architecture-planning/references/architecture-decision-records.md`
- Sync Mode: `repo cache + subtree sync`

### architecture-patterns

- Source Repository: `https://github.com/wshobson/agents.git`
- Upstream Skill Path: `plugins/backend-development/skills/architecture-patterns`
- Local Mirror Directory: `skills/architecture-planning/resources/architecture-patterns`
- Local Reference: `skills/architecture-planning/architecture-planning/references/architecture-patterns.md`
- Sync Mode: `repo cache + subtree sync`

### project-planner

- Source Repository: `https://github.com/shubhamsaboo/awesome-llm-apps.git`
- Upstream Skill Path: `awesome_agent_skills/project-planner`
- Local Mirror Directory: `skills/architecture-planning/resources/project-planner`
- Local Reference: `skills/architecture-planning/architecture-planning/references/project-planner.md`
- Sync Mode: `repo cache + subtree sync`

## Update

在仓库根目录运行：

```bash
./scripts/update-public.sh
```

脚本会先更新仍由 `skills/manifests/` 管理的公共 Skill，再调用这个目录下的 `update.sh`，把上游 skill 子目录同步到这里的本地镜像目录。

## Rules

- 这里只跟踪 `architecture-planning` 分类已经入口化的上游 Skill。
- 不直接修改镜像目录中的上游内容；需要调整行为时，改入口 Skill 下的 `references/`。
- `architecture-planning` 的入口规则只在 `architecture-planning/references/` 中维护。
- 如需新增或移除上游 Skill，先更新这个 README，再同步调整 `update.sh` 和对应 reference。
