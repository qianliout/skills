---
name: go-service-layer
description: "Go Service 层 Skill。Use when writing, refactoring, reviewing, debugging, or explaining service interfaces, service structs, constructor injection, business orchestration, aggregation, cache/client calls, error wrapping, and service-layer boundaries."
---

# Go Service Layer

用于 Go service 层任务。Service 负责业务编排、参数校验入口、模型转换、结果聚合、日志和错误包装；不直接访问 DB、GORM 或 SQL，也不把 DAL/model 的职责搬进 service。

## Workflow

1. 确认公开方法、param/response、依赖 DAL/service/cache/client/logger、错误语义和方法类型。
2. 读取 `references/service-layer.md` 和 `references/service-layer-conventions.md`。
3. 涉及 model、DAL、logging、code style 或测试时，再按需使用对应 Go 分类 Skill。
4. 同步 interface、struct、constructor；依赖按项目约定显式注入。
5. 实现公开方法：`ctx context.Context` 优先，资源/动作级方法名，按需要执行 `Serialize()` / `Check()`，再编排依赖。
6. 修改 Go 文件后运行 `goimport`；能定位包或测试时运行最小范围 `go test`。

## Layer Boundaries

- Service 不直接访问数据库、GORM 或 SQL；持久化通过 DAL/repository。
- 公开接口保持资源/动作级别，不因为调用方、租户、项目或权限场景拆窄方法。
- 不在业务方法里临时创建长期依赖，不用 nil 注入依赖跳过业务。
- 复杂聚合可以拆 helper，但避免一两行转调组成薄 helper 链。

## Pre-Delivery Checklist

- 已读取本 Skill 的两个 reference。
- interface、struct、constructor 和 receiver 符合约定。
- Service 只做业务编排，没有侵入 DAL/model/API 职责。
- 修改 Go 文件后已运行 `goimport`；能运行时已执行相关 `go test`。
