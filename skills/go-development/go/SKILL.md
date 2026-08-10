---
name: go
description: "用于编写、重构、评审、排查、测试或解释任何 Go 代码时。"
---

# Go

把本 Skill 当作全部 Go 任务的强制总入口。禁止跳过本 Skill 直接凭印象改 Go 代码。本 Skill 不含各层细则；细则只在对应 `go-*` Skill 中。

## 强制工作流

1. 识别任务类型与实际触及的层（实现 / 重构 / 评审 / 排查 / 测试 / 解释 / 单接口 OpenAPI）。
2. 读取就近代码：相邻文件、接口、构造函数、调用方、测试。
3. 按下方路由表加载**且仅加载**实际需要的 `go-*` Skill（先读其 `SKILL.md`，再读其 reference）。
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
