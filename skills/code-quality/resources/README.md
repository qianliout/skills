# Code Quality Resources

这个目录用于跟踪 `code-quality` 分类依赖的上游 Git Skill。这里保存的是原始上游 Skill 内容镜像，只用于同步、核对和追溯设计，不会被直接安装到 `~/.agents/skills`。

## Managed Skills

### code-review-expert

- Source Repository: `https://github.com/sanyuan0704/code-review-expert.git`
- Upstream Skill Path: `skills/code-review-expert`
- Local Mirror Directory: `skills/code-quality/resources/code-review-expert`
- Local Reference: `skills/code-quality/code-quality/references/code-review-expert.md`
- Sync Mode: `repo cache + subtree sync`

### requesting-code-review

- Source Repository: `https://github.com/obra/superpowers.git`
- Upstream Skill Path: `skills/requesting-code-review`
- Local Mirror Directory: `skills/code-quality/resources/requesting-code-review`
- Local Reference: `skills/code-quality/code-quality/references/requesting-code-review.md`
- Sync Mode: `repo cache + subtree sync`

## Update

在仓库根目录运行：

```bash
./scripts/update-public.sh
```

脚本会先更新仍由 `skills/manifests/` 管理的公共 Skill，再调用这个目录下的 `update.sh`，把上游 skill 子目录同步到这里的本地镜像目录。

## Rules

- 这里只跟踪 `code-quality` 分类已经入口化的上游 Skill。
- 不直接修改镜像目录中的上游内容；需要调整行为时，改入口 Skill 下的 `references/`。
- 如需新增或移除上游 Skill，先更新这个 README，再同步调整 `update.sh` 和对应 reference。
