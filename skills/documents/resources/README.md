# Documents Resources

这个目录用于跟踪 `documents` 分类依赖的上游 Git Skill。这里保存的是原始上游仓库副本，只用于同步、核对和追溯设计，不会被直接安装到 `~/.agents/skills`。

## Managed Skills

### lark-markdown

- Source Repository: `https://github.com/larksuite/cli.git`
- Upstream Skill Path: `skills/lark-markdown`
- Local Mirror Directory: `skills/documents/resources/lark-markdown`
- Local Reference: `skills/documents/documents/references/lark-markdown.md`
- Sync Mode: `full clone + git pull --ff-only`

### obsidian-markdown

- Source Repository: `https://github.com/kepano/obsidian-skills.git`
- Upstream Skill Path: `skills/obsidian-markdown`
- Local Mirror Directory: `skills/documents/resources/obsidian-markdown`
- Local Reference: `skills/documents/documents/references/obsidian-markdown.md`
- Sync Mode: `full clone + git pull --ff-only`

## Update

在仓库根目录运行：

```bash
./scripts/update-public.sh
```

脚本会先更新仍由 `skills/manifests/` 管理的公共 Skill，再读取这个 README 中的 `Managed Skills` 段落，同步 `documents/resources/<skill-name>` 下的上游仓库。

## Rules

- 这里只跟踪 `documents` 分类已经入口化的上游 Skill。
- 不直接修改各个 skill 目录中的上游源码。
- `documents` 的入口规则只在 `documents/references/` 中维护。
- 如需新增或移除上游 Skill，先更新这个 README，再调整对应 reference。
