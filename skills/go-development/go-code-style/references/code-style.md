# Go 通用代码风格硬约束

注释 → `comment-style.md`；日志 → `logging.md`；生命周期方法 → `go-model-hierarchy`；业务错误包装 → `go-service-layer`；handler 错误返回 → `go-api-layer`。禁止在本文件复述专文。冲突：层 Skill > 专文 > 本文件。必须保持业务行为与层职责不变。

## 控制流

- 非法输入、空值、权限失败、错误必须 early return；成功主流程左对齐。
- 禁止 `else if`；单值多状态必须 `switch`。
- 禁止嵌套复合分支：`if`/`for`/`switch` 的 body 内禁止再出现三者。`switch` case 内只允许 early return，或一层且无嵌套的 `if`。
- 禁止 `else`。仅当两分支合流后共用 ≥3 行、且只读分支前局部变量时允许；否则 early return，或抽具名函数两侧调用。
- ≥2 处 `&&`/`||` 或含函数调用的布尔条件必须先赋具名变量。布尔 helper 仅本包 ≥2 处复用，或名称已在 typed param/领域模型中时允许。

## 函数与签名

- 业务函数：含 `ctx` 或 API/Service/DAL 导出方法。工具函数：无 `ctx`、无持久化/RPC/缓存副作用。其余新增签名必须先经用户确认。
- 新增业务方法必须 `(ctx, param *T)`（`ctx` 首位），返回只能 `error` 或 `(result, error)`；禁止多位置业务参数。工具函数普通参数；返回值 ≤3（含 `error`）；receiver 不计入参数个数。
- 免确认：框架/接口强制、生成适配器、构造/装配、既有分层标准（含 DAL `Create/Update/Delete/SearchXxx` 既有形态）。既有多参/多返回必须保留，除非用户要求重构。
- 同一函数禁止既做跨依赖编排又做字段赋值/拼接/容器操作。
- 禁止薄包装：只转发；体 ≤3 句且只赋值/判空/转换；只藏单条件；单调用点且无稳定业务动词、不隔离副作用。禁止 `processData`/`handleResult`/`buildInfo`/`prepareData`/`doCreate`/`checkData` 及无决策 helper 链。抽 helper 必须满足其一：本包 ≥2 复用；隔离副作用；≥2 层分支或跨领域聚合；稳定业务动词。本地短操作内联或具名变量；既有薄包装只保留兼容。
- 有归属行为必须用所属 struct 指针方法；禁止无主包级业务函数。无归属纯工具必须放既有 `utils`。

## 返回与实参

- `(value, error)` 必须先处理 `err` 再返回 value。
- 业务/I/O/层调用、≥2 步构造转换、链式调用、错误包装必须先赋局部变量再返回。允许直接返回：字面量、常量、字段、`nil`/`err`/布尔/简单零值、`fmt.Errorf`/`errors.New`、稳定适配器值。
- 实参只允许变量/常量/字面量/简单字段或索引。返回 `error` 或多返回值的调用禁止直接作实参。`len`/`cap`/`append` 与字段/索引允许直接作实参。

## 防御与依赖

- 防御检查只允许：请求/外部边界、真实 panic 风险、契约接受 nil/零值/`(nil, nil)`、允许 nil receiver 的生命周期方法、goroutine 恢复/清理。必须紧邻不确定性边界；验证/构造后禁止重复检查。
- 禁止：复查已 `Check()`/边界通过字段；检查本函数刚 `make`/字面量/保证可用构造；`err == nil` 仍判空（契约允许 `(nil, nil)` 除外）；空 slice/map 改 nil；为空结果加多余分支；不可能状态静默降级。
- 长期依赖必须构造/启动注入且非 nil；字段、构造参数、启动点同步更新且顺序一致：持久化 → 跨领域服务 → 基础设施/缓存/Client → 配置或小 helper → Logger。
- 字段只放长期协作者；请求级对象只在方法内创建。禁止方法内临时 `New` Service/DAL/Client/Cache/Logger。禁止依赖 nil 时跳过验证/写入/缓存/日志或假成功。

## 命名与声明

- 全部指针 receiver；同 struct 禁止混用；名称：Service `s`，DAL `dal`，API `api`，含 `Param` 用 `p`，其他 Model 用 `vi`。
- 标识符必须表达业务职责。公共方法禁止编码调用方/租户/场景；差异进 typed param。副作用或写入字段集合不同且 param 表达不了时，必须独立业务动词。
- 禁止 `data`/`tmp`/`obj`。`res`/`ans`/`input`/`output`/`cnt` 仅循环体或闭包。禁止冗余 `Is`、局部名 >40 字符、与函数/receiver/type/package 重名，以及 `max`/`min`/`len`/`cap`/`error`/`slices`/`maps`/`strings`。
- `ID`/`URL`/`HTTP`/`JSON` 同库大小写一致。默认 `:=`；仅 nil 指针/接口、跨分支累积零值、扩作用域零值用 `var`。

## 类型与数据

- 输入输出必须具体类型。匿名结构本包 ≥2 次或跨函数传递必须具名 struct。
- 禁止普通业务字段具名基础类型包装。必须具名当且仅当：外部协议、该类型需方法、或不可用 struct 的强类型边界。
- `err == nil` 的 slice/map 必须非 nil；`err != nil` 允许 nil。
- 业务与层间数值必须 `int64`。例外：语言/标准库 `int`、外部协议、第三方签名、字节、已证明性能/存储、兼容约束。禁止因范围小用 `int`/`int32`/`uint`/`uint64`。
- 禁止业务数据 `any`/`interface{}`/`map[string]any`（`ToUpdater`、service 组装给 DAL 的 DB 列 updater、泛型 helper、原始 JSON、日志字段、第三方边界除外）；入域立即强类型。updater map 只能作为「列名 → 值」直接传给 DAL，禁止当业务对象在层间传递、缓存或返回给 API。
- 禁止新增 ≤3 方法且单动词接口，除非调用方按不同实现切换。常量必须进项目 `consts`；禁止在层代码或函数体定义。重复魔法值必须具名常量。
- 新表/新功能时间必须毫秒 `int64` + `time.Now().UTC().UnixMilli()`；禁止擅自改既有单位。JSON tag 禁止 `omitempty`。禁止 `Normalize()`/`FillDefault()` 替代 `Serialize()`。

## 文件、并发、错误、门禁

- 按类型组/职责/路由组/方法族拆文件；禁止无关混装与纯行数切碎。非 Model 公共 struct → 项目 `structs`；Model 语义留 Model。单行 >120 列必须换行。
- I/O/DB/Cache/RPC/Queue/长任务必须传上游 `ctx`；禁止请求/任务流改用 `context.Background()`。仅 timeout/cancel 可建 child 且必须 `cancel`。
- goroutine 必须有：ctx 取消、有上限工作量、或同寿停机信号；必须 `recover` 并记录 panic/stack。共享状态用项目既有同步。
- 错误立即返回；有恢复则恢复后继续；禁止吞错。忽略的次要错误必须打日志或英文注释原因。包装错误用 `errors.Is`/`errors.As`。错误上下文必须含可定位业务 ID/主键；禁止敏感值。
- import 必须分组。改文件后必须 `goimports`；必须最小范围 `go test`，行为/共享变更扩范围；不能测必须报告原因。
