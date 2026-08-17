# Go API Layer

API 层只负责 HTTP 适配：读取框架上下文、构造类型化参数、执行参数校验、调用 service，并使用项目响应 helper 返回结果。API 层不得承担领域决策、持久化、跨资源聚合或模型生命周期。

## 职责边界

- handler 必须只完成「handler 复杂度」规定的线性流程。
- handler 必须调用注入的 service；禁止直接访问 DB、GORM、SQL、DAL、缓存或外部 client。
- 错误返回必须遵守「错误处理边界」。
- param/DTO 生命周期、领域规整与 service 编排分别归属 `go-model-hierarchy` 和 `go-service-layer`。

## 结构与依赖

- API struct 只持有 service、logger、无状态轻量 helper 或 config。
- 所有依赖必须通过构造函数注入；禁止在 handler 内创建 service、DAL、client、cache 或 logger。
- 字段与构造参数顺序必须保持 service、轻量 helper/config、logger。
- 新增依赖时，必须同时修改 API struct、构造函数、构造赋值和路由或 bootstrap 注入。
- 构造与 bootstrap 必须保证依赖有效；禁止在 handler 中以 nil 判断跳过 service 调用、响应、校验或日志。
- API 方法必须使用指针接收者 `api`，并保持同一 API struct 的接收者名称与形式一致。
- 禁止为 API/handler 方法使用值接收者。

```go
type XxxAPI struct {
    xxxSrv service.XxxService
    log    *logger.Logger
}

func NewXxxAPI(xxxSrv service.XxxService) *XxxAPI {
    api := XxxAPI{
        xxxSrv: xxxSrv,
        log: logger.New(
            logger.WithModule("moduleName"),
            logger.WithSubModule("api"),
        ),
    }
    return &api
}
```
## 请求解析

- 禁止使用 path param。
- `POST` 的全部请求参数必须来自 JSON body。
- `PUT` 的更新 `id` 或 `uniqueID` 必须来自 query，其余更新字段必须来自 JSON body。
- 除 `POST` 和 `PUT` 外，请求参数必须来自 query。
- query 与 header 必须使用项目既有 helper 解析；JSON body 必须使用 `ShouldBindJSON`、`BindJSON` 或项目 wrapper。
- 调用 service 前必须把 HTTP 原始字符串转换为类型化 param。
- 参数较多时必须使用单个语义化 param struct；禁止使用大量位置参数。
- param 和响应 DTO 必须定义在 model/API 类型层；禁止在 handler 函数内声明请求或响应 struct。
- param 与响应 DTO 的 JSON tag 必须显式声明，且禁止使用 `omitempty`。
- HTTP 请求参数名（query、JSON body 字段）与响应 JSON 字段名默认统一使用小驼峰（camelCase），如 `projectId`、`uniqueId`、`itemsPerPage`；项目已有明确命名约定时遵循项目约定。
- 新设计 API 的所有时间请求或响应字段必须使用 `int64` 毫秒时间戳；既有 API 必须保持现有时间单位，除非用户明确要求迁移。
- trim、ID 规整、默认值与派生字段必须放入拥有字段的公开 `Serialize()`。
- 枚举与必填字段校验必须放入 `Check()`。
- 禁止在 handler 分散请求规整；禁止新建 `Normalize()`、`FillDefault()` 或包级 `NormalizeXxxParam` helper 替代 `Serialize()`。

## HTTP 方法

- `GET` 只用于只读列表或详情。
- `POST` 只用于创建、提交动作或非幂等操作。
- `PUT` 只用于完整更新。
- `DELETE` 只用于删除。
- 禁止引入 `PATCH`、`HEAD`、`OPTIONS` 或其他 HTTP 方法；用户明确确认例外时除外。

## 更新模式

- `PUT` 必须是完整更新，禁止将其实现为部分更新。
- 更新 `id` 或 `uniqueID` 必须通过 query 提供，示例为 `?id=123` 或 `?uniqueID=123`。
- 更新 body 必须包含其余完整更新内容。
- 禁止把更新 `id` 或 `uniqueID` 放入 path param。

```go
id := util.GetInt64FromQuery(ctx, "id")
body := model.UpdateXxxBody{}
if err := ctx.ShouldBindJSON(&body); err != nil {
    response.JSONError(ctx, response.NewErr(err))
    return
}

param := &model.UpdateXxxAPIParam{
    ID:   id,
    Data: body,
}
```

## 响应模式

- 必须使用项目统一 response helper 返回数据。
- `JSONError` 后必须立即 `return`。
- 成功的空列表必须返回空切片，禁止返回 `nil`。
- 分页响应必须包含 `items`、`total`、`itemsPerPage` 与 `startIndex`。
- 单条/详情成功响应必须通过 `response.JSONOK(ctx, response.WithItem(item))` 返回；禁止直接调用 `ctx.JSON`、`c.JSON` 或绕过项目 response helper。

列表响应：

```go
items, cnt, err := api.xxxSrv.SearchXxx(ctx, param)
if err != nil {
    response.JSONError(ctx, err)
    return
}

response.JSONOK(ctx,
    response.WithItems(items),
    response.WithTotalItems(cnt),
    response.WithItemsPerPage(param.Filter.Limit),
    response.WithStartIndex(param.Filter.Offset),
)
```

单条响应：

```go
item, err := api.xxxSrv.GetXxxDetail(ctx, param)
if err != nil {
    response.JSONError(ctx, err)
    return
}

response.JSONOK(ctx, response.WithItem(item))
```

## 错误处理边界

- 解析/绑定/校验失败必须 `response.JSONError(ctx, response.NewErr(err))`。
- service 返回的 error 必须原样 `response.JSONError(ctx, err)`，禁止再处理。

## handler 复杂度

- handler 只允许：解析请求、构造 param、`Serialize()`、`Check()`、调用 service、写响应。
- 超出上列的逻辑必须迁到 service 或 model。
- 禁止拆分 `parseXxxParam`、`buildXxxResponse`、`writeXxxOK` 等仅转发上述步骤的私有 helper。

## 类型规则

- 必须使用类型化 param 与 DTO；禁止使用 `any`、`interface{}` 或 `map[string]any` 承载 API 请求与响应。
- 禁止使用 `uint64`、`uint`、`bool` 或大于 `int64` 的数值类型；类型约束以 `go-model-hierarchy` 为准。
- 项目不使用 bool 字段时，状态必须使用 `"true"` 与 `"false"` 字符串。

## 格式化与测试

- 修改 Go 文件后必须运行 `goimport`。
- 必须运行受影响 package 的最小范围 `go test`。
- 变更路由注册或 middleware 行为时，必须验证路由接线、预期 HTTP 状态码与错误响应结构。
