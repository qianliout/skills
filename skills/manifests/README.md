# Public Skill Manifests

这两个清单负责更新有 Git 上游的公共 Skill。字段使用 `|` 分隔，不需要额外解析工具。Codex、Claude 等工具自带的 Skill 不加入清单。

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

## 更新和安装

只更新公共源码：

```bash
./scripts/update-public.sh
```

更新公共源码并全量安装：

```bash
./scripts/install.sh
```
