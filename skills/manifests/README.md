# Public Skill Manifests

这些清单负责更新有 Git 上游、并且仍以公共 Skill 形态安装的能力。字段使用 `|` 分隔，不需要额外解析工具。Codex、Claude 等工具自带的 Skill 不加入清单。

## public-repositories.txt

每行格式：

```text
本地仓库名|Git 地址
```

源码拉取到项目根目录的 `.sources/<本地仓库名>`。`.sources` 不提交到 Git。

## public-skills.txt

每行格式：

```text
功能分类|Skill 名称|本地仓库名|仓库中的 Skill 目录
```

`Skill 名称` 同时作为 `~/.agents/skills` 下的安装目录名。`本地仓库名` 必须存在于 `public-repositories.txt`。

## 分类入口资源

已经迁移为“分类入口 Skill + references”的分类，不再写入这里的公共 Skill 清单。对应上游仓库由分类目录下的 `resources/` 自行维护。

例如 `documents`：

```text
skills/documents/resources/README.md
```

更新时仍然统一执行：

```bash
./scripts/update-public.sh
```

脚本会继续更新 `.sources/`，并额外同步这些分类入口自带的 `resources/` 仓库。

## 更新和安装

只更新公共源码：

```bash
./scripts/update-public.sh
```

更新公共源码并全量安装：

```bash
./scripts/install.sh
```
