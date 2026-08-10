# Task 8 Report

- 已将 `go-model-hierarchy` 合并为单个中文硬规则 reference，并删除 `model-hierarchy-conventions.md`。
- `SKILL.md` 已改为 `$go` 路由、强制工作流、禁止清单与交付门禁；OpenAI 元数据已更新。
- reference 覆盖字段生命周期隔离、`omitempty` 禁令、receiver/签名、tag、存储、基础字段、类型、校验、序列化与 updater。
- 禁止软性措辞、旧 conventions 引用及 `go/references/` 的扫描通过。
- Ruby YAML 校验与 `git diff --check` 通过。
- `bash scripts/check.sh` 仍因既有独立 `skills/gin-openapi-json` 被全局门禁拒绝，与本任务无关。
- 提交信息：`Consolidate go-model-hierarchy into a single Chinese hard-rule reference.`
- 已明确 `Serialize()` 只负责写入前规整；旧枚举、秒级时间、历史默认值等存储读取兼容只归 `Deserialize()`。
- 已恢复业务 ID 硬规则：按来源类型使用稳定业务键生成；未生成业务 ID 的类型必须说明业务原因。
