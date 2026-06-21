# Lark Markdown

这个 reference 负责飞书 Drive 中原生 Markdown 文件的查看、创建、比较和更新。目标对象是作为普通文件存储的 `.md`，不是在线 docx 文档。

## When To Load

- 用户要读取飞书中的 Markdown 文件内容。
- 用户要创建、上传、覆盖更新远端 `.md` 文件。
- 用户要比较远端 Markdown 的历史版本，或比较远端文件与本地草稿。
- 用户要对飞书 Markdown 做局部文本替换、正则替换或 patch。

## Quick Routing

- 创建一个新的原生 `.md` 文件：使用 `markdown +create`。
- 读取远端 Markdown：使用 `markdown +fetch`。
- 对比两个远端版本，或远端文件与本地文件：使用 `markdown +diff`。
- 做局部替换：优先使用 `markdown +patch`。
- 用完整内容覆盖远端文件：使用 `markdown +overwrite`。

## Boundaries

- 只处理 Drive 中作为普通文件存储的 Markdown，不处理 docx。
- `--name` 和本地 `--file` 文件名都必须显式带 `.md` 后缀。
- `--content` 支持直接传字符串、`@file` 从本地读取，或 `-` 从标准输入读取。
- `markdown +patch` 的实际语义是先完整下载，再本地替换，最后整文件覆盖上传；它不是服务端原子 patch。
- `markdown +patch` 当前只支持一组 `--pattern` 和 `--content`。
- 替换后的最终内容不能为空；空内容不会被上传。
- `--file` 只接受本地 `.md` 文件路径。

## Not In Scope

- 把 Markdown 导入成飞书在线新版文档，不属于这里。
- rename、move、delete、搜索、权限、评论等云空间管理操作，不属于这里。
- 认证、权限初始化和全局参数处理，按上游共享能力处理，不在这里展开。

## Upstream Tracking

- 原始 Skill 的仓库地址、上游路径和本地镜像目录见 `../../resources/README.md`。
- 仓库源码同步到 `../../resources/lark-markdown/`，需要核对原始行为时再读取对应上游文件。
