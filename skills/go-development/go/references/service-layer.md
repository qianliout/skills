# Go Service Layer

Service 层负责业务编排、参数校验入口、模型转换、结果聚合、日志和错误包装；不直接访问 DB/GORM/SQL，不把 DAL 或 model 的职责搬进 service。

## Workflow

1. 确认 service 边界：公开方法、param/response、依赖 DAL/service/cache/client/logger、错误语义和方法类型。
2. 加载 `references/service-layer-conventions.md`；同时遵循当前任务触发的 `references/code-style.md`、`references/model-hierarchy.md`、`references/query-dal.md`、`references/logging.md`。
3. 定义 interface/struct/constructor：项目使用 interface 时同步更新；依赖按 DAL、其他 service、cache/infra、client、config/helper、logger 顺序声明和注入。
4. 实现公开方法：签名固定 `ctx + param`（工具函数除外），返回值 `error` 或 `res + error`（见 code-style `Function Parameters`）；方法名保持资源/动作级别，不按调用场景拆窄接口。已有多参数/多返回值方法默认保留。
5. 处理 param：带领域方法的 param 使用指针类型；入口按 `param = param.Serialize()`、`param.Check()` 执行。
6. 编排依赖：调用 DAL/service/cache/client；slice/map 返回值先实例化；错误按项目约定记录和包装。
7. 控制 helper 粒度：复杂详情或跨资源聚合可按数据域拆 helper；不要把一两行转调拆成薄 helper 链。

## Reference Loading

生成、重构或评审 service 层代码时，必须加载 `references/service-layer-conventions.md`。

## Pre-Delivery Checklist

- [ ] Service interface/struct/constructor 同步且依赖顺序清晰；业务方法内没有临时创建长期依赖。
- [ ] 没有用 nil 注入依赖跳过业务、校验、写入或日志。
- [ ] 实现方法使用指针接收者，receiver 统一为 `s`；业务方法入参为 `ctx + param`、返回值 `error` 或 `res + error`；未无故改写已有多参数/多返回值签名。
- [ ] 公开接口保持资源/动作级别，没有 `SearchXxxForUser`、`UpdateXxxForProject` 等场景化窄接口。
- [ ] Param 按需要执行 `Serialize()` / `Check()`；service 不重复清洗、校验或派生字段。
- [ ] Service 不直接访问 DB/GORM/SQL，不临时定义应归属 model 的 param/response/model struct。
- [ ] 列表/聚合返回值已初始化为空集合；复杂聚合无循环逐条查询。
