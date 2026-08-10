# Go Skills 收敛设计

日期：2026-08-10  
状态：已批准（对话确认）

## 1. 问题

当前 Go 相关 Skill 存在三类结构性缺陷：

1. **双轨物理拷贝**：`go/references/*` 与各 `go-* /references/*` 各维护一份相同正文；同步脚本与校验未落地，仓库与安装目录已出现漂移。
2. **发现与语义冲突**：同时安装总入口、分层叶子、以及两套 OpenAPI Skill（`gin-openapi-json` 单接口 vs `go-gin-openapi-json` 多接口）。
3. **语言与语气不一致**：入口/概览偏中文，多数 `*-conventions.md` 偏英文；大量「建议/尽量」软措辞，约束力不足。

## 2. 目标（验收即定义）

1. **分层多 Skill**：按层保留独立可安装 Skill；注释与日志并入代码风格 Skill。
2. **`go` 仅薄路由**：总入口只做强制路由、层边界与全局门禁；**不得**再持有各层细则正文或拷贝。
3. **单一事实源**：每个领域规则只存在于对应 `go-*` 目录内；零物理拷贝、零双份同步表。
4. **全文中文**：所有 `SKILL.md`、reference、`agents/openai.yaml`、脚本注释与用户可见说明均为中文。
5. **OpenAPI 单接口**：只保留一个 OpenAPI Skill；一次只生成一个 operation。
6. **措辞严厉**：必须 / 禁止 / 不得 / 违规即停；禁止「建议」「尽量」「可以考虑」等软性逃避句。
7. **安装与校验**：manifest、README、`check.sh` 与重装结果与上述结构一致。

## 3. 非目标

- 不改动非 Go 分类 Skill（`documents`、`code-quality` 等）的结构。
- 不在本次引入 symlink 跨 Skill 共享文件（扁平安装下易碎）；共享只通过「点名加载其它 Skill」，不复制正文。
- 不保留「多接口 / 路由组批量出文档」能力。

## 4. 最终可安装 Skill 集合

| 安装名 | 职责 |
|--------|------|
| `go` | 薄路由总入口：识别任务 → 强制加载对应 `go-*`；层边界；全局交付门禁 |
| `go-code-style` | 通用代码风格 + **注释** + **日志** |
| `go-api-layer` | Gin/HTTP handler、请求绑定、响应 |
| `go-service-layer` | Service 编排与边界 |
| `go-query-dal` | DAL/DAO/GORM |
| `go-model-hierarchy` | Model/Param/Response 与字段生命周期 |
| `go-test-writer` | `_test.go`、testify、table-driven |
| `go-gin-openapi-json` | 从 Gin 代码生成 OpenAPI 3.1.0 JSON；**单接口** |

### 4.1 必须删除的安装入口

- `skills/go-development/go-comment-style/`（全文并入 `go-code-style`）
- `skills/go-development/go-logging/`（全文并入 `go-code-style`）
- `skills/gin-openapi-json/`（能力并入 `go-gin-openapi-json`，含 scripts/assets/铁律）
- `go/references/` 下全部与叶子重复的细则文件，以及仅服务于 OpenAPI 的 `go/assets/`（迁到 `go-gin-openapi-json`）
- `scripts/go-reference-pairs.txt` 及任何「双份同步」设计/文档表述

### 4.2 目录形态（叶子）

每个 `go-*`（含 OpenAPI）：

```
go-<name>/
  SKILL.md                 # 中文；严厉；短路由/门禁，不堆细则
  agents/openai.yaml       # 中文
  references/<topic>.md    # 唯一细则文件（合并原 overview + conventions）
  # 仅 OpenAPI 额外：
  assets/openapi.json
  scripts/generate.sh
```

`go` 总入口：

```
go/
  SKILL.md
  agents/openai.yaml
  # 禁止 references/ 中再放 api/service/dal/... 细则
  # 禁止 assets/openapi.json
```

## 5. 路由与加载铁律

1. 任何 Go 相关任务：**必须先加载 `go`**，再按路由加载对应 `go-*`。跳过总入口直接开写 = 违规。
2. `go` **禁止**粘贴各层细则；只允许：任务识别、Skill 路由表、层边界、全局门禁（如改 Go 文件后必须 `goimport`、能跑则跑最小范围 `go test`）。
3. 跨层任务：只加载**实际修改、评审或解释到的层**。禁止因调用链存在某层就加载该层。
4. 注释、日志、通用风格、命名、错误处理、控制流：一律路由到 `go-code-style`。
5. OpenAPI / Apifox / `openapi.json`：一律路由到 `go-gin-openapi-json`；生成前若需对齐 handler 形态，可再加载 `go-api-layer`，不得再加载已删除的独立 OpenAPI Skill。
6. 叶子 Skill **禁止**指引去读 `go/references/...`。需要其它层时：点名 Skill（例如「必须同时加载 `go-model-hierarchy`」），禁止复制对方正文。
7. 叶子之间禁止互相拷贝 reference 文件。

## 6. OpenAPI 语义（单接口）

以现有 `gin-openapi-json` 为准，收敛进 `go-gin-openapi-json`：

- **铁律**：每次只生成一个接口（一个 path + 一个 HTTP method）。扫描到相邻路由、同组其它方法、同 handler 其它接口时一律忽略。
- 每次生成都是对当前代码的全量重建目标文件内容；禁止为「兼容旧 JSON」而合并、保留已删除字段或路由。
- 范围缺失或选择器歧义：必须停下来向用户索取可唯一确定的 method+path 或 handler 名；禁止擅自扩大范围。
- 废弃并删除一切「多接口、路由组、模块批量出文档」表述（含原 `go-gin-openapi-json` / `go` 内多接口 conventions）。
- `scripts/generate.sh` 与单接口 workflow checklist 迁入 `go-gin-openapi-json`；全文中文；语气严厉。

## 7. 内容合并与语言

1. 每个领域将原 `references/<x>.md` 与 `references/<x>-conventions.md` **合并为一份**中文 `references/<x>.md`，然后删除 `*-conventions.md`。
2. `go-code-style` 在本 Skill 的 `references/` 下维护三份中文细则（禁止再拆成独立可安装 Skill）：
   - `code-style.md` — 通用代码风格
   - `comment-style.md` — 注释规范
   - `logging.md` — 日志规范
   其它叶子仍为「一域一份」：合并原 overview + conventions 后只留一个 `<topic>.md`。
3. description 只写触发条件（中文），禁止在 description 里写流程摘要或「本 Skill 会做什么」。
4. 全文消灭英文规范正文；代码标识符、命令、包名、JSON 字段名保留原文。

## 8. 措辞规范（强制）

适用于全部 Go 相关 `SKILL.md`、reference、yaml、脚本帮助信息：

| 禁止 | 必须改成 |
|------|----------|
| 建议 / 尽量 / 最好 / 可以考虑 / 推荐 | 必须 / 禁止 / 不得 |
| 软性例外（「除非特殊情况」且无判定条件） | 有可观察条件的显式分支，或删除例外 |
| 「参考其它层时酌情」 | 点名 Skill + 强制加载条件 |

每个叶子 Skill 必须包含：

- **禁止清单**（违规即停）
- **交付门禁**（未满足不得宣称完成）

## 9. 仓库与安装变更清单

1. 删除第 4.1 节列出的目录与文件。
2. 重写 `skills/go-development/go/SKILL.md` 为薄路由。
3. 重写/合并各保留 `go-*` 的 SKILL 与 reference（中文、严厉、单文件细则）。
4. 将 `skills/gin-openapi-json/` 的脚本、资产、单接口铁律并入 `go-gin-openapi-json` 后删除前者。
5. 更新 `README.md`：Go 分类只列出第 4 节集合；删除「物理拷贝需同步」维护约定；运维组合中的 Go 项只列保留 Skill。
6. 更新 `skills/manifests/operations-skills.txt`：去掉 `go-comment-style`、`go-logging`、`gin-openapi-json`；保留新集合。
7. 更新 `scripts/check.sh`（或等价校验）：
   - `go-development` 下不得存在 `go-comment-style`、`go-logging` 目录；
   - 仓库根 `skills/gin-openapi-json` 不得存在；
   - `go/references` 若存在，不得包含 `api-layer`、`service-layer`、`query-dal`、`model-hierarchy`、`logging`、`comment-style`、`test-writer`、`gin-openapi-json`、`code-style` 等细则文件（推荐：`go` 无 `references/` 目录）；
   - 不得再依赖 `go-reference-pairs.txt`。
8. 删除 `scripts/go-reference-pairs.txt`。
9. 通过 `./scripts/check.sh`；按仓库惯例重装后确认 `~/.agents/skills` 中 Go 相关名与第 4 节一致。

## 10. 风险与迁移

- 已习惯 `$go-logging` / `$go-comment-style` / `$gin-openapi-json` 的调用方必须改用 `$go-code-style` / `$go-gin-openapi-json`。
- 合并 reference 时禁止「只翻译标题、正文仍英文」；禁止两份 conventions 机械拼接导致重复矛盾——合并时以严厉中文重写为一份权威文本。
- 原 `go` 与叶子若有漂移，以**更完整且不与单接口铁律冲突**的内容为素材，最终以本设计为准重写，不搞双文件 diff 式长期共存。

## 11. 实现顺序（供后续 plan 拆解）

1. 定稿本 spec → 实现计划。
2. 先改 `check.sh` / manifest / README 的结构断言（红），再删目录与重写内容（绿）。
3. 先落地 `go` 薄路由 + 删除拷贝，再逐个收敛叶子内容与中文严厉化。
4. 最后合并 OpenAPI（删独立 `gin-openapi-json`），跑 `check.sh` 与安装验证。

## 12. 明确决议记录

| 议题 | 决议 |
|------|------|
| 语言 | 全文中文 |
| OpenAPI | 单接口；唯一 Skill 名 `go-gin-openapi-json` |
| 总入口 | 保留薄路由 `go` |
| 分层 | 多 Skill；细则只在叶子 |
| 注释 / 日志 | 并入 `go-code-style`；删除独立 Skill |
| 语气 | 严厉（必须/禁止） |
| 拷贝 | 消灭；不保留同步表 |
