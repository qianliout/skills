---
name: go-api-layer
description: "Go API/handler/controller 层专家。Use when writing, refactoring, or reviewing Gin/HTTP handlers, request binding, query/body params, response DTOs, pagination responses, service calls, JSONOK/JSONError, or API layer conventions."
---

# Go API Layer

API 层只负责 HTTP 适配：解析请求、基础校验入口、调用 service、统一响应。复杂参数组装、关联聚合、业务编排和复杂响应组装放到 service 层。

## Workflow

1. 识别 API 边界：确认 handler、query/body/header 来源、service 依赖、返回 items/count/page 信息。
2. 加载 `references/go-api-conventions.md`，按项目约定处理路由、请求解析、错误响应和分页响应。
3. 定义结构：API struct 只持有 service、logger 或轻量依赖；依赖通过构造函数注入；handler 方法统一使用指针接收者。
4. 解析请求：所有请求参数使用 query 传参，body 使用项目既有 JSON binding；字段多时组装语义化 param。
5. 校验与调用：带领域方法的 param/DTO 使用指针变量；param 有 `Serialize()` 时用原变量接收返回值，再执行 `Check()`；handler 不直接访问 DB/GORM/DAL；trim/default/derive/fill 等领域规整统一放到拥有字段的 param/DTO 的公有 `Serialize()` 中。
6. 响应交付：使用统一 response helper；列表响应包含 items、total、itemsPerPage、startIndex。

## Reference Loading

生成、重构或评审 API/handler/controller 层代码时，必须加载 `references/go-api-conventions.md`。

## Pre-Delivery Checklist

- [ ] API struct 只持有 service/logger/轻量依赖，依赖由构造函数注入。
- [ ] handler/API 方法都使用指针接收者，例如 `func (api *XxxAPI) Action(ctx *gin.Context)`，没有值接收者。
- [ ] Handler 签名符合项目框架约定；handler 内没有重复 nil 防御判断。
- [ ] HTTP 方法只使用 `GET`、`POST`、`PUT`、`DELETE`，除非用户明确确认例外。
- [ ] 请求 param、response DTO 定义在 model/API 类型层，没有 handler 内临时 struct。
- [ ] 带领域方法的 param/DTO 使用指针变量，便于 `Serialize()` / `Deserialize()` 在 nil receiver 场景返回新对象。
- [ ] 所有请求参数使用 query 传参，没有 path 参数。
- [ ] `PUT` 更新为全量更新，query 必传更新 ID，body 传全量内容。
- [ ] 字段较多的入参已收敛为语义化 param struct。
- [ ] 有 param 领域方法时，调用 service 前按 `param = param.Serialize()`、`param.Check()` 顺序执行。
- [ ] Handler 内没有散落 trim/default/derive/fill 逻辑；领域规整已挂到拥有字段的 param/DTO 的公有 `Serialize()` 上，没有 `Normalize()`、`FillDefault()` 或小写规整方法。
- [ ] API 层没有 DB/GORM/DAL 操作；复杂逻辑组装、关联聚合和业务编排留在 service。
- [ ] 错误通过统一 response 返回；列表响应包含分页信息且空列表是空切片。
- [ ] 没有新增 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
