# Markdown Style Conventions

Use this reference when generating, refactoring, or reviewing Markdown documents.

## List Syntax — Flat Only, No Nesting

Lists must be single-level and flat. Never indent list items to create nested sub-lists. When information has a hierarchical relationship, split it into separate sections with headings, each containing its own flat list.

### Unordered Lists

Unordered lists use `-` as the bullet marker. Every item is at the same indent level.

```markdown
- Item one
- Item two
- Item three
```

Rules:

- All items share the same left margin — no indentation.
- Do not use `*` or `+` for list bullets.
- If you feel the urge to nest, stop and restructure: add a heading, then a new flat list.

### Ordered Lists

Ordered lists use `1.` for all items. The renderer auto-numbers.

```markdown
1. First step
1. Second step
1. Third step
```

Rules:

- All items start with `1.`, never `2.`, `3.` etc.
- This keeps diffs clean when reordering items.
- No indentation — every item starts at column zero.

### Expressing Hierarchy Without Nesting

When information is naturally hierarchical, use headings to split levels instead of indenting bullets.

Incorrect (nested list):

```markdown
- Setup steps
  1. Install dependencies
  1. Configure environment
- Verification steps
  1. Run tests
  1. Check logs
```

Correct (headings + flat lists):

```markdown
## Setup Steps

1. Install dependencies
1. Configure environment

## Verification Steps

1. Run tests
1. Check logs
```

Another correct approach (paragraphs + flat lists):

```markdown
First, complete the setup:

- Install dependencies
- Configure environment

Then verify everything works:

- Run tests
- Check logs
```

## Emphasis

### Bold

Bold (`**text**`) is reserved for high-priority warnings only:

- Security vulnerabilities or data loss risks.
- Breaking changes in changelogs.
- Critical prerequisites that block further steps.

Do not use bold for:

- Adding weight to opinions or recommendations.
- Highlighting key terms in paragraphs.
- Emphasizing conclusions.
- Making headings or list items stand out.

When tempted to use bold, consider whether the surrounding text can be restructured so the important point leads the paragraph or becomes its own short paragraph.

### Italic

Italic (`*text*` or `_text_`) is not used.

- Book titles, movie names, and similar proper names are written plain.
- Technical terms are written plain or in backticks if they are code identifiers.
- Foreign words are written plain.

## Code

### Fenced Code Blocks

All fenced code blocks specify a language identifier.

```go
func Hello() string {
    return "hello"
}
```

Rules:

- Language tag is required: ```go, ```bash, ```yaml, ```json, ```markdown.
- Do not use bare ``` without a language tag.
- For plain text output or logs, use ```text.

### Inline Code

Use single backticks for:

- File paths: `src/main.go`
- Function names: `Serialize()`
- Config keys: `maxRetries`
- Short code fragments: `err != nil`

Do not use backticks for emphasis or decoration of non-code terms.

## Headings

### Hierarchy

Headings start at `#` (H1) and descend without skipping levels.

```markdown
# Document Title

## Section

### Sub-section

#### Detail level
```

Rules:

- Start with `#` for the document title.
- `##` for major sections.
- `###` for sub-sections.
- Never jump from `#` to `###` or from `##` to `####`.
- `####` is the deepest level used; prefer restructuring when deeper nesting seems needed.

### Spacing

- One blank line before and after every heading.
- No blank line between consecutive headings at different levels.

## Paragraphs and Spacing

- Separate paragraphs with exactly one blank line.
- Do not use trailing whitespace.
- List items in a compact group have no blank lines between them.
- List items that are long or contain multiple paragraphs are separated by blank lines.

## Links

### Inline Links

Single-use links use inline format:

```markdown
[Go Code Style](../go-code-style/SKILL.md)
```

### Reference Links

Repeated links use reference format:

```markdown
See [Go Code Style][go-style] and [Go API Layer][go-api] for details.

[go-style]: ../go-code-style/SKILL.md
[go-api]: ../go-api-layer/SKILL.md
```

Rules:

- When the same URL appears multiple times, extract to a reference at the end of the section or document.
- Reference labels are lowercase, hyphen-separated, and descriptive.
- One-time links can stay inline.

## Tables

Tables use GFM pipe syntax with a header separator row.

```markdown
| Name | Type | Description |
| ---- | ---- | ----------- |
| id   | int64 | Unique identifier |
| name | string | Display name |
```

Rules:

- Header row, separator row, then data rows.
- Columns are aligned for readability when practical, but left-aligned pipes are acceptable.
- Keep cell content short; move long explanations to text above or below the table.

## Horizontal Rules

Horizontal rules (`---`) are used sparingly to separate major document sections. Do not use `***` or `___`.

## HTML in Markdown

Avoid raw HTML in Markdown. Use native Markdown constructs.

## Line Length

- Paragraphs are written as continuous lines.
- Code blocks and tables are the exception: wrap long lines for readability.
- Source readability matters more than rendered column width.

## Checklist

- [x] All lists are flat and single-level — no indented sub-items anywhere.
- [x] Hierarchical information expressed with headings, not nested bullets.
- [x] All unordered lists use `-` bullets.
- [x] Bold used only for critical warnings, not for general emphasis.
- [x] No italic markers (`*text*` or `_text_`).
- [x] All fenced code blocks specify a language.
- [x] Heading hierarchy is continuous with no skipped levels.
- [x] Paragraphs separated by single blank lines.
- [x] Links use consistent style; repeated links extracted to references.
