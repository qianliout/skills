# Go Service Layer

Service 只负责业务编排、跨领域聚合、响应组合、日志与错误包装。持久化必须经 DAL/repository；Service 禁止访问 DB、GORM、SQL，禁止导入 API/controller 包，禁止承载 Model 或 DAL 的职责。

## 职责与结构

- 项目定义 service interface 时，必须定义 `XxxService`；实现必须使用 `XxxSrv` 或项目既有命名。
- 每个 service 必须提供 `NewXxxSrv(...) *XxxSrv` 或项目既有构造入口。
- 实现方法必须使用指针接收者 `s`。同一 service 禁止混用值接收者、`srv`、`service` 等 receiver。
- interface、struct、constructor、新增依赖及全部调用点必须同步修改。
- Service 公开接口必须按资源/动作命名，如 `SearchXxx`、`CreateXxx`、`UpdateXxx`、`DeleteXxx`。
- 禁止按调用方、租户、项目、所有者或权限拆出 `SearchXxxForUser`、`UpdateXxxForProject` 等窄接口；约束必须放入 typed param/command 并由 `Check()` 校验。

## 依赖注入

Service 的长期依赖必须声明为 struct 字段，经 constructor 显式注入。禁止在公有或私有业务方法内调用 `NewXxxDao`、`NewXxxSrv`、`NewClient`、`logger.New` 或同类工厂。

字段与 constructor 参数必须保持同一顺序：

1. 主模型 DAL/repository，再关联模型 DAL/repository。
1. 跨领域编排所需的其他 service。
1. cache、queue、lock 等基础设施。
1. HTTP、RPC、对象存储等外部 client/gateway。
1. config、clock、ID generator、feature flag、无状态 helper。
1. logger 或 log event。

- 项目存在 service/DAL interface 时必须依赖 interface；否则必须遵循项目既有构造约定。
- constructor 参数必须使用表达依赖含义的名称，如 `policyDal`、`projectSrv`、`cache`。
- constructor 仅能初始化不隐藏外部依赖的轻量自有 helper、logger 或 cache；项目要求时必须在构造或 bootstrap 阶段校验依赖。
- 禁止在每个业务方法重复检查 `s == nil` 或长期依赖是否为 nil。
- 禁止用 `if s.cache != nil`、`if s.primaryDal == nil`、`if s.log != nil` 等分支静默跳过缓存、持久化、日志或业务。必须修复 constructor、bootstrap 或测试装配。
- 请求级对象、param、结果容器、事务、timer 和短生命周期数据允许在方法内创建。
- Service 只能依赖 DAL/repository interface、其他 service interface、基础设施、外部 client、config/helper 与 logger。

## 方法签名与参数

- 业务公开方法必须使用 `ctx context.Context` 加一个 typed param；工具函数除外。
- 业务公开方法必须返回 `error` 或 `(res, error)`。
- 已存在的多参数或多返回值导出方法必须原样保留，除非用户确认改形或分层规则明确规定例外。
- 分页 `SearchXxx` 的既有 `(res, count, error)` 返回是允许例外；DAL 的 `UpdateXxx(ctx, id, data)` 与 `SearchXxx(ctx, param)` 三值形式也是允许例外。
- 带 `Serialize()`、`Check()` 等领域方法的 param 必须使用指针类型。
- 公有 service 边界必须先执行 `param = param.Serialize()`，再执行 `param.Check()`；无对应方法时不得伪造调用。
- Service 必须调用 Model/Param 所有者提供的 `Serialize()`、`Deserialize()`、`Check()`、`ToUpdater()` 或纯转换方法；禁止在 Service 重复 trim、默认值、归一化、派生字段、lowercase 或字段清洗。
- API 与 DAL DTO 不同且映射非平凡时，必须使用转换方法；转换方法禁止重复序列化、反序列化、归一化或派生字段职责。

## 编排与聚合

- Service 必须经 DAL/service/cache/client 编排业务；持久化必须委托 DAL。
- 更新必须先校验操作 param，再委托 DAL；禁止在 Service 手工构造 update map，禁止修改应由 Model `Serialize()` 或 `ToUpdater()` 处理的持久化字段。
- 返回值含 slice 或 map 时，必须在校验前初始化，并在全部返回路径返回初始化后的空集合；契约明确声明为可选指针字段时除外。
- 详情聚合跨越多个数据域时，必须按数据域或副作用拆分私有 `addXxxData` helper。
- 禁止把单次转调、单字段赋值、单个 map 写入或单次错误包装拆成 helper，禁止 helper 链只互相转调。
- 主流程必须保持同一抽象层的有序业务步骤；复杂阶段必须按真实业务概念、数据域、外部调用、事务、异步入队或缓存刷新拆分。
- 列表关联数据必须收集 ID、去重、按关联 DAL 批量查询、构建 ID map、再回填响应。禁止在逐项循环内执行可批量化的关联 DAL 查询。
- 仅当项目既有契约明确要求时，详情聚合错误才能返回部分结果与聚合错误。

## 日志与错误包装

- 日志所有权必须遵守 `$go-code-style` 的 `logging.md`：仅拥有最完整业务上下文的层必须记录错误日志。
- 公有方法输入需要记录时，必须使用安全的 `LogStr()` 摘要，禁止直接记录完整敏感 struct。
- 私有 helper 默认只返回错误，禁止在 helper 内记录已由上层或下游记录的同一 error；上层必须附带当前操作名、业务 ID 与可用 param 摘要记录。
- 当前 service 作为编排入口且拥有最完整业务上下文时，必须记录 DAL、cache、client 或外部调用失败；日志必须包含稳定英文操作名、原始 error、关键业务 ID 与可用 param 摘要。
- 调用其他 service 时，若下游 service 已按 `logging.md` 记录完整业务上下文，当前 service 禁止再次记录同一 error；必须包装并向上返回。
- 调用其他 service 时，若当前 service 追加了下层无法感知的业务上下文（如跨域聚合步骤、组合 param、事务边界），必须由当前 service 记录一次，禁止与下游重复打印同一 error。
- 禁止在每一层嵌套 service 都对同一失败重复打 Error 日志。
- 存在项目错误 wrapper 时，必须将底层错误包装为 user/API/service 层错误；禁止把原始低层错误文本直接暴露给调用方。
- 对外可见的错误包装、语义转换与 i18n 必须在 Service 完成；禁止留给 API/handler 再做 `wrapXxxErr`。
- 错误包装不得丢失可供上层或日志使用的原始 error。

## 与 DAL、Model 的边界

- Model 负责类型、`Serialize`、`Deserialize`、`ToUpdater`、`Check`、`Same` 与不重复序列化职责的纯跨类型转换。
- DAL 负责持久化、超时、SQL/GORM、`AddFilter`、CRUD 与 search。
- Service 负责编排、跨 DAL 聚合、响应组合、日志与错误包装。
- 包级 helper 只能承载没有明确所属 struct 的通用领域无关逻辑。

## 测试门禁

- 修改 Go 文件后必须运行 `goimport`。
- 可定位包或测试时必须运行最小范围 `go test`。
- 测试装配必须注入完整长期依赖；禁止以 nil 依赖绕过行为。
