# 坑库（miniapp）

> 本文件为 miniapp 侧坑库，含从原 zymix-deploy-service 合并来的两类坑。
> 标注「适用：IM」的条目（P12/P16/P17/P20 等）属于 IM 流水线/共享库语境，
> 在 zymix-deploy-im 中生效，miniapp 侧仅作参考，不要在本 skill 的部署里套用。

每条五字段：现象 / 原因 / 解法 / 预检命令 / 适用。
「预检命令」是这条坑的可执行形式——Probe 阶段照 [preflight.md](preflight.md) 跑一遍，就不会再踩。

阶段 5 复盘时往这里追加新条目，格式照抄。占位符按实际值替换后执行。

---

## P1 跳板机选错，连到同名 kubeconfig 的另一个集群

- 现象：`-n zymix-prod` 得到 NotFound，或内网 IP 全超时，或"看起来没部署过"。
- 原因：`miniapp_config` 在 `test-jenkins` 与 `prod-jenkins` 上是两个不同集群，文件名相同。
- 解法：test/stage → `test-jenkins`；prod → `prod-jenkins`。固定死，不凭记忆。
- 预检：`ssh <跳板机> "kubectl --kubeconfig=<路径> get ns | grep -E 'zymix-(dev|test|stage|prod)'"` —— namespace 集合对不上预期就是选错了机器。
- 适用：两类，prod 尤甚。

## P2 数据库密码只在容器内验证过，走 TCP 就失败

- 现象：`docker exec ... psql` 能连，应用连不上。
- 原因：容器内本机 socket 可能走 `trust`，测不出密码对不对；且笔记里的密码常有笔误。
- 解法：以主机映射端口的 TCP 认证为准；密码从 `docker inspect` 的 `POSTGRES_PASSWORD` 读，不信文档。
- 预检：`ssh <host> "sudo docker inspect <container> --format '{{range .Config.Env}}{{println .}}{{end}}' | grep PASSWORD"`，再 `PGPASSWORD=<值> psql -h 127.0.0.1 -p <映射端口> -U <user> -d postgres -c 'select 1'`
- 适用：两类。

## P3 集群到数据库必须走内网地址

- 现象：Pod 连 DB 超时，但你在跳板机上连得通（或反过来）。
- 原因：公网映射通常不对集群开放；跳板机与集群节点在不同网段。
- 解法：CM 里写内网地址；公网地址只用于跳板机上的管理操作（建库、灌 schema）。两套地址写进同一份文档时必须标清用途。
- 预检：`kubectl run -n <ns> --rm -it netcheck --image=busybox --restart=Never -- nc -zv <内网IP> <端口>`
- 适用：两类。

## P4 密码里的 `#` 被 YAML 当成注释

- 现象：认证失败，日志里的密码比你配的短。
- 原因：`pass: pass#102` 解析成 `pass: pass`。
- 解法：含 `#` `:` 空格 的值一律加双引号。
- 预检：apply 之后 `kubectl get cm <name> -n <ns> -o yaml`，核对挂进去的原文，不要只看本地清单文件。
- 适用：两类（miniapp 尤其，因为值直接写在 CM 里）。

## P5 听错分支，编出空树

- 现象：镜像能编出来但功能全无，或编译直接失败。
- 原因：`master` / `test` 分支常停在 Initial commit，真实代码在 `dev`。
- 解法：设 Job 默认分支和 webhook regexp 前，先确认该分支有真实提交。
- 预检：`git ls-remote <git-url> refs/heads/<branch>` 对比 `refs/heads/dev` 的 sha；相同或指向 Initial commit 就是空树。
- 适用：miniapp（一服务一仓时高发）。

## P6 项目自带的 Dockerfile 用不了

- 现象：`docker build` 找不到 `temp/linux_amd64/main` 之类的产物。
- 原因：仓库 Dockerfile 假设用 `gf build` 产物，与 Jenkins 节点的 host `go build` 对不上。
- 解法：miniapp 用 Jenkinsfile 内嵌 alpine Dockerfile 只 COPY 二进制；IM 用流水线里已有的 `generateDockerfile()`。
- 预检：`ls <src>/manifest/docker/Dockerfile` 存在就默认不用它，另确认后台 UI 是否 embed（embed 了就别 `COPY resource/`）。
- 适用：两类。

## P7 ECR 仓库不存在，push 直接失败

- 现象：`docker push` 报 repository does not exist。
- 原因：仓库要预先创建，且 test 与 prod 的 region / 镜像 namespace 常常不同。
- 解法：`aws ecr create-repository --repository-name <repo> --region <region> --image-tag-mutability MUTABLE`
- 预检：`ssh <跳板机> "aws ecr describe-repositories --region <region> --repository-names <repo>"`
- 适用：两类。IM：test `siu/` vs prod `zymix/`；miniapp：region 需实测。

## P8 占位 `:latest` + RollingUpdate 让 rollout 卡死

- 现象：新 RS 起来了，旧 RS 不退，`rollout status` 超时。
- 原因：1 副本时 `maxUnavailable: 25%` 向下取整成 0，旧 Pod 不允许被删；而旧 Pod 卡在 `ImagePullBackOff` 永远不会 Ready。
- 解法：清单直接写首张真实 tag；miniapp 用 `Recreate`；已经卡住就删掉旧 RS。
- 预检：apply 前 `grep -n ':latest' <清单>` 必须无命中。
- 适用：两类（miniapp 用 Recreate 后基本免疫，IM 保持 RollingUpdate 需靠真实 tag）。

## P9 空库导致进程启动即 fatal，看起来像镜像坏了

- 现象：日志显示 Redis 连接成功，几毫秒后 `relation "xxx" does not exist`，Pod CrashLoopBackOff。
- 原因：应用启动时要读某张配置表；只建了库没建表。不是镜像、不是网络、不是密码的问题。
- 解法：先灌 schema 再发镜像。已经 CrashLoop 的，灌完表 `rollout restart` 即可，不要回滚镜像、不要改 DSN。
- 预检：Probe 的 B3 先确认服务有没有自动 migrate；没有就必须连 schema 一起灌。
  `provision-db.sh` 收尾会数 `public` 下的表，0 张会告警——别忽略那行告警。
- 适用：两类。

## P10 流水线不创建 K8s 资源

- 现象：Job 在 `set image` 一步失败，报 deployment not found。
- 原因：流水线只做 `set image`。
- 解法：先 apply 清单，再跑 Job。IM 尤其危险——`set image` 失败会让整条 monorepo 流水线红，连带影响其它服务发布。
- 预检：`kubectl get deploy <name> -n <ns>` 存在。
- 适用：两类。

## P11 没有真正的 `/healthz`

- 现象：探针一直失败，但进程其实在跑（或反过来，探针通过但服务是坏的）。
- 原因：有些服务未匹配路由会被改写成 200，探活等于没探。
- 解法：确认有真 healthz handler 才配探针；没有就不配。CrashLoop 时看容器日志，不看探针。
- 预检：`grep -rn 'healthz\|/health' <src> --include=*.go` 找到真实 handler 再说。
- 适用：两类（IM 按惯例统一不配）。

## P12 IM：容器名不带 `cloud-` 前缀

- 现象：`set image` 报 `unable to find container named cloud-xxx-svc`。
- 原因：Deployment 名是 `cloud-<svc>-svc`，容器名是 `<svc>-svc`。
- 解法：`set image deployment/cloud-<svc>-svc <svc>-svc=<image>`。
- 预检：`kubectl get deploy cloud-<svc>-svc -n <ns> -o jsonpath='{.spec.template.spec.containers[*].name}'`
- 适用：IM。

## P13 miniapp：真值 ConfigMap 误入库

- 现象：`git status` 里出现含明文密码的 ConfigMap。
- 原因：本类敏感信息按规定写在 CM 里，靠 gitignore 兜底。两个陷阱：① 真值文件名没用 `.local.yaml` 后缀，规则盖不住；② 文件一旦被 git 跟踪，gitignore 就完全失效，而 `git check-ignore` 对已跟踪文件默认静默，会让你误以为规则生效了。
- 解法：真值文件一律命名 `*.local.yaml`；入库的是 `*.example.yaml`。已经被跟踪的要先 `git rm --cached` 才能真正生效（存量服务如 rent-rewards / ticket-tailor 的明文 CM 已在 git 历史里，本流程不迁移它们）。
- 预检：`git check-ignore -v --no-index <project>/<env>/k8s/00-configmap.local.yaml` 必须有输出（`--no-index` 不能省）；再 `git status --short | grep -i configmap` 必须无命中。
- 适用：miniapp。

## P14 目标 namespace 里缺 `zymix-io-tls` / `aws-ecr`

- 现象：Ingress 的 TLS 不生效，或 Pod 一直 `ImagePullBackOff`。
- 原因：这两份 Secret 是 namespace 级的，不是集群级。miniapp 的 `zymix-stage` 就只有 `aws-ecr`，没有 `zymix-io-tls`。
- 解法：apply Ingress 前先确认 TLS Secret 在；不在就先补。
- 预检：`kubectl get secret -n <ns> aws-ecr zymix-io-tls`
- 适用：两类。

## P15 资源名与已有服务撞车

- 现象：apply 之后别人的服务被改掉了。
- 原因：`apply` 对已存在的同名资源是覆盖语义。
- 解法：apply 前逐个资源确认不存在。
- 预检：`kubectl get deploy,svc,cm,ingress -n <ns> | grep -w <resource-name>` 必须无命中。
- 适用：两类。这是本流程里最容易造成他人事故的一条。

## P16 推 monorepo 流水线，静默删掉别人的服务（IM 专属，见 zymix-deploy-im）

- 现象：推完流水线，别人的服务从构建里消失；或者别人昨天加的行不见了。没有任何报错，Job 照常绿。
- 原因：`push-pipeline.sh` 是整体覆盖语义（拿本地 Jenkinsfile 注入 config.xml 后 `update-job`），不是打补丁。本地快照落后多少，就抹掉多少。`jenkins-piplines/` 是只读快照，天然会落后。
- 解法：改 `cloud-im-go-server` 前先**全量拉线上 Jenkinsfile** 并以其为基线，绝不基于本地旧快照推（pipeline-sync-guard 已按用户决策移除）。详见 zymix-deploy-im 的 profile。
- 预检：push 前 `jcli get-job <env>/cloud-im-go-server` → extract-script 抽 Jenkinsfile 与工作副本 diff，只应有本次新增行。
- 适用：IM。这是影响面最大的一条——一条流水线带全部 IM 服务。

## P17 给 IM 新服务建了一个没人连的新库

- 现象：建了 `db_<svc>`，服务却连不上，或者连上了但和其它服务的数据对不上。
- 原因：IM 一个环境只有一个共享库（`db_zymix_test` / `db_zymix_stage` / `db_zymix_prod`），全部 `cloud-*-svc` 共用 `public` schema。新服务要的是表，不是库。
- 解法：DSN 从同环境任一 `cloud-*-svc` 的 Secret 里读现成的，原样写进新服务的 Secret；DDL 建表打在共享库上。确实要独立库，才用 `provision-db.sh --allow-new-database` 并在 rollout 文档写明理由。
- 预检：`kubectl -n zymix-<env> get secret cloud-user-svc-secret -o jsonpath='{.data.USER_SVC_DATABASE_DSN}' | base64 -d`，确认 host/dbname 与你打算用的一致。
- 适用：IM。详见 [db-topology.md](db-topology.md)。

## P18 prod 构建被间接触发：以为没点 Build，push 一下就上线了

- 现象：没有点过 Build，prod 却开始构建并 `set image`，新镜像直接进了生产。
- 原因：prod 的 Job 都挂了 `GenericTrigger` webhook，push 到匹配分支 = 点 Build，没有二次确认。`prod-cloud-im-go-server` 匹配 `master`（一推带全部 IM 服务）；miniapp 的 `prod-<svc>` 匹配 `prod` 分支，且与 test Job 共用 webhook token，靠 `regexpFilterExpression` 分流。
- 解法：prod 的构建一律由用户手动执行。 AI 可以改 Job / 推流水线，但不 `jcli build prod-*`，也不 push 会命中 prod webhook 的分支——源码分支的创建和推送在 prod 归用户。准备完就停下来交接：Job 名、要推的分支、预期 tag 形态、构建后要验什么。
- 预检：`jcli get-job <prod-job> | grep -A6 GenericTrigger` 读出真实的 `regexpFilterExpression`，确认哪个分支是触发分支（别背文档里的表）。
- 适用：两类，仅 prod。

## P19 部署卡住时顺手改了源码

- 现象：部署过程中为了让镜像编出来 / Pod 起来，改了服务仓库里的一行代码（补 Dockerfile、改端口、加 healthz handler、修编译错误、动 `go.mod`）。当时确实通了。
- 原因：部署窗口里改代码没人 review，改动跟着镜像进生产。而且它会掩盖真问题——本该报给用户的编译错误变成了「已解决」。
- 解法：本流程对服务源码只读。 撞上要改代码才能过的坎，一律停下报给用户。绕得过去的用部署侧手段绕：Dockerfile 用 Jenkinsfile 内嵌或 `generateDockerfile()`（P6）；端口不匹配改清单不改代码；没 healthz 就不配探针（P11）；没 migrate 就手工灌 schema（P9）。绕不过去就停。
- 预检：交付前 `git -C <源码仓> status --porcelain` 必须为空；`git -C <源码仓> log --oneline -1` 与 Probe 时记录的 sha 一致。
- 适用：两类。产出物只能落在部署仓（清单 / Jenkinsfile / Secret / 建库脚本 / rollout 文档）。

## P20 selective 流水线「不勾就是全量」：加一个还没进目标分支的服务 = 埋雷

- 现象：往 `cloud-im-go-server-selective` 的 `ALL_SERVICES` 加了一个新服务并推上线。此后别人用默认参数跑这条 Job 就构建失败，红的是承载全部 IM 服务的流水线，而报错指向一个跟他无关的服务。
- 原因：`resolveSelectedServices()` 里 `if (!raw) return allServices`——一个复选框都不勾（以及 webhook 触发）就是全量构建 `ALL_SERVICES`。新服务只要在这个列表里，就会在目标分支上被无条件 `go build ./app/<svc>/cmd/<svc>`；而新服务的代码常常还只在 `integration` 之类的特性分支上，目标分支（test 的 `test`、stage 的 `stage`）根本没有这个目录。复选框 `<value>` 加不加都不影响这一点，引信在 `ALL_SERVICES`。
- 解法：先确认 `git ls-tree --name-only origin/<目标分支> app/ | grep <svc>` 有命中，再往 `ALL_SERVICES` 加。代码还没合进目标分支时有三条路：① 等合并；② 只写本地不推 Jenkins，改动在仓里备着；③ 往 Build 阶段加一道通用守卫 `selected = selected.findAll { fileExists("app/${it.name}/cmd/${it.name}") }`（改的是共享逻辑，方向收敛，需用户批准）。选哪条要用户拍板，别自己定。
- 预检：`git ls-tree --name-only origin/<目标分支> app/ | grep -w <svc>-svc`；无命中就是有雷。另外 `grep -n 'if (!raw)' <Jenkinsfile>` 确认默认语义仍是「全量」。
- 适用：IM。`test/cloud-im-go-server-selective` 现存此雷（`event-svc` 在列表里，`origin/test` 无 `app/event-svc`），本次未修，属另一环境范围。

## P21 stage 的 ECR 是 eu-west-2 + zymix/，跟 prod 一样，不是 test 那套

- 现象：照 test 的镜像地址推 stage，`ap-east-1` / `siu/` 一路建仓库、改流水线，最后 Pod 拉不到镜像；或反过来在错误的 region 建了个没人用的空仓库。
- 原因：profile 的环境矩阵里 stage 那两格写的是「见现网 Job」。实测 `stage-cloud-im-go-server` 的 `ECR_REGISTRY` 是 `483898562971.dkr.ecr.eu-west-2.amazonaws.com`、镜像 namespace 是 `zymix/`——与 prod 相同，与 test 不同。
- 解法：stage = `eu-west-2` + `zymix/<svc>`。建仓库时对齐存量配置：`--image-tag-mutability MUTABLE`、AES256、`scanOnPush: false`。
- 预检：`grep -E "ECR_REGISTRY|AWS_DEFAULT_REGION|/zymix/|/siu/" jenkins-piplines/<env>/cloud-im-go-server/Jenkinsfile`，以现网 Job 为准，别背表。
- 适用：IM。

## P22 stage 的 imagePullSecrets 全是死引用，照抄只会多刷告警

- 现象：新服务照老邻居写 `imagePullSecrets: [tcr-secret, ecr-secret-apeast1]`，Pod 起来就刷 `FailedToRetrieveImagePullSecret`。
- 原因：`zymix-stage` 里这两个 Secret 都不存在。存量 20+ 个服务的清单里还挂着历史引用，每个 Pod 都在刷这条 Warning。同账号 ECR 靠 node IAM 就能拉，所以没人发现。最近 30 天内 onboard 的 task-svc / vote-svc / points-svc 都不写 `imagePullSecrets`。
- 解法：stage 的新 IM 服务不写 `imagePullSecrets`。验证方式：拉取失败时看错误码，`code = NotFound`（tag 不存在）说明认证是通的；`401/403` 才是真的缺凭据。
- 预检：`kubectl -n zymix-<env> get secret tcr-secret ecr-secret-apeast1` —— 不存在就不要写进清单。
- 适用：IM（stage 已实测；prod 未验，照此法先查再写）。

## P23 validate.py 的 NS 检查是字面比较，CM 里带引号的 namespace 会被误判

- 现象：`FAIL NS ... namespace 是 "zymix-stage"，stage 环境应为 zymix-stage` —— 值明明是对的。
- 原因：`check_env_consistency` 用 `re.match(r"\s*namespace:\s*(\S+)")` 抓取后直接与期望值比较，不剥引号。命中的是 ConfigMap `data.config.yaml` 正文里应用自己的 `nacos.namespace: "zymix-stage"`，不是 K8s 的 `metadata.namespace`。
- 解法：CM 正文里的 namespace 写成不带引号的 `zymix-stage`（值不含 `: # ` 空格，YAML 上等价，也与线上渲染形态一致）。不要为了过检查去动 `metadata.namespace`。
- 预检：`python3 validate.py --class im --env <env> --dir <dir>`；报 NS 时先看命中行是 `metadata` 还是 CM 正文。
- 适用：IM（`cloud-event-svc/test` 的 CM 也有带引号写法，会同样误报）。

## P24 cloudwatch / opentelemetry 那 8 个注解不用手写，是集群 webhook 注进去的

- 现象：照 `deployment/` 快照抄新清单，纠结要不要带上 `cloudwatch.aws.amazon.com/auto-annotate-*` 和 `instrumentation.opentelemetry.io/inject-*`；带上又怕给新服务塞了不需要的 java/python/dotnet 探针。
- 原因：这 8 个注解由集群的 mutating webhook 自动加。实测：apply 的清单里只写了 3 个 prometheus 注解，落到集群里就变成 11 个。相应的 adot-autoinstrumentation init 容器也是自动注入的（Pod 会先 `PodInitializing` 几秒）。
- 解法：新清单只写自己要的（IM 类写 3 个 prometheus 注解），其余交给集群。快照里比你写的多出来的注解不是漏抄。
- 预检：apply 后 `kubectl -n <ns> get deploy <name> -o jsonpath='{.spec.template.metadata.annotations}'` 对比清单，多出来的即为注入项。
- 适用：IM（stage 实测；test/prod 同集群策略需各自确认）。

## P25 把「不进 git」做成了「不落盘」，本机没有真值文件

- 现象：Secret 已经在集群里跑着，但本机 `<project>/<env>/secret/` 下只有 `.example`，没有真值文件。要重新 apply、要和集群比对、要排查配置对不对，全都无从下手，只能再去跳板机上现捞。
- 原因：把「明文不进 git」误解成「明文不能存在于本机」，于是设计成 Secret→Secret 平移、值不落盘，或者 apply 完就把 `.secret.env` 删掉。
- 解法：真值文件留在本机，只是不进 git。 靠 `.gitignore` 的 `/*.secret.env` 挡住入库，再 `chmod 600` 限权，不靠删除。集群里已有 Secret 而本机缺文件时，从集群拉下来补齐（用管道直接落盘，值不过终端、不进对话）。
- 预检：`ls -l <project>/<env>/secret/*.secret.env` 存在且是 `600`；`git check-ignore -v --no-index <file>` 有输出；`git ls-files --error-unmatch <file>` 报错（= 未被跟踪）。
- 适用：IM（miniapp 同理，对应的是 `*.local.yaml`）。
