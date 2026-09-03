# profile：小程序小游戏类（miniapp）

参考已上线服务：`ticket-tailor`、`rent-rewards`（本仓同名目录）、`minigame-ranking`。
线上样本：`deployment/miniapp_config/zymix-dev/`、`deployment/miniapp_config/zymix-stage/`。

## 环境矩阵

只有 test 和 prod，没有 stage。

| 项 | test | prod |
| --- | --- | --- |
| 跳板机 | `ssh test-jenkins` | `ssh prod-jenkins` |
| kubeconfig | `/opt/jenkins-scripts/config/miniapp_config` | 同路径，另一个集群 |
| namespace | `zymix-dev`（注意：不叫 zymix-test） | `zymix-prod` |
| ECR region | `ap-east-1` | 按 `ap-east-1` 写，Probe 时用 `aws ecr describe-repositories` 实测确认 |
| ECR 仓库 | `zymix_mini_app/<repo>` | 同 |
| Ingress host | `<svc>-test.zymix.io` | `<svc>.zymix.io` |
| Jenkins agent | `dev` | `built-in` |
| Jenkins Job | `test-<svc>` | `prod-<svc>` |
| 快照可查 | 是 | 否（miniapp prod 不在 `deployment/` 也不在 MCP） |

## 密钥处理（本类的硬规则）

- 敏感信息全部写在 ConfigMap 的 `config.yaml` 里，不新建业务 Secret。
  只使用集群已有的 `aws-ecr`（拉镜像）和 `zymix-io-tls`（Ingress TLS）。
- 真值 CM 文件不入库。 生成两份，靠文件名后缀区分：
  - `<project>/<env>/k8s/00-configmap.local.yaml` —— 含真值，被 `.gitignore` 的 `/*.local.yaml` 忽略，只 apply 不提交
  - `<project>/<env>/k8s/00-configmap.example.yaml` —— 敏感位换成 `REPLACE_ME_*`，入库
  - 本类不生成裸的 `00-configmap.yaml`（那个名字留给 IM 类的占位符 CM，它是要入库的）
- `.local.yaml` 留在本机，用完不删，`chmod 600`。 规则是「不进 git」不是「不落盘」——
  重新 apply、跟集群比对、排查配置对不对，全靠本机这份（P25）。
  集群里 CM 已存在而本机没有真值文件时，从集群拉下来补齐，别重新编一套值。
- 真值来源优先级：① 从同环境同类服务的集群/快照读到的共享值（PG 主机、Redis 地址与密码）自动复用；
  ② 本服务独有且可生成的（`auth.jwtKey`、`auth.wxJwtKey`，≥24 字符随机）你自己生成；
  ③ 外部凭据（tcsas appSecret、partnerFeed token、S3 密钥）——只有这类才问用户。
- prod 的 tcsas / partnerFeed / JWT 一律不得沿用 test 的值。

> 为什么不进 Secret：GoFrame `gcfg` 不做 `${VAR}` 展开，CM 里写占位符不会被替换。
> 本类统一按「值在 CM、文件不入库」处理。IM 类相反（值进 Secret、CM 只留 `${VAR}`），走 zymix-deploy-im。

## 命名对照

| 项 | 取值 |
| --- | --- |
| 资源名 / 容器名 | `zymix-<svc>` |
| ConfigMap | `zymix-<svc>-configmap` |
| 容器端口 | GoFrame 18080 / 普通 Go 8080（以 Probe 结论为准） |
| Service | ClusterIP `9010 → <容器端口>` |
| Ingress class | `traefik`，TLS secret `zymix-io-tls` |
| imagePullSecrets | `aws-ecr` |
| replicas | `1` |
| 策略 | `Recreate` |
| 探针 | 有真 `/healthz` 才配；否则不配探针，别拿 `/admin/` 冒充 |
| Webhook token | `zymix-<svc>`（test/prod 共用，regexp 各滤分支） |
| Jenkins View | `app-game` |

## 流水线形态

一服务一个 Job，内嵌 Pipeline（不用 SCM Script Path），Dockerfile 写在 Jenkinsfile 里
（项目自带的 Dockerfile 通常依赖 gf 产物，与 Jenkins 节点 host 编译对不上，不要用）。

阶段：Prepare（解析分支）→ Checkout（Codeup）→ Resolve Environment（`IMAGE_TAG=日期时间-短commit`，钉钉开始）
→ Build image（host `go build` + `writeFile` 内嵌 alpine Dockerfile + `docker build`）→ Push to ECR
→ Update（`kubectl set image`）→ post（钉钉成功/失败/中止）。

模板：`templates/miniapp/Jenkinsfile.tmpl`。

## 执行顺序（阶段 4）

1. 建库 + 灌 schema（若服务需要 DB）。必须在发镜像之前，否则进程启动查不到表会 CrashLoopBackOff（P9）。
   本类是一服务一个库，且两个环境是两套不同的东西：

   | 环境 | 库在哪 | 怎么连 |
   | --- | --- | --- |
   | test | 主机 `43.129.216.91` 的 docker 容器 `dev-postgres17` | `MODE=ssh-docker`（不走跳板机） |
   | prod | 腾讯云 CDB `…tencentcdb.com:28960` | `MODE=jump-psql`，在 `prod-jenkins` 上公网连 |

   prod 的管理员账号（建库）和业务账号（灌 schema / 运行时）不是同一个。
   集群内连库必须用内网 IP，公网地址在 Pod 里不通（P3）。

   用 [`../templates/db/provision-db.sh`](../templates/db/provision-db.sh)（默认 dry-run、幂等、永不 DROP）：

   ```bash
   bash <本 skill 目录>/templates/db/provision-db.sh \
     --conn <project>/<env>/db.secret.env --class miniapp --env <env> \
     --db <dbname> --owner <role> \
     --schema-dir <src>/resource/sql --schema-list <project>/<env>/schema-order.txt
   # 看清计划后再加 --apply（prod 还要 --prod-confirm）
   ```

   连接参数放 `db.secret.env`（脚本强制这个后缀，`.gitignore` 已挡住）。
   收尾会数表；0 张表的告警不要忽略，除非确认服务自带 migrate。
2. 建 ECR 仓库（`aws ecr create-repository --region <region> --image-tag-mutability MUTABLE`）
3. apply 清单：ConfigMap → Deployment → Service → Ingress
4. 建 Jenkins Job（用 `scripts/lib/job_utils.py inject` 把 Jenkinsfile 灌进 config.xml 模板，再 `jcli create-job`），加入 View `app-game`
5. 跑一次构建，流水线自动 `set image`
   - test：你自己跑
   - prod：停。交给用户手动点。 不 `jcli build prod-<svc>`，也不 push 源码仓的
     `prod` 分支——prod Job 挂了 `GenericTrigger`，推分支等于点 Build。
     `prod` 分支的创建和推送也归用户，你只说清楚要从哪个 commit 推
6. `rollout status` + 看日志 + 集群内 curl

清单里的 image 直接写首张真实 tag（或 apply 后立刻 set image）。不要先 apply `:latest` 再等它自己好。

## 验收清单

- [ ] 库存在且表已建（能 `SELECT` 到应用启动时要读的表）
- [ ] ECR 仓库存在于目标 region
- [ ] Job 能从指定分支检出并推镜像（prod 的构建由用户手动触发）
- [ ] 四份清单已 apply，`kubectl get cm <name> -n <ns> -o yaml` 里密码原文正确（`#` 没被当注释吃掉）
- [ ] Pod Ready，日志无启动期 fatal
- [ ] 集群内 `wget`/`curl` 打得通业务路径
- [ ] 未改动 namespace 内任何既有服务
- [ ] `git status` 里看不到 `*.local.yaml`；`git check-ignore --no-index <dir>/k8s/00-configmap.local.yaml` 有输出
- [ ] DNS 另配（外网打不开不算发布失败）
