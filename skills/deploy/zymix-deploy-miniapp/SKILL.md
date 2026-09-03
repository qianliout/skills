---
name: zymix-deploy-miniapp
description: 从零把一个小程序小游戏类（miniapp）新服务部署到 zymix 集群。当用户要求部署新的 miniapp 服务、新建 Jenkins 流水线 + K8s 清单、把某个 Go 服务跑到 test/prod 时使用。覆盖探查、拍板、生成清单、执行上线、验收复盘全过程。不用于变更已上线服务的配置，也不用于存量 ConfigMap 明文整改（那走 scripts/cm-secret-remediate/cms.sh）。IM 云服务类走 zymix-deploy-im。
---

# 部署一个新的 miniapp 服务

## 核心原则

你执行，用户决策。 用户不 copy 任何命令。所有 ssh / kubectl / psql / aws / jcli 都由你直接跑。
人的介入只有两种：① 提供你查不到的外部凭据；② 在阶段闸门上答一次 yes。

不要输出「请你在跳板机上执行以下命令」这种话。要么你去执行，要么说明为什么执行不了。

## 适用类别确认（不可跳过）

本 skill 只处理**小程序小游戏类（miniapp）**：

| 判据 | 本类取值 |
| --- | --- |
| 资源名前缀 | `zymix-<svc>` |
| kubeconfig | `miniapp_config` |
| 源码仓 | 独立仓（一服务一仓） |

三条判据有一条对不上（例如目标服务叫 `cloud-<svc>-svc`、走 monorepo `zymix-im-go-cloud`），
就是 IM 云服务，停下手上的流程，改用 `zymix-deploy-im` skill，不要在本 skill 里套用。

### 选环境

用 AskUserQuestion 明确问目标环境，不推断、不设默认值。

- miniapp 只有 `test`、`prod`（没有 stage）。

环境决定跳板机，选错就是打错集群（同名 kubeconfig 在两台跳板机指向不同集群）：

| 环境 | 跳板机 | namespace |
| --- | --- | --- |
| test | `ssh test-jenkins` | `zymix-dev`（注意：不叫 zymix-test） |
| prod | `ssh prod-jenkins` | `zymix-prod` |

约定顺序 test → prod，由用户把控，本 skill 不做自动前置检查。

## 敏感信息：写到本机，只是不进 git

规则是「不进 git」，不是「不落盘」。 真值文件必须在本机存在并保留：

| 类别 | 本机真值文件 | 挡住入库的规则 |
| --- | --- | --- |
| miniapp | `<env>/k8s/00-configmap.local.yaml` | `.gitignore: /*.local.yaml` |

- 权限 `chmod 600`，用完不删。重新 apply、与集群比对、排查配置，全靠它。
- 入库的是占位符版 `00-configmap.example.yaml`（敏感位 `REPLACE_ME_*`）。
  本类不生成裸的 `00-configmap.yaml`（那个名字留给 IM 类的占位符 CM）。
- 集群里已有 CM 而本机缺真值文件 → 从集群拉下来补齐，不要重新编一套值。
  拉的时候用管道直接落盘，值不要经过终端输出、不要进对话。
- 为什么不进 Secret：GoFrame `gcfg` 不做 `${VAR}` 展开，CM 里写占位符不会被替换。
  真值统一写在 CM、文件不入库（IM 类相反，见 zymix-deploy-im）。

## 不准动代码

本 skill 对服务源码只读。 一行都不改，不新增文件，不 commit，不建分支，不 push。

「代码」指被部署的那个服务的源码仓（miniapp 的各自独立仓）。
本 skill 的产出物是部署侧的东西——K8s 清单、Jenkinsfile、Secret、建库脚本、rollout 文档，
这些照常写。分界线是：跑在集群里的东西归你，被编译进镜像的东西不归你。

部署经常会撞上「改一行代码就通了」的场景。撞上就停，报给用户，不要顺手改：

| 撞上什么 | 你要做的 |
| --- | --- |
| 没有 Dockerfile / 自带的用不了 | 用 Jenkinsfile 内嵌 Dockerfile（P6），不改仓库 |
| 监听端口和预期对不上 | 改清单去适配代码；不改代码去适配清单 |
| 没有 `/healthz` | 不配探针（P11），不去加 handler |
| 配置路径 / 读取方式不对 | 改 CM 的挂载路径和启动参数；不改配置加载代码 |
| 没有自动 migrate | 手工灌 schema（P9），不去加 migrate |
| 编译失败、分支是空树（P5） | 停。 报清楚哪个包哪一行，交给用户 |

理由：改源码会改变服务行为，那是另一个人的评审范围，且部署窗口里没人 review。
一次「顺手修好」的编译错误，可能就是下一次生产事故。

例外只有一种：用户在本轮对话里明确说了改哪个文件。skill 自己永远不主动改。

## 五个阶段

### 1. Probe（只读，免批准）

自己查，查不到才问。清单见 [references/preflight.md](references/preflight.md)，逐项跑完并把结果记下来。

只读探查优先用 MCP（`mcp__rockcore-mcp-test__k8s_*` / `pg_*`、`mcp__zymix-devtool-remote__log_search_summary`），
MCP 覆盖不到的走 `ssh <跳板机>`。注意 miniapp 的 prod 集群目前不在 MCP 里，只能走 `ssh prod-jenkins`。

Probe 结束时必须能回答：源码怎么启动、听哪个端口、配置怎么读、有没有自动 migrate、
目标 namespace 现状、DB/Redis 从 Pod 内是否可达、ECR 仓库在不在、分支上有没有真实代码。

要不要建库先读 [references/db-topology.md](references/db-topology.md)：miniapp 一服务一库，要建。

#### ⛔ 闸门 0：依赖与敏感信息清单，逐项过给用户确认

Probe 的最后一件事：把这个服务要用什么摊开成三张表，请用户逐项确认。
用户没确认之前不进入 Decide。 模板见 [templates/inventory.md](templates/inventory.md)。

这一步存在的理由：DB 连错、Redis db 号撞车、少列一个密钥，都是要么当场 CrashLoop、
要么悄悄写脏别人数据的错误，而它们在 Probe 阶段全都是一句话就能问清的。
放到 apply 之后再发现，成本差两个数量级。

表一 · 敏感信息清单——一行一个 key，不许写「等等」「若干」：

| key | 用途 | 值从哪来 | 存哪 | 本机文件 |
| --- | --- | --- | --- | --- |
| `auth.jwtKey` | 签发 token | AI 生成 32 位随机 | ConfigMap | `test/k8s/00-configmap.local.yaml` |
| `tcsas.appSecret` | 第三方 | 需你提供 | ConfigMap | 同上 |

「值从哪来」只有三种，必须写明是哪种：复用现网（指明从哪个 CM 读）、
AI 生成（指明长度规则）、需用户提供（这类要在表里显式列出来问）。
prod 的外部凭据和 JWT 一律不得沿用 test 的值。

表二 · 数据库：实例 host、库名、schema、账号、是否新建库、表从哪来（自动 migrate / 手工灌 / 已存在）。
miniapp 一服务一库，正常填「是」。

表三 · Redis：地址、db 号、密码来源、以及「同 namespace 里还有谁在用这个 db 号」。
db 号撞车不会报错，只会互相覆盖 key。

三张表都要写进 rollout 文档，用户确认过的版本原样留档。

### 2. Decide（拍板 → 闸门 1）

产出 `<project>/doc/<env>-rollout.md`，四段：事实 / 需求与成功标准 / 已拍板 / 明确不做。
闸门 0 那三张表放进「事实」段，标注用户已确认。
格式复用 `grilling` skill 的输出（若可用则直接调用它；不可用则按同样四段自己写）。

⛔ 闸门 1：等用户说「可以开始」。在此之前不产生任何副作用。

### 3. Scaffold（本地生成，免批准）

按 [profiles/miniapp.md](profiles/miniapp.md) 的模板 + `params.yaml` 填充，写进 `<project>/<env>/`。
写完必须跑校验，有 FAIL 就不许进入阶段 4：

```bash
python3 <本 skill 目录>/validate.py --class miniapp --env <env> --dir <project>/<env>
```

`<本 skill 目录>` 是本 skill 文件所在的目录（拆分后为 `zymix-deploy-miniapp`）。

### 4. Execute（→ 闸门 2 / 闸门 3）

开始前，一次性列出本阶段将执行的全部动作（目标集群、namespace、库名、镜像仓、Job 名），请用户确认一次。

- ⛔ 闸门 2（test）：一次批准，然后你跑完整阶段。
- ⛔ 闸门 3（prod）：一次批准，但清单要逐项列出，且必须复述「跳板机 = prod-jenkins、namespace = zymix-prod」。

#### prod 的构建由用户手动执行

prod 环境可以改 Jenkins Job（灌流水线、建 Job），但绝不可以由你触发构建。
最后那一下由用户手动点。你要做的是把一切准备到位，然后停下来交接。

触发构建有两条路，两条都禁：

1. 直接触发 —— `jcli build prod-*`、Jenkins UI 上点 Build、任何等价调用。
2. 推分支间接触发 —— prod 的 Job 都挂了 `GenericTrigger` webhook，
   push 到匹配分支就等于点了 Build，而且没有二次确认：
   miniapp `prod-<svc>` 触发分支是 `prod`（与 test Job 共用 token，按 regexp 分流）。

   分支名以 Probe 时实际读到的 `regexpFilterExpression` 为准，不要背。
   源码分支的创建和推送，在 prod 一律交给用户做，你只说清楚要推哪个分支。

交接时给出：Job 名、要推的分支、预期镜像 tag 形态、构建后你会去验的东西。
用户点完构建再回来，你继续做 `rollout status` / 看日志 / 验收。

test 不受此限制，构建你自己跑。

执行顺序见 [profiles/miniapp.md](profiles/miniapp.md)。每一步做完立刻自检（profile 里给了判据），不要等到最后。

一条硬顺序：建库 / 灌 schema 在发镜像之前。 空库会让服务 CrashLoop，且日志长得像镜像或网络问题（P9）。
用 [templates/db/provision-db.sh](templates/db/provision-db.sh)，默认 dry-run，幂等，永不 DROP。
prod 的写操作要 `--apply --prod-confirm`，算在闸门 3 里。

### 5. Verify + Postmortem（不可省）

先自查没动过代码——`git -C <源码仓> status --porcelain` 必须为空，
`rev-parse --short HEAD` 与 Probe 时（B8）记下的一致（P19）。

跑完 [profiles/miniapp.md](profiles/miniapp.md) 的验收清单。然后把本次新踩的坑按五字段追加到
[references/pitfalls.md](references/pitfalls.md)：现象 / 原因 / 解法 / 预检命令 / 适用类。

没有新坑就写一行「本次无新增」。这一阶段不做，下一个服务会重踩。

## 本机目录缺口（TODO，后续补齐）

拆分时以下内容尚未整理，先在此留缺口，补齐前按保守默认执行：

- [ ] 本机部署仓/产出目录的绝对路径约定（`<project>/` 落在哪、rollout 文档与清单往哪写）未最终定稿。
      当前先落在本 skill 调用时约定的工作目录；确认路径后再回填本文档与 preflight.md 中的引用。
- [ ] miniapp 源码仓逐个补进 settings-snippet.json 的 deny 清单（参考原 zymix-deploy-service 的说明）。

## 绝不做

- 不改被部署服务的源码：不编辑、不新增文件、不 commit、不建分支、不 push（见上「不准动代码」）
- 不改任何已上线服务的 Deployment / ConfigMap / Secret / Job
- 不把 test 的密钥、token、DSN 拷进 prod
- 不删本机的真值文件（`*.local.yaml`）。规则是「不进 git」不是「不落盘」；
  删了就没法重新 apply、没法与集群比对。靠 `.gitignore` + `chmod 600` 兜，不靠删除
- 不手改 `deployment/`、`jenkins-piplines/` 里的快照当作变更手段（改了不影响线上）
- 不在 test-jenkins 上执行 prod 操作，反之亦然
- 不用 `:latest` 作为 Deployment 的镜像 tag
- 不触发任何 prod 构建：既不 `jcli build prod-*`，也不 push 会命中 prod webhook 的分支。改 Job 可以，按 Build 不行
- 建库永不 `DROP`、永不复用别人的库名
- 不给没有真实 `/healthz` 的服务配 `/healthz` 探针
