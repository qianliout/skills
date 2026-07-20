---
name: go-model-hierarchy
description: "Go Model/Param/Response 层级 Skill。Use when writing, refactoring, reviewing, debugging, or explaining Go domain models, GORM models, params, responses/views, validation, serialization, deserialization, ToUpdater, field lifecycle, tags, and model ownership."
---

# Go Model Hierarchy

用于 Go model、param、response/view、cache/statistic 和字段生命周期任务。Model 层负责字段契约、校验、序列化、反序列化、派生字段和更新字段选择。

## Workflow

1. 先识别模型职责：实体、param、response/view、cache/statistic 或辅助值对象。
2. 读取 `references/model-hierarchy.md` 和 `references/model-hierarchy-conventions.md`。
3. 涉及 code style、comment、logging、DAL/service/API 或测试时，再按需使用对应 Go 分类 Skill。
4. 先给模型树，再写 struct；实体优先，param/view/cache/statistic 跟随所属实体或业务域。
5. 定义字段契约、tag、时间和数值类型；复杂结构优先文本列配合 `Serialize()` / `Deserialize()`。
6. 修改 Go 文件后运行 `goimport`；能定位包或测试时运行最小范围 `go test`。

## Layer Boundaries

- 领域规整统一归属到拥有字段的公有 `Serialize()`。
- `Serialize()` / `Deserialize()` / `ToUpdater()` / `Check()` / `Same()` 不互相调用，组合顺序由外部决定。
- Model 层不依赖 API、service、DAL 等业务层。
- 常量统一放到项目定义的 `consts` 目录，不散落在 model 文件中。

## Pre-Delivery Checklist

- 已读取本 Skill 的两个 reference。
- 模型层级、字段生命周期、tag、时间/数值类型和复杂结构存储策略清楚。
- Param、校验、序列化、反序列化、派生字段和更新字段选择都归属正确。
- 修改 Go 文件后已运行 `goimport`；能运行时已执行相关 `go test`。
