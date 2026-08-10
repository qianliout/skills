# Task 7 Report

已将 `go-query-dal` 收敛为单个中文硬规则 reference，并删除 `query-dal-conventions.md`。

- `SKILL.md` 与 `agents/openai.yaml` 已按 brief 更新。
- reference 覆盖 DAO 结构、依赖、timeout context、`TableName()`、签名、`SearchXxx`、CRUD、查询链、SQL 限制、日志与验证。
- DAL 规则明确禁止业务决策、跨资源业务聚合与业务日志。
- `test ! -f .../query-dal-conventions.md` 及 soft wording 扫描通过。
- `bash scripts/check.sh` 未通过：现存 `skills/gin-openapi-json` 违反仓库全局收敛门禁，与本任务改动无关。
