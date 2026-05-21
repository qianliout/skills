---
name: go-api-layer
description: "通用 Go API/handler/controller 层专家，生成、重构、评审 Gin API 层代码。Use when user asks 写 API、写 handler、写 controller、Gin 路由处理、BindJSON、Query 参数解析、请求 param、响应 response、分页返回、调用 service、JSONOK/JSONError、HTTP 参数校验、API 层代码规范。Actions: design, create, refactor, review, implement Go API layer."
---

# Go API Layer

核心约束：API 层只负责 HTTP 入参解析、基础校验入口、调用 service、统一响应；不直接访问数据库，不承载复杂业务编排，不把 service/DAL/model 的职责搬到 handler。

## Workflow

- [ ] Step 1: 识别 API 边界 ⚠️ REQUIRED
  - [ ] 确认路由 handler、请求来源 query/path/body/header、service 依赖、返回 item/items/count/page 信息。
  - [ ] 确认请求 param 和响应 DTO 定义在 model/API 类型层，不在 handler 内临时定义 struct。
  - [ ] 判断方法类型：查询列表、详情、创建、更新、删除、内部接口、导出/异步触发。
- [ ] Step 2: 定义结构
  - [ ] API struct 只持有 service、logger 或轻量依赖。
  - [ ] 构造函数注入必需依赖；依赖有效性由初始化阶段保证，handler 内不重复判断 `api == nil` 或 `api.xxxSrv == nil`。
  - [ ] Gin handler 使用 `func (api *XxxAPI) Action(ctx *gin.Context)`。
- [ ] Step 3: 解析请求
  - [ ] query/path/header 通过项目既有 util/helper 解析；body 使用 `ShouldBindJSON`/`BindJSON` 或项目既有封装。
  - [ ] 将请求字段组装成语义化 param；字段多时使用 param struct，不在 handler 中堆大量散落变量。
  - [ ] 有 filter/pagination 时用项目既有 `GetFilter`/`GetFilterWithDefaultValue` 等 helper，并设置合理最大 limit。
  - [ ] param 提供 `Check()` 时在调用 service 前执行；复杂清洗、默认值、派生字段放 param 层。
- [ ] Step 4: 调用 service 并响应
  - [ ] handler 只调用 service，不直接访问 DB/GORM/DAL。
  - [ ] service 错误通过统一错误响应返回；需要业务语义转换时使用项目既有 i18n/wrap helper。
  - [ ] 列表响应返回 items、total、itemsPerPage、startIndex；空列表返回空切片。
  - [ ] 单对象响应使用统一 item/target response。
- [ ] Step 5: 交付检查
  - [ ] 运行 Pre-Delivery Checklist。
  - [ ] 修改 Go 文件后遵循 `go-code-style`，运行 `goimport` 和相关测试。

## Reference Loading

需要生成或评审 Go API/handler 层代码时，加载 `references/go-api-conventions.md`。

## Required Patterns

API struct 和构造函数：

```go
type XxxAPI struct {
    xxxSrv service.XxxService
}

func NewXxxAPI(xxxSrv service.XxxService) *XxxAPI {
    return &XxxAPI{xxxSrv: xxxSrv}
}
```

查询 handler：

```go
func (api *XxxAPI) SearchXxx(ctx *gin.Context) {
    param := model.SearchXxxAPIParam{
        Keyword: util.GetKeywordFromQuery(ctx, "keyword"),
        Filter:  model.GetFilter(ctx).SetMaxLimit(consts.DefaultMaxLimit),
    }
    if err := param.Check(); err != nil {
        response.JSONError(ctx, err)
        return
    }

    list, cnt, err := api.xxxSrv.SearchXxx(ctx, param)
    if err != nil {
        response.JSONError(ctx, wrapSearchXxxErr(err))
        return
    }

    response.JSONOK(ctx,
        response.WithItems(list),
        response.WithTotalItems(cnt),
        response.WithItemsPerPage(param.Filter.Limit),
        response.WithStartIndex(param.Filter.Offset),
    )
}
```

Body handler：

```go
func (api *XxxAPI) CreateXxx(ctx *gin.Context) {
    param := model.CreateXxxAPIParam{}
    if err := ctx.ShouldBindJSON(&param); err != nil {
        response.JSONError(ctx, response.NewHttpError(http.StatusBadRequest, err))
        return
    }
    if err := param.Check(); err != nil {
        response.JSONError(ctx, err)
        return
    }

    item, err := api.xxxSrv.CreateXxx(ctx, param)
    if err != nil {
        response.JSONError(ctx, wrapCreateXxxErr(err))
        return
    }
    response.JSONOK(ctx, response.WithItem(item))
}
```

## Anti-Patterns

- 不要在 API 层直接访问 DB/GORM/DAL。
- 不要在 handler 内写复杂业务编排、批量关联查询、循环调用 service 拼详情；复杂逻辑放 service。
- 不要在 handler 内临时定义 body/response struct；请求和响应类型应放在 model/API 类型层。
- 不要散落解析大量 query 变量后直接传下去；字段多时组装为语义化 param。
- 不要重复参数清洗、ID 规范化、默认值和派生字段计算；放到 `param.Check()` 或 param 方法。
- 不要吞掉 service 错误；统一 `JSONError` 返回，必要时按项目约定包装。
- 不要返回 nil slice 表示成功空列表。
- 不要新增 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型；类型约束遵循 model 层规则。
- 不要在有上游 request ctx 时改用 `context.Background()`。

## Pre-Delivery Checklist

- [ ] API struct 只持有 service/logger/轻量依赖。
- [ ] 构造函数注入依赖，handler 内没有重复 nil 防御判断。
- [ ] Handler 签名符合项目框架约定，如 `func (api *XxxAPI) Action(ctx *gin.Context)`。
- [ ] 请求 param、response DTO 定义在 model/API 类型层，没有 handler 内临时 struct。
- [ ] query/body/path 解析使用项目既有 util/helper。
- [ ] 字段较多的入参已收敛为语义化 param struct。
- [ ] 有 param 校验方法时，调用 service 前执行 `param.Check()`。
- [ ] API 层没有 DB/GORM/DAL 操作。
- [ ] 复杂业务编排留在 service，handler 只做解析、调用、响应。
- [ ] 错误通过统一 response 返回，业务错误包装遵循项目约定。
- [ ] 列表响应包含 items、total、itemsPerPage、startIndex，空列表使用空切片。
- [ ] 没有新增 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型。
- [ ] 没有 placeholder：`TODO`、`FIXME`、`xxx`。
