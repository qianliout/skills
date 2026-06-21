---
name: documents
description: "文档类任务唯一入口和按需规则路由。Use whenever writing, refactoring, reviewing, comparing, or managing Markdown documents, Feishu Markdown files, or Obsidian notes. Always start here and load only the reference files required by the task."
---

# Documents

把这个 Skill 作为全部文档类任务的唯一入口。先识别文档场景，再只读取当前任务需要的 reference；不要一次性读取全部文档规则。

## Workflow

1. 识别任务类型：普通 Markdown 写作与评审、飞书 Markdown 文件操作、或 Obsidian 笔记编辑。
1. 读取就近上下文：目标 Markdown 文件、同目录 README、模板文件、相关配置和已有文档风格。
1. 根据下方路由只读取当前任务需要的 reference；跨场景任务只组合实际涉及的 reference。
1. 优先保持文档原有语义不变；除非用户明确要求，不扩写无关内容。
1. 如需核对上游公共 Skill 的原始设计，读取 `../../resources/README.md` 中记录的仓库与本地镜像目录，不直接把上游 Skill 当作可安装 Skill 使用。

## Reference Routing

- 新增、重构、评审 README、技术文档、变更说明、通用 Markdown 文本：读取 `references/md-style.md` 和 `references/md-style-conventions.md`。
- 查看、创建、上传、覆盖、比较、局部修改飞书 Markdown 文件：读取 `references/lark-markdown.md`；仅在任务同时涉及通用 Markdown 改写时再补充读取 `references/md-style.md`。
- 编辑 Obsidian 笔记、处理 wikilinks、embeds、callouts、frontmatter、properties、tags：读取 `references/obsidian-markdown.md`；仅在任务同时涉及通用 Markdown 改写时再补充读取 `references/md-style.md`。

## Routing Rules

- 不默认读取任何 reference；只在任务匹配时读取。
- 不把 `resources/` 中跟踪的上游仓库当作直接可调用 Skill。
- 不因为目标文件是 `.md` 就自动读取全部文档 reference。
- 飞书 Markdown 与 Obsidian Markdown 的规则互不替代，只有任务明确跨场景时才组合读取。

## Boundaries

- `md-style` 负责通用 Markdown 结构、列表、强调、标题、代码块和链接风格。
- `lark-markdown` 负责飞书 Drive 中原生 `.md` 文件的读取、创建、比较、局部 patch 和覆盖更新。
- `obsidian-markdown` 负责 Obsidian 扩展语法，如 wikilinks、embeds、callouts、properties、comments 和标签。
- 云空间管理、权限、评论、移动、删除等不属于通用 Markdown 风格约束，按对应 reference 的边界处理。

## Pre-Delivery Checklist

- 只读取了任务需要的文档 reference。
- 没有把飞书、Obsidian、通用 Markdown 的规则混用到无关场景。
- 保持了原文档语义，未无故扩写或改写无关内容。
- 如需追溯上游规则，已从 `resources/` 读取原始 Skill，而不是直接安装叶子 Skill。
