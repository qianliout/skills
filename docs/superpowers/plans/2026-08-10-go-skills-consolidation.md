# Go Skills 收敛 Implementation Plan

> For agentic workers: REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Goal: 按已批准 spec 收敛 Go Skills：薄路由 `go` + 分层叶子、注释/日志并入 `go-code-style`、OpenAPI 单接口唯一 Skill、全文中文、严厉措辞、零物理拷贝。

Architecture: `go` 只路由到可安装叶子；每个叶子自有中文 reference（`go-code-style` 三份）；删除 `go/references` 拷贝、`go-comment-style`、`go-logging`、根级 `gin-openapi-json`；用 `check.sh` 锁死结构。

Tech Stack: 仓库内 Markdown Skill、`scripts/check.sh`、`skills/manifests/operations-skills.txt`、bash 安装脚本。

Spec: `docs/superpowers/specs/2026-08-10-go-skills-consolidation-design.md`

## Global Constraints

- 语言：全部 `SKILL.md` / reference / `agents/openai.yaml` / 脚本用户可见文案必须中文（标识符、命令、JSON 键名除外）。
- 语气：必须使用「必须 / 禁止 / 不得 / 违规即停」；禁止「建议 / 尽量 / 最好 / 可以考虑 / 推荐」。
- 可安装集合仅允许：`go`、`go-code-style`、`go-api-layer`、`go-service-layer`、`go-query-dal`、`go-model-hierarchy`、`go-test-writer`、`go-gin-openapi-json`。
- `go` 禁止持有各层细则：`skills/go-development/go/references/` 与 `skills/go-development/go/assets/` 必须不存在。
- 叶子禁止指引读取 `go/references/...`；跨层只点名其它 Skill 名。
- OpenAPI：仅 `go-gin-openapi-json`；每次只生成一个 operation。
- description 只写中文触发条件，不写流程摘要。
- 合并 reference：读原 `*.md` + `*-conventions.md`，重写为一份权威中文，删除 `*-conventions.md`；禁止机械拼接、禁止正文留英文规范段落。
- 工作目录：仓库根 `/Users/liuqianli/work/skills`（或当前 clone 根）。只改本仓库 `skills/`、`scripts/`、`README.md`；不手改 `~/.agents/skills`（验证时用安装脚本重装）。

### Reference 重写验收命令（每个叶子任务结束必须跑）

```bash
# 软措辞：目标目录内必须无匹配（代码块外的英文说明也不应成段存在）
rg -n '建议|尽量|最好|可以考虑|推荐' skills/go-development/<skill> --glob '*.md' --glob '*.yaml' && exit 1 || true
test -z "$(find skills/go-development/<skill> -name '*-conventions.md')"
```

---

### Task 1: 为 Go 结构写入失败的 check 断言

Files:
- Modify: `scripts/check.sh`
- Test: `./scripts/check.sh`

Interfaces:
- Consumes: 现有 `check.sh` 末尾 `printf 'check passed\n'`
- Produces: 函数式断言块，后续删除/改写后必须全部通过

- [ ] Step 1: 在 `check.sh` 的 gitlinks 检查之后、`check passed` 之前插入以下块

```bash
# --- Go skills consolidation invariants ---
GO_DEV="$ROOT/skills/go-development"
ALLOWED_go_skills='go
go-api-layer
go-code-style
go-gin-openapi-json
go-model-hierarchy
go-query-dal
go-service-layer
go-test-writer'

test -d "$GO_DEV" || fail "missing go-development category"

forbidden_go_dirs='go-comment-style
go-logging'
while IFS= read -r d; do
  test -n "$d" || continue
  test ! -e "$GO_DEV/$d" || fail "forbidden go skill directory still present: go-development/$d"
done <<< "$forbidden_go_dirs"

test ! -e "$ROOT/skills/gin-openapi-json" || fail "forbidden standalone skill still present: skills/gin-openapi-json"
test ! -e "$ROOT/scripts/go-reference-pairs.txt" || fail "forbidden sync map still present: scripts/go-reference-pairs.txt"

test ! -d "$GO_DEV/go/references" || fail "go must not contain references/ (thin router only)"
test ! -d "$GO_DEV/go/assets" || fail "go must not contain assets/ (OpenAPI assets live under go-gin-openapi-json)"

go_skill_dirs="$(find "$GO_DEV" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)"
while IFS= read -r d; do
  test -n "$d" || continue
  printf '%s\n' "$allowed_go_skills" | grep -Fx "$d" >/dev/null ||
    fail "unexpected go-development skill directory: $d"
done <<< "$go_skill_dirs"

while IFS= read -r d; do
  test -n "$d" || continue
  test -f "$GO_DEV/$d/SKILL.md" || fail "missing SKILL.md for go-development/$d"
done <<< "$allowed_go_skills"

test -f "$GO_DEV/go-code-style/references/code-style.md" || fail "missing go-code-style/references/code-style.md"
test -f "$GO_DEV/go-code-style/references/comment-style.md" || fail "missing go-code-style/references/comment-style.md"
test -f "$GO_DEV/go-code-style/references/logging.md" || fail "missing go-code-style/references/logging.md"
test -f "$GO_DEV/go-gin-openapi-json/scripts/generate.sh" || fail "missing go-gin-openapi-json/scripts/generate.sh"
test -f "$GO_DEV/go-gin-openapi-json/assets/openapi.json" || fail "missing go-gin-openapi-json/assets/openapi.json"

# 叶子不得再持有 *-conventions.md；go 除外已无 references
conv_hits="$(find "$GO_DEV" -type f -name '*-conventions.md' | sort)"
test -z "$conv_hits" || fail "conventions files must be merged away: $conv_hits"

# go-* 不得再嵌入 go/references 指引
if rg -n 'go/references/' "$GO_DEV" --glob 'SKILL.md' --glob '*.md' >/dev/null; then
  fail "Go skills must not reference go/references/"
fi
```

- [ ] Step 2: 跑 check，确认当前仓库失败

Run: `./scripts/check.sh`

Expected: `check failed:` 且至少命中仍存在的禁目录 / `go/references` / 缺文件之一。

- [ ] Step 3: Commit

```bash
git add scripts/check.sh
git commit -m "$(cat <<'EOF'
fail check on Go skill structure until consolidation lands.

EOF
)"
```

---

### Task 2: 更新 manifest 与 README 目标集合

Files:
- Modify: `skills/manifests/operations-skills.txt`
- Modify: `README.md`
- Delete: `scripts/go-reference-pairs.txt`（若仍存在）

Interfaces:
- Consumes: spec §4 安装名列表
- Produces: 运维清单与文档只列出允许的 Go Skill

- [ ] Step 1: 将 `operations-skills.txt` 中 Go 段改成

```text
# Operations platform development and review
go
go-api-layer
go-code-style
go-gin-openapi-json
go-model-hierarchy
go-query-dal
go-service-layer
go-test-writer
code-quality
```

（保持其后 `requesting-code-review` 等行不变；删除 `go-comment-style`、`go-logging`、`gin-openapi-json`。）

- [ ] Step 2: 改 README

在 `README.md`：

1. 分类表中 `go-development` 一行只列：`go`、`go-api-layer`、`go-code-style`、`go-gin-openapi-json`、`go-logging` 等不得再出现；最终为：

`go`、`go-api-layer`、`go-code-style`、`go-gin-openapi-json`、`go-model-hierarchy`、`go-query-dal`、`go-service-layer`、`go-test-writer`

2. 删除「`gin-openapi-json` 是唯一没有分类目录包装…」整条说明；删除根树状图里的 `gin-openapi-json/`（若有）。
3. 说明改为：
   - `go` 是薄路由总入口，必须先加载；
   - `go-*` 是分层细则；注释与日志在 `go-code-style`；
   - OpenAPI 唯一入口是 `go-gin-openapi-json`（单接口）。
4. 运维组合「Go 平台开发」一行只列上述 8 个名字。
5. 删除维护约定中「`go-development/go` 与同目录 `go-*` … 物理拷贝…同步」整条。

- [ ] Step 3: 删除同步表

```bash
rm -f scripts/go-reference-pairs.txt
```

- [ ] Step 4: Commit

```bash
git add skills/manifests/operations-skills.txt README.md
git add -u scripts/go-reference-pairs.txt
git commit -m "$(cat <<'EOF'
Align manifests and README with consolidated Go skill set.

EOF
)"
```

---

### Task 3: 重写薄路由 `go` 并清空拷贝

Files:
- Modify: `skills/go-development/go/SKILL.md`
- Modify: `skills/go-development/go/agents/openai.yaml`
- Delete: `skills/go-development/go/references/`（整个目录）
- Delete: `skills/go-development/go/assets/`（整个目录）

Interfaces:
- Produces: 仅路由的 `go` Skill；后续叶子不得再被 `go` 内嵌细则替代

- [ ] Step 1: 写入完整 `SKILL.md`

```markdown
---
name: go
description: "用于编写、重构、评审、排查、测试或解释任何 Go 代码时；必须先加载本 Skill，再按任务层加载对应 go-* Skill。"
---

# Go

把本 Skill 当作全部 Go 任务的强制总入口。禁止跳过本 Skill 直接凭印象改 Go 代码。本 Skill 不含各层细则；细则只在对应 `go-*` Skill 中。

## 强制工作流

1. 识别任务类型与实际触及的层（实现 / 重构 / 评审 / 排查 / 测试 / 解释 / 单接口 OpenAPI）。
2. 读取就近代码：相邻文件、接口、构造函数、调用方、测试。
3. 按下方路由表加载且仅加载实际需要的 `go-*` Skill（先读其 `SKILL.md`，再读其 reference）。
4. 禁止因调用链上存在某层就加载该层。
5. 修改 Go 文件后必须运行 `goimport`；能定位包或测试时必须跑最小范围 `go test`；不能跑时必须说明原因。未满足不得宣称完成。

## 路由表

| 任务信号 | 必须加载 |
|----------|----------|
| 控制流、命名、错误处理、依赖注入、receiver、import、可维护性 | `go-code-style` |
| 注释、doc comment、字段注释 | `go-code-style`（`references/comment-style.md`） |
| 日志、logger、recover 日志、敏感信息 | `go-code-style`（`references/logging.md`） |
| Gin/HTTP handler、绑定、响应 DTO、分页响应 | `go-api-layer` |
| Service 接口/编排/聚合/错误包装 | `go-service-layer` |
| Store/DAL/DAO/GORM/CRUD/分页查询 | `go-query-dal` |
| Domain/GORM model、param、response、Serialize/生命周期 | `go-model-hierarchy` |
| `_test.go`、testify、mock、表驱动 | `go-test-writer` |
| OpenAPI / Apifox / `openapi.json` / 单接口文档 | `go-gin-openapi-json`；需要对齐 handler 形态时再加 `go-api-layer` |

## 层边界（违规即停）

- API 只做 HTTP 适配；禁止在 handler 写复杂业务、聚合、DB/GORM/SQL。
- Service 只做业务编排；禁止直接访问 DB、GORM、SQL。
- DAL 只做持久化；禁止承载业务规则。
- Model 管理字段生命周期、校验、序列化/反序列化、更新字段选择。
- 日志由拥有业务上下文的 API、Service 或 goroutine 边界记录；DAL 与 Model 默认禁止新增日志。
- 代码注释必须中文；日志 Msg 必须英文。

## 禁止清单

- 禁止在本 Skill 内维护或粘贴各层细则正文。
- 禁止读取或恢复 `go/references/` 拷贝。
- 禁止再使用已删除 Skill：`go-comment-style`、`go-logging`、`gin-openapi-json`。
- 禁止一次 OpenAPI 生成多个接口；OpenAPI 只能走 `go-gin-openapi-json`。

## 交付门禁

- 已加载本 Skill 与路由表要求的全部 `go-*`。
- 层职责未互相侵入。
- 已运行 `goimport`；能测则已 `go test`，不能则已说明原因。
```

- [ ] Step 2: 写入 `agents/openai.yaml`

```yaml
interface:
  display_name: "Go"
  short_description: "Go 强制总入口与分层路由"
  default_prompt: "必须先使用 $go，再按任务加载对应 go-* Skill；禁止跳过路由。"
```

- [ ] Step 3: 删除拷贝目录

```bash
rm -rf skills/go-development/go/references skills/go-development/go/assets
```

- [ ] Step 4: 自检

```bash
test ! -d skills/go-development/go/references
test ! -d skills/go-development/go/assets
rg -n '建议|尽量|最好|可以考虑|推荐' skills/go-development/go/SKILL.md && exit 1 || true
```

Expected: 目录不存在；软措辞无匹配。

- [ ] Step 5: Commit

```bash
git add skills/go-development/go
git add -u skills/go-development/go
git commit -m "$(cat <<'EOF'
Make go a thin router and remove duplicated references.

EOF
)"
```

---

### Task 4: 删除 comment/logging Skill，并入 `go-code-style`

Files:
- Delete: `skills/go-development/go-comment-style/`
- Delete: `skills/go-development/go-logging/`
- Modify: `skills/go-development/go-code-style/SKILL.md`
- Modify: `skills/go-development/go-code-style/agents/openai.yaml`
- Modify/Create: `skills/go-development/go-code-style/references/code-style.md`
- Create: `skills/go-development/go-code-style/references/comment-style.md`
- Create: `skills/go-development/go-code-style/references/logging.md`
- Delete: `skills/go-development/go-code-style/references/*-conventions.md`

Interfaces:
- Consumes: 原 `go-code-style`、`go-comment-style`、`go-logging` 下全部 md
- Produces: 单一可安装 `go-code-style`，三份中文 reference

- [ ] Step 1: 写入 `SKILL.md`

```markdown
---
name: go-code-style
description: "用于编写、重构、评审、排查或解释 Go 通用代码风格、注释或日志时。"
---

# Go Code Style

本 Skill 覆盖通用代码风格、注释与日志。任务属于 API/Service/DAL/Model/Test/OpenAPI 时，必须先经 `$go` 路由，并另外加载对应层 Skill；禁止用本 Skill 替代层职责。

## 强制工作流

1. 确认变更范围与是否触及其它层；触及则必须同时加载对应 `go-*`。
2. 风格任务必须读 `references/code-style.md`。
3. 注释任务必须读 `references/comment-style.md`。
4. 日志任务必须读 `references/logging.md`。
5. 同时涉及多项时全部读取；禁止只读其一却改其它领域。
6. 修改 Go 文件后必须 `goimport`；能测必须最小范围 `go test`。

## 禁止清单

- 禁止把业务编排、HTTP 适配、DB 访问塞进「风格清理」。
- 禁止新增复述型注释；命名能表达则禁止用注释凑数。
- 禁止在 DAL/Model 默认路径新增业务日志。
- 禁止日志 Msg 使用中文；禁止注释使用英文（标识符除外）。
- 禁止软性逃避措辞。

## 交付门禁

- 已读本次涉及的全部 reference。
- 风格/注释/日志边界未互相污染层职责。
- 已 `goimport`；能测则已测试。
```

- [ ] Step 2: 写入 `agents/openai.yaml`

```yaml
interface:
  display_name: "Go Code Style"
  short_description: "Go 风格、注释与日志硬约束"
  default_prompt: "使用 $go-code-style，按任务读取 code-style / comment-style / logging reference，严格执行禁止清单。"
```

- [ ] Step 3: 重写三份 reference

从以下源合并为中文严厉版（覆盖源中每条硬规则，删除重复与软句）：

| 目标 | 源 |
|------|----|
| `references/code-style.md` | `go-code-style/references/code-style.md` + `code-style-conventions.md` |
| `references/comment-style.md` | `go-comment-style/references/comment-style.md` + `comment-style-conventions.md` |
| `references/logging.md` | `go-logging/references/logging.md` + `logging-conventions.md` |

`code-style.md` 必须含（标题可同义，内容必须覆盖）：控制流与 early return、函数形态与禁止薄包装、防御检查边界、领域方法形态（Serialize 等）、文件行宽、常量、命名、变量声明、返回值、类型与接口、tag、时间字段、错误处理、context 与并发、与注释/日志的交界（指向同 Skill 其它文件）、格式化与测试门禁。

`comment-style.md` 必须含：何时必须写、何时禁止写、中文硬性、导出标识符、字段注释、禁止复述。

`logging.md` 必须含：谁拥有 logger、Msg 英文、级别、错误日志、敏感信息、各层日志边界、recover、禁止噪音。

- [ ] Step 4: 删除旧叶子与 conventions

```bash
rm -rf skills/go-development/go-comment-style skills/go-development/go-logging
rm -f skills/go-development/go-code-style/references/*-conventions.md
```

- [ ] Step 5: 验收

```bash
test -f skills/go-development/go-code-style/references/code-style.md
test -f skills/go-development/go-code-style/references/comment-style.md
test -f skills/go-development/go-code-style/references/logging.md
test ! -e skills/go-development/go-comment-style
test ! -e skills/go-development/go-logging
rg -n '建议|尽量|最好|可以考虑|推荐' skills/go-development/go-code-style && exit 1 || true
```

- [ ] Step 6: Commit

```bash
git add -A skills/go-development/go-code-style skills/go-development/go-comment-style skills/go-development/go-logging
git commit -m "$(cat <<'EOF'
Fold comment and logging into go-code-style as Chinese hard rules.

EOF
)"
```

---

### Task 5: 收敛 `go-api-layer`

Files:
- Modify: `skills/go-development/go-api-layer/SKILL.md`
- Modify: `skills/go-development/go-api-layer/agents/openai.yaml`
- Modify: `skills/go-development/go-api-layer/references/api-layer.md`
- Delete: `skills/go-development/go-api-layer/references/api-layer-conventions.md`

Interfaces:
- Consumes: 原 api-layer 双文件
- Produces: 单 reference + 严厉 SKILL；跨层点名 `go-service-layer` / `go-model-hierarchy` / `go-code-style`

- [ ] Step 1: 写入 `SKILL.md`

```markdown
---
name: go-api-layer
description: "用于编写、重构、评审、排查或解释 Gin/HTTP handler、请求绑定、响应 DTO 或分页响应时。"
---

# Go API Layer

API 层只做 HTTP 适配。禁止在 handler 内写复杂业务、聚合、DB/GORM/SQL 或模型生命周期逻辑。

## 强制工作流

1. 必须先经 `$go` 路由进入本 Skill。
2. 必须读取 `references/api-layer.md`。
3. 涉及 param/model 生命周期时必须加载 `go-model-hierarchy`；涉及编排时必须加载 `go-service-layer`；涉及风格/注释/日志时必须加载 `go-code-style`。
4. API struct 只持有 service、logger 或轻量 helper/config；依赖必须构造注入。
5. 修改后必须 `goimport`；能测必须 `go test`。

## 禁止清单

- 禁止 handler 访问 DAL/DB/GORM/SQL。
- 禁止在 handler 做复杂参数规整（必须落到拥有字段的 `Serialize()`）。
- 禁止 JSON tag 使用 `omitempty`。
- 禁止跳过 `$go` 或本 Skill reference 直接改 handler。

## 交付门禁

- 已读 `api-layer.md` 与路由要求的其它 Skill。
- Handler 瘦身符合 reference。
- 已 `goimport`；能测则已测。
```

- [ ] Step 2: yaml

```yaml
interface:
  display_name: "Go API Layer"
  short_description: "Gin/HTTP 适配层硬约束"
  default_prompt: "先经 $go，再使用 $go-api-layer 并严格执行 api-layer reference。"
```

- [ ] Step 3: 合并重写 `references/api-layer.md`（中文严厉）

必须覆盖原 conventions 全部章节：职责、结构、请求解析、HTTP 方法约定、更新模式、响应模式、handler 复杂度、类型规则、格式化与测试。删除英文正文与 soft 措辞。删除 `api-layer-conventions.md`。

- [ ] Step 4: 验收 + Commit

```bash
test ! -f skills/go-development/go-api-layer/references/api-layer-conventions.md
rg -n '建议|尽量|最好|可以考虑|推荐|go/references/' skills/go-development/go-api-layer && exit 1 || true
git add -A skills/go-development/go-api-layer
git commit -m "$(cat <<'EOF'
Consolidate go-api-layer into a single Chinese hard-rule reference.

EOF
)"
```

---

### Task 6: 收敛 `go-service-layer`

Files:
- Modify: `skills/go-development/go-service-layer/SKILL.md`
- Modify: `skills/go-development/go-service-layer/agents/openai.yaml`
- Modify: `skills/go-development/go-service-layer/references/service-layer.md`
- Delete: `skills/go-development/go-service-layer/references/service-layer-conventions.md`

- [ ] Step 1: `SKILL.md`

```markdown
---
name: go-service-layer
description: "用于编写、重构、评审、排查或解释 Go service 接口、构造注入、业务编排或错误包装时。"
---

# Go Service Layer

Service 负责业务编排。禁止直接访问 DB、GORM、SQL。禁止把 DAL/Model 职责搬进 service。

## 强制工作流

1. 必须先经 `$go`。
2. 必须读 `references/service-layer.md`。
3. 触及 DAL/Model/日志/风格/测试时必须加载对应 `go-*`。
4. interface、struct、constructor 必须同步；依赖必须显式注入。
5. 修改后必须 `goimport`；能测必须 `go test`。

## 禁止清单

- 禁止 service 内临时 new 长期依赖或用 nil 依赖跳过逻辑。
- 禁止直接 DB/GORM/SQL。
- 禁止无用户确认擅自把已有多参数导出方法改成其它形状（分层已规定签名除外）。

## 交付门禁

- 已读 service-layer reference 与所需跨层 Skill。
- 依赖注入与边界符合 reference。
- 已 `goimport`；能测则已测。
```

- [ ] Step 2: yaml 中文严厉；合并重写 `service-layer.md`；删除 conventions

覆盖原章节：职责、结构与注入顺序、方法签名、编排、错误包装、与 DAL/Model 边界、测试门禁。

- [ ] Step 3: 验收 + Commit（同 Task 5 命令模式，路径换成 `go-service-layer`，commit message：`Consolidate go-service-layer into a single Chinese hard-rule reference.`）

---

### Task 7: 收敛 `go-query-dal`

Files:
- `skills/go-development/go-query-dal/SKILL.md`
- `skills/go-development/go-query-dal/agents/openai.yaml`
- `skills/go-development/go-query-dal/references/query-dal.md`
- Delete conventions

- [ ] Step 1: `SKILL.md`

```markdown
---
name: go-query-dal
description: "用于编写、重构、评审、排查或解释 Go store/DAL/DAO、GORM 查询、CRUD 或持久化边界时。"
---

# Go Query DAL

DAL 只编排持久化。禁止承载业务规则。一个 DAL 方法围绕一个主要 data model。

## 强制工作流

1. 必须先经 `$go`。
2. 必须读 `references/query-dal.md`。
3. 触及 model/service/风格/日志/测试时必须加载对应 `go-*`。
4. 每个 DB 方法必须创建 timeout context，并 `WithContext(cancelCtx)`；表名必须来自主要 model 的 `TableName()`。
5. 修改后必须 `goimport`；能测必须 `go test`。

## 禁止清单

- 禁止在 DAL 写业务决策、跨资源业务聚合。
- 禁止默认在 DAL 打业务日志。
- 禁止无 timeout 的 DB 调用。

## 交付门禁

- 已读 query-dal reference 与所需跨层 Skill。
- 签名、receiver（`dal`）、边界符合 reference。
- 已 `goimport`；能测则已测。
```

- [ ] Step 2: 合并重写 `query-dal.md`（覆盖原 conventions 全部硬规则）+ 删 conventions + 验收 + Commit  
  message: `Consolidate go-query-dal into a single Chinese hard-rule reference.`

---

### Task 8: 收敛 `go-model-hierarchy`

Files:
- `skills/go-development/go-model-hierarchy/SKILL.md`
- `agents/openai.yaml`
- `references/model-hierarchy.md`
- Delete conventions

- [ ] Step 1: `SKILL.md`

```markdown
---
name: go-model-hierarchy
description: "用于编写、重构、评审、排查或解释 Go domain/GORM model、param、response、校验或字段生命周期时。"
---

# Go Model Hierarchy

Model 层拥有字段契约与生命周期。禁止把 HTTP 适配或 DB 会话管理塞进 model。

## 强制工作流

1. 必须先经 `$go`。
2. 必须读 `references/model-hierarchy.md`。
3. 触及注释/风格/DAL/service/API/测试时必须加载对应 `go-*`。
4. 先定模型树再写 struct；`Serialize`/`Deserialize`/`ToUpdater`/`Check`/`Same` 禁止互相调用。
5. 修改后必须 `goimport`；能测必须 `go test`。

## 禁止清单

- 禁止 JSON tag `omitempty`。
- 禁止生命周期方法互相调用。
- 禁止在 model 默认路径打业务日志。

## 交付门禁

- 已读 model-hierarchy reference 与所需跨层 Skill。
- 字段契约与生命周期符合 reference。
- 已 `goimport`；能测则已测。
```

- [ ] Step 2: 合并重写 + 删 conventions + 验收 + Commit  
  message: `Consolidate go-model-hierarchy into a single Chinese hard-rule reference.`

---

### Task 9: 收敛 `go-test-writer`

Files:
- `skills/go-development/go-test-writer/SKILL.md`
- `agents/openai.yaml`
- `references/test-writer.md`
- Delete conventions

- [ ] Step 1: `SKILL.md`

```markdown
---
name: go-test-writer
description: "用于创建、补全、评审、排查或解释 Go _test.go、表驱动测试、testify 或 mock 时。"
---

# Go Test Writer

测试必须覆盖真实分支、错误路径与边界。禁止为刷覆盖率写无断言测试。

## 强制工作流

1. 必须先经 `$go`。
2. 必须读 `references/test-writer.md`。
3. 被测对象属于某层时必须加载对应层 `go-*`。
4. 默认表驱动；`assert`/`require`/`mock` 按 reference 强制选用。
5. 修改后必须跑最小必要 `go test`；能定位包或单测名时必须精确执行。

## 禁止清单

- 禁止 `time.Sleep` 赌时序。
- 禁止无断言或只打印的测试。
- 禁止跳过错误路径。

## 交付门禁

- 已读 test-writer reference 与所需层 Skill。
- 相关 `go test` 已通过，或无法运行时已说明原因。
```

- [ ] Step 2: 合并重写（源已是中文为主，仍须去掉软措辞并删 conventions）+ 验收 + Commit  
  message: `Consolidate go-test-writer into a single Chinese hard-rule reference.`

---

### Task 10: 收敛 `go-gin-openapi-json` 为单接口唯一 OpenAPI Skill

Files:
- Modify: `skills/go-development/go-gin-openapi-json/SKILL.md`
- Modify: `skills/go-development/go-gin-openapi-json/agents/openai.yaml`
- Modify: `skills/go-development/go-gin-openapi-json/references/gin-openapi-json.md`
- Delete: `skills/go-development/go-gin-openapi-json/references/gin-openapi-json-conventions.md`
- Delete: `skills/go-development/go-gin-openapi-json/references/api-layer.md`
- Delete: `skills/go-development/go-gin-openapi-json/references/api-layer-conventions.md`
- Create: `skills/go-development/go-gin-openapi-json/scripts/generate.sh`（从 `skills/gin-openapi-json/scripts/generate.sh` 迁入；注释改中文）
- Ensure: `skills/go-development/go-gin-openapi-json/assets/openapi.json`
- Delete: `skills/gin-openapi-json/`（整个目录）

Interfaces:
- Consumes: `skills/gin-openapi-json/` 单接口铁律与脚本；废弃多接口 conventions
- Produces: 唯一 OpenAPI Skill；需要对齐 handler 时点名 `go-api-layer`（不拷贝其 reference）

- [ ] Step 1: 写入 `SKILL.md`（吸收原 gin-openapi-json checklist，全文中文严厉）

必须包含：

- frontmatter：`name: go-gin-openapi-json`；description 仅触发条件；保留 `runAs: subagent` 与 `argument-hint`（若原独立 Skill 有）。
- 铁律：每次只生成一个接口；扫描到其它接口一律忽略。
- 全量重建：禁止合并旧 JSON、禁止保留代码中已删除字段/路由。
- Step 0：必须先跑 `bash scripts/generate.sh <SELECTOR> [--output <path>]`，失败则停。
- 选择器只接受能唯一命中的 method+path 或 handler 名；模糊选择器必须拒绝。
- 必须读 `references/gin-openapi-json.md`；模板读 `assets/openapi.json`。
- 需要对齐 API 形态时必须加载 `go-api-layer`，禁止在本目录保留 api-layer 拷贝。
- 交付：写出文件、校验 JSON/`$ref`/path 参数，报告路径；未完成校验禁止宣称成功。

- [ ] Step 2: 迁入脚本与资产

```bash
mkdir -p skills/go-development/go-gin-openapi-json/scripts
cp skills/gin-openapi-json/scripts/generate.sh skills/go-development/go-gin-openapi-json/scripts/generate.sh
chmod +x skills/go-development/go-gin-openapi-json/scripts/generate.sh
# assets/openapi.json：若 go-gin-openapi-json 已有则保留；否则从 gin-openapi-json 或旧 go/assets 拷入后只留一份
test -f skills/go-development/go-gin-openapi-json/assets/openapi.json || \
  cp skills/gin-openapi-json/assets/openapi.json skills/go-development/go-gin-openapi-json/assets/openapi.json
```

将 `generate.sh` 用户可见 echo/注释改为中文；保持 CLI 行为：校验 selector、向上找 `go.mod`、默认输出名、`mkdir -p`、打印 JSON `{selector,output,project_root}`。

- [ ] Step 3: 重写唯一 `references/gin-openapi-json.md`

以 `skills/gin-openapi-json/references/gin-openapi-json-conventions.md` 与单接口 SKILL 为准翻译/重写为中文严厉版。  
删除一切多接口、路由组、模块批量出文档表述。  
删除本 Skill 内 `*-conventions.md` 与任何 `api-layer*` 拷贝。

- [ ] Step 4: 删除独立 Skill

```bash
rm -rf skills/gin-openapi-json
```

- [ ] Step 5: 验收

```bash
test ! -e skills/gin-openapi-json
test -f skills/go-development/go-gin-openapi-json/scripts/generate.sh
test -f skills/go-development/go-gin-openapi-json/assets/openapi.json
test ! -f skills/go-development/go-gin-openapi-json/references/api-layer.md
rg -n '多个接口|路由组|整库|建议|尽量|最好|可以考虑|推荐' skills/go-development/go-gin-openapi-json && exit 1 || true
# 「多个接口」若出现在「禁止一次生成多个接口」这类禁令句中允许；用更精确检查：
rg -n '为多个接口生成|批量生成|路由组的.*文档' skills/go-development/go-gin-openapi-json && exit 1 || true
```

- [ ] Step 6: Commit

```bash
git add -A skills/go-development/go-gin-openapi-json skills/gin-openapi-json
git commit -m "$(cat <<'EOF'
Make go-gin-openapi-json the sole single-operation OpenAPI skill.

EOF
)"
```

---

### Task 11: 全量结构验收与重装核对

Files:
- Verify only: `scripts/check.sh`、安装结果

- [ ] Step 1: 跑仓库校验

Run: `./scripts/check.sh`  
Expected: `check passed`

- [ ] Step 2: 结构抽查

```bash
ls skills/go-development
# 必须恰好：go go-api-layer go-code-style go-gin-openapi-json go-model-hierarchy go-query-dal go-service-layer go-test-writer
find skills/go-development -name '*-conventions.md' | tee /tmp/conv.txt
test ! -s /tmp/conv.txt
test ! -d skills/go-development/go/references
rg -n '建议|尽量|最好|可以考虑|推荐' skills/go-development --glob '*.md' --glob '*.yaml' && exit 1 || true
rg -n 'go/references/' skills/go-development && exit 1 || true
```

- [ ] Step 3: 重装并核对安装名

Run: `./scripts/install-operations.sh`（若只需 Go 相关且该脚本会清安装目录，按 README 使用；否则 `./scripts/install.sh`）

然后：

```bash
ls ~/.agents/skills | rg '^(go|go-|gin-openapi)'
```

Expected：出现 `go`、`go-api-layer`、`go-code-style`、`go-gin-openapi-json`、`go-model-hierarchy`、`go-query-dal`、`go-service-layer`、`go-test-writer`；不出现 `go-comment-style`、`go-logging`、`gin-openapi-json`。

- [ ] Step 4: 若有修复，单独 commit；否则记录验证通过

```bash
git status
# 无差异则无需 commit；有校验相关修复则：
# git add -A && git commit -m "Fix residual Go consolidation check failures."
```

---

## Plan Self-Review

| Spec 项 | 对应 Task |
|---------|-----------|
| 薄路由 `go`、无 references/assets | Task 3 |
| 分层多 Skill 集合 | Task 2、4–10 |
| 注释/日志并入 code-style | Task 4 |
| 删独立 gin-openapi、单接口 | Task 10 |
| 全文中文 + 严厉措辞 | Global Constraints + 各 Task 验收 rg |
| 零拷贝、删 pairs | Task 2、3、10 |
| check/manifest/README/重装 | Task 1、2、11 |

占位符扫描：无 TBD/TODO；各 Task 含明确路径与命令。  
大型 reference 正文在 Task 内以「必须覆盖的源文件 + 章节清单 + 严厉中文重写」交付，避免计划内嵌数千行重复译文，同时用 rg/find/`check.sh` 做可机器验收门禁。
