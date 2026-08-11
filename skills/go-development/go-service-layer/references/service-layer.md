# Go Service Layer

Service 只负责业务编排、跨领域聚合、响应组合、日志与错误包装。禁止访问 DB、GORM、SQL；禁止导入 API/controller；禁止承担 Model/DAL 职责。通用 DI/nil/receiver/日志字段写法遵守 `$go-code-style`；字段生命周期定义遵守 `$go-model-hierarchy`。

## 结构与命名

- interface 必须 `XxxService`，实现 `XxxSrv`，构造 `NewXxxSrv(...) *XxxSrv`。同包已有其它命名/构造时可沿用，新建否则禁止偏离。
- 方法指针接收者必须为 `s`；禁止混用值接收者或其它 receiver 名。
- interface、struct、constructor、新增依赖与全部调用点必须同步修改。
- 公开方法按资源/动作命名：`SearchXxx`、`CreateXxx`、`UpdateXxx`、`DeleteXxx`。禁止 `SearchXxxForUser`、`UpdateXxxForProject` 等按调用方拆分的窄接口；约束写入 typed param 的 `Check()`。

## 依赖注入

长期依赖必须为 struct 字段并经 constructor 注入。禁止在业务方法内 `NewXxxDao`/`NewXxxSrv`/`NewClient`/`logger.New`。

字段与 constructor 参数顺序固定：

1. 主模型 DAL，再关联 DAL
1. 其它 service
1. cache / queue / lock
1. HTTP / RPC / 对象存储等 client
1. config / clock / ID generator / feature flag / 无状态 helper
1. logger

- 有 interface 必须依赖 interface；否则依赖同包既有具体类型。
- 参数名必须表达依赖含义（`policyDal`、`projectSrv`）。
- constructor 内仅允许 `logger.New(...)`；其余长期依赖必须注入。
- 请求级对象、param、结果容器、事务、timer 允许方法内创建。

## 签名

- 业务公开方法：`ctx` + 一个 typed param，返回 `error` 或 `(res, error)`。
- 无 `ctx`、不返回业务 `error`、且不编排 DAL/service/cache/client 的包内函数，不受上条约束。
- 分页 `SearchXxx` 允许 `(res, count, error)`。
- 调用 DAL 时允许 DAL 保持既有签名；禁止把 DAL 签名复制为新的 Service 公开签名，除非用户确认或既有 Service 契约已是该形状。

## 生命周期（按需）

不强制每个入口调用生命周期方法；无方法时禁止伪造。禁止在 Service 做 trim/默认值/归一化/派生字段/字段清洗。

| 方法 | 何时调用 | 禁止 |
| --- | --- | --- |
| `Serialize()` | 下游前需要消费规整字段（分支、状态机、组装写入/响应） | 纯转调仍调用 |
| `Check()` | 本方法要拒非法输入并继续编排 | 纯转调仍调用 |
| `Deserialize()` | 本方法持有尚未反序列化的存储形态 | DAL/service 已返回业务形态后仍调用 |
| `ToUpdater()` | 不在 Service 调用（DAL `Updates` 负责） | 手工 update map；改应由 Model 处理的持久化字段 |

- 调用 `Serialize` 必须 `obj = obj.Serialize()`。
- 字段名/类型非一一对应或需组合多字段时用转换方法；转换禁止再做序列化/归一化/派生。一一赋值可内联。

## 编排

- 持久化必须委托 DAL；更新先完成所需校验与业务判断再调 DAL。
- 跨多个 DAL 写且需原子提交时，由 Service 用已注入的 DB/事务入口开事务；禁止把跨资源事务藏进单个 DAL。
- 返回 slice/map 必须先 `make`，全路径返回非 nil 空集合；契约为可选指针且允许 nil 除外。
- 满足任一即拆私有 `addXxxData`（或同等业务名）：编排步骤 ≥5；跨 ≥2 个 DAL/service/client；含事务/异步入队/缓存刷新。禁止为单次转调、单字段赋值、单次 map 写入或单次错误包装拆 helper。
- 列表关联：收集 ID → 去重 → 批量查 → ID map → 回填。禁止在逐项循环内做可批量化的关联查询。
- 详情聚合返回部分结果仅当项目既有契约明确要求。

## 日志与错误

遵守 `$go-code-style` 的 `logging.md`。helper 禁止打 Error。同一 error 只允许一层打 Error：

| 失败来源 | 本 service |
| --- | --- |
| 直接 DAL/cache/client/外部依赖 | 必须打：英文操作名 + `.Err(err)` + 业务 ID；有 `LogStr()` 用其，否则只打 ID |
| 其它 service，无追加下游不知的上下文 | 禁止打；包装返回 |
| 其它 service，追加了跨域步骤/组合业务 ID/事务边界 | 打一次；包装返回 |

- 对外错误包装、语义转换、i18n 必须在 Service 完成；禁止留给 API `wrapXxxErr`；不得丢失原始 error。

## 示例

按需 `Serialize`/`Check`、构造注入、批量回填。`addXxxData` 见编排节规则，形状同私有方法只返回 `error`、由入口记日志。

```go
type XxxService interface {
	CreateXxx(ctx context.Context, param *model.CreateXxxParam) (*model.Xxx, error)
	SearchXxx(ctx context.Context, param *model.SearchXxxParam) ([]*model.XxxView, int64, error)
}

type XxxSrv struct {
	xxxDal     dal.XxxDal
	projectDal dal.ProjectDal
	log        *logger.Logger
}

func NewXxxSrv(xxxDal dal.XxxDal, projectDal dal.ProjectDal) *XxxSrv {
	return &XxxSrv{
		xxxDal:     xxxDal,
		projectDal: projectDal,
		log:        logger.New(logger.WithModule("service"), logger.WithSubModule("xxx")),
	}
}

// CreateXxx：本方法要消费规整字段，因此先 Serialize/Check；持久化仍交给 DAL。
func (s *XxxSrv) CreateXxx(ctx context.Context, param *model.CreateXxxParam) (*model.Xxx, error) {
	param = param.Serialize()
	if err := param.Check(); err != nil {
		return nil, err
	}

	data := &model.Xxx{
		ProjectID: param.ProjectID,
		Name:      param.Name,
	}
	if err := s.xxxDal.CreateXxx(ctx, data); err != nil {
		s.log.Error(ctx).Err(err).Int64("projectID", param.ProjectID).Str("param", param.LogStr()).Msg("createXxx failed")
		return nil, err
	}
	return data, nil
}

// SearchXxx：纯查询转调不在 Service 重复 Serialize/Check；关联数据批量回填。
func (s *XxxSrv) SearchXxx(ctx context.Context, param *model.SearchXxxParam) ([]*model.XxxView, int64, error) {
	result := make([]*model.XxxView, 0)
	rows, total, err := s.xxxDal.SearchXxx(ctx, param)
	if err != nil {
		s.log.Error(ctx).Err(err).Str("param", param.LogStr()).Msg("searchXxx failed")
		return result, 0, err
	}

	ids := make([]int64, 0, len(rows))
	seen := make(map[int64]struct{}, len(rows))
	for _, row := range rows {
		if _, ok := seen[row.ProjectID]; ok {
			continue
		}
		seen[row.ProjectID] = struct{}{}
		ids = append(ids, row.ProjectID)
	}

	projectMap := make(map[int64]*model.Project, len(ids))
	if len(ids) > 0 {
		projects, _, err := s.projectDal.SearchProject(ctx, &model.SearchProjectParam{IDs: ids})
		if err != nil {
			s.log.Error(ctx).Err(err).Str("param", param.LogStr()).Msg("searchXxx load projects failed")
			return result, 0, err
		}
		for _, p := range projects {
			projectMap[p.ID] = p
		}
	}

	for _, row := range rows {
		view := &model.XxxView{Xxx: row}
		if p := projectMap[row.ProjectID]; p != nil {
			view.ProjectName = p.Name
		}
		result = append(result, view)
	}
	return result, total, nil
}
```