# Obsidian Markdown

这个 reference 负责 Obsidian Flavored Markdown。它覆盖 Obsidian 在标准 Markdown 之外扩展的语法，如 wikilinks、embeds、callouts、properties、comments、tags 和部分渲染约定。

## When To Load

- 用户明确提到 Obsidian、vault、note、wikilinks、callouts、frontmatter、properties、embeds 或 tags。
- 用户要创建或编辑 Obsidian 笔记。
- 用户要把普通 Markdown 改造成 Obsidian 可用的笔记格式。

## Workflow

1. 在文件开头添加 frontmatter，按需声明 `title`、`tags`、`aliases`、`cssclasses` 等属性。
1. 用标准 Markdown 搭建结构，再补充 Obsidian 专属语法。
1. 站内笔记之间优先使用 `[[wikilinks]]`，外部链接使用普通 Markdown 链接。
1. 需要嵌入其他笔记、图片、PDF 时使用 `![[embed]]` 语法。
1. 需要高亮提示时使用 callout 语法 `> [!type]`。
1. 完成后确认语法在 Obsidian 阅读视图中可以正常渲染。

## Syntax Highlights

- 内部链接：`[[Note Name]]`、`[[Note Name|Display Text]]`、`[[Note Name#Heading]]`。
- Block ID：在段落末尾追加 `^block-id`，再通过 `[[Note#^block-id]]` 链接。
- 嵌入：`![[Note Name]]`、`![[image.png|300]]`、`![[document.pdf#page=3]]`。
- Callout：`> [!note]`、`> [!warning] Custom Title`、`> [!faq]-`。
- 标签：正文中可使用 `#tag` 或 `#nested/tag`，也可放在 frontmatter 的 `tags` 字段。
- 评论：使用 `%% hidden %%` 或块级 `%% ... %%`。
- 高亮：使用 `==highlighted text==`。
- 数学公式：支持行内 `$...$` 和块级 `$$...$$`。
- Mermaid：代码块语言标记使用 `mermaid`。

## Boundaries

- 这里只覆盖 Obsidian 扩展语法，不重复定义标准 Markdown 基础规则。
- 如果任务同时要求通用 Markdown 风格统一，需要额外加载 `md-style.md`。
- 示例中的嵌套任务列表来自上游说明，但在当前仓库内写 Markdown 时仍要遵循扁平列表规则。

## Upstream Tracking

- 原始 Skill 的仓库地址、上游路径和本地镜像目录见 `../../resources/README.md`。
- 仓库源码同步到 `../../resources/obsidian-markdown/`，需要核对完整语法细节时再读取对应上游文件。
