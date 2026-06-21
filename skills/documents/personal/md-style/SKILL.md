---
name: md-style
description: "Markdown 写作风格规范。Use when writing, refactoring, reviewing, or explaining Markdown documents, README, technical docs, changelogs, or any .md file. Enforces consistent list syntax, minimal emphasis usage, and clean document structure."
---

# Markdown Style

Markdown 文档优先清晰、扁平、克制。禁止列表多层嵌套，减少 `**` 加粗和斜体，靠标题层级和自然语言传达结构。

## Workflow

1. 识别文档类型：README、技术文档、changelog、skill 定义、会议记录、或其他 Markdown 文本。
1. 加载 `references/md-style-conventions.md`；除非用户明确要求，不改变文档的实质内容。
1. 审查列表结构：所有列表保持单层扁平，禁止使用缩进嵌套子列表；嵌套信息改用标题拆分或独立段落。
1. 审查强调符号：非必要不使用 `**` 加粗和 `*` 斜体；用自然语言、标题层级和列表结构传达重点。
1. 审查文档结构：标题层级连续不跳层；代码块指定语言；链接使用 reference 风格或清晰的内联风格。
1. 审查空白和分隔：段落间空一行；标题前后各空一行；列表项松散时项间空一行，紧凑时不空。
1. 修改后自检：全文没有任何缩进嵌套列表；`**` 仅保留在确有必要强调的场景。

## Shared Rules

- 列表始终保持单层扁平，禁止使用缩进创建多层嵌套列表。
- 需要表达层级关系时，使用标题拆分 + 各自独立的单层列表，或使用自然语言段落。
- 无序列表标记统一用 `-`。
- 有序列表使用 `1.` 自动编号，不手动维护数字。
- `**` 加粗仅用于紧急安全警告、破坏性变更标记等极高优先级信息，其余场景用自然语言替代。
- `*` 斜体原则上不使用；书籍名、电影名等直接写原名不加标记。
- 代码块必须指定语言：```go、```bash、```yaml 等，不写裸 ```。
- 标题从 `#` 开始，层级连续不跳（`#` → `##` → `###`），不跳过 `##` 直接用 `###`。
- 内联代码用单个反引号 `` ` ``，引用文件路径、函数名、配置项时使用。
- 链接优先使用 reference 风格 `[text][ref]`，重复链接收敛到文末 reference 区块；一次性链接可用内联 `[text](url)`。
- 表格使用 GFM 管道格式，表头和分隔行完整，单元格保持简短。
- 避免在一行内混合多种格式标记，保持单行可读。

## Reference Loading

生成、重构或评审 Markdown 文档时，必须加载 `references/md-style-conventions.md`。

## Pre-Delivery Checklist

- [ ] 全文无缩进嵌套列表，所有列表均为单层扁平。
- [ ] 原有嵌套信息已用标题拆分或段落重组。
- [ ] `**` 加粗仅用于安全警告或破坏性变更等极高优先级信息。
- [ ] 没有 `*` 斜体标记。
- [ ] 代码块全部指定了语言标识。
- [ ] 标题层级连续，未跳层。
- [ ] 段落间、标题前后空白符合规范。
- [ ] 链接格式一致，重复链接已收敛。
