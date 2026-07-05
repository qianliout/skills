# Documents Resources

这个目录用于跟踪 `documents` 分类依赖的上游 Git Skill。这里保存的是从上游仓库同步出来的 Skill 子目录，只用于同步、核对和追溯设计，不会被直接安装到 `~/.agents/skills`。

## Managed Skills

### lark-markdown

- Source Repository: `https://github.com/larksuite/cli.git`
- Upstream Skill Path: `skills/lark-markdown`
- Local Mirror Directory: `skills/documents/resources/lark-markdown`
- Local Reference: `skills/documents/documents/references/lark-markdown.md`
- Sync Mode: `repo cache + subtree sync`

### obsidian-markdown

- Source Repository: `https://github.com/kepano/obsidian-skills.git`
- Upstream Skill Path: `skills/obsidian-markdown`
- Local Mirror Directory: `skills/documents/resources/obsidian-markdown`
- Local Reference: `skills/documents/documents/references/obsidian-markdown.md`
- Sync Mode: `repo cache + subtree sync`

## Update

在仓库根目录运行：

```bash
./scripts/update-public.sh
```

脚本会先更新仍由 `skills/manifests/` 管理的公共 Skill，再调用这个目录下的 `update.sh`，从 `.sources/resource-cache/` 中的上游仓库缓存同步所需 Skill 子目录。

## Rules

- 这里只跟踪 `documents` 分类已经入口化的上游 Skill。
- 不直接修改镜像目录中的上游内容；需要调整行为时，改入口 Skill 下的 `references/`。
- 这里只提交需要追溯的上游 Skill 子目录，不提交完整上游仓库，不使用 git submodule。
- `documents` 的入口规则只在 `documents/references/` 中维护。
- 如需新增或移除上游 Skill，先更新这个 README，再同步调整 `update.sh` 和对应 reference。
