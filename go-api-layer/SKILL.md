---
name: go-api-layer
description: "通用 Go API/handler/controller 层专家，生成、重构、评审 Gin API 层代码。Use when user asks 写 API、写 handler、写 controller、Gin 路由处理、BindJSON、Query 参数解析、请求 param、响应 response、分页返回、调用 service、JSONOK/JSONError、HTTP 参数校验、API 层代码规范。Actions: design, create, refactor, review, implement Go API layer."
---

# Go API Layer

API 层只负责 HTTP 适配：解析请求、基础校验入口、调用 service、统一响应。复杂参数组装、关联聚合、业务编排和复杂响应组装放到 service 层。

## Workflow

- [ ] Step 1: 识别 API 边界
  - 确认 handler、query/body/header 来源、service 依赖、返回 item/items/count/page 信息。
  - 请求 param 和响应 DTO 放在 model/API 类型层，不在 handler 内临时定义 struct。
  - 加载 `references/go-api-conventions.md`，按项目约定落地。
- [ ] Step 2: 定义结构
  - API struct 只持有 service、logger 或轻量依赖。
  - 构造函数注入依赖；handler 内不重复判断 `api == nil` 或 `api.xxxSrv == nil`。
  - Gin handler 使用项目既有签名，如 `func (api *XxxAPI) Action(ctx *gin.Context)`。
- [ ] Step 3: 解析请求
  - HTTP 方法一般只使用 `GET`、`POST`、`PUT`、`DELETE`。
  - 所有请求参数使用 query 传参，不使用 path 传参；body 使用项目既有 JSON binding。
  - `PUT` 更新必须是全量更新：query 必传更新 ID，body 传全量内容。
  - 字段多时组装语义化 param；filter/pagination 使用项目既有 helper 并设置合理最大 limit。
  - param 有 `Check()` 时调用 service 前执行；复杂清洗、默认值、派生字段放 param 层。
- [ ] Step 4: 调用 service 并响应
  - handler 不直接访问 DB/GORM/DAL。
  - service 错误通过统一错误响应返回，必要时使用项目既有包装/i18n helper。
  - 列表响应返回 items、total、itemsPerPage、startIndex；成功空列表返回空切片。
- [ ] Step 5: 交付
  - 修改 Go 文件后遵循 `go-code-style`，运行 `goimport` 和相关测试。
  - 运行 Pre-Delivery Checklist。

## Reference Loading

生成、重构或评审 API/handler 层代码时，必须加载 `references/go-api-conventions.md`。

## Pre-Delivery Checklist

- [ ] API struct 只持有 service/logger/轻量依赖，依赖由构造函数注入。
- [ ] Handler 签名符合项目框架约定；handler 内没有重复 nil 防御判断。
- [ ] HTTP 方法只使用 `GET`、`POST`、`PUT`、`DELETE`，除非用户明确确认例外。
- [ ] 请求 param、response DTO 定义在 model/API 类型层，没有 handler 内临时 struct。
- [ ] 所有请求参数使用 query 传参，没有 path 参数。
- [ ] `PUT` 更新为全量更新，query 必传更新 ID，body 传全量内容。
- [ ] 字段较多的入参已收敛为语义化 param struct。
- [ ] 有 param 校验方法时，调用 service 前执行 `param.Check()`。
- [ ] API 层没有 DB/GORM/DAL 操作；复杂逻辑组装、关联聚合和业务编排留在 service。
- [ ] 错误通过统一 response 返回；列表响应包含分页信息且空列表是空切片。
- [ ] 没有新增 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
