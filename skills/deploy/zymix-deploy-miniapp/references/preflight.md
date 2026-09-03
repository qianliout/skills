# Probe 预检清单（miniapp）

Probe 阶段逐项跑完，把结果记下来带进 Decide。每一条右侧标的是对应坑号，跳过就是主动选择踩它。

只读探查优先 MCP，MCP 覆盖不到的走 `ssh <跳板机>`。
miniapp 的 prod 集群目前不在 MCP 里，只能 `ssh prod-jenkins`。

## A. 类别与环境

| # | 检查 | 命令 / 依据 | 坑 |
|---|---|---|---|
| A1 | 确认是 miniapp 类 | 资源前缀 `zymix-<svc>`、kubeconfig `miniapp_config`、一服务一仓；对不上 → 改用 zymix-deploy-im | — |
| A2 | 环境已由用户显式指定 | AskUserQuestion，不推断 | P1 |
| A3 | 跳板机与环境匹配 | test→test-jenkins；prod→prod-jenkins | P1 |
| A4 | 连对了集群 | `ssh <jump> "kubectl --kubeconfig=<cfg> get ns"`，namespace 集合符合预期（test=`zymix-dev`、prod=`zymix-prod`） | P1 |

## B. 源码

只读。 本节全部是 `grep` / `ls` / `git ls-remote` 级别的动作，不编辑、不 commit、不 push（P19）。

| # | 检查 | 命令 | 坑 |
|---|---|---|---|
| B1 | 怎么启动、听哪个端口 | 读 `main.go` / `cmd/`；确认监听端口 | — |
| B2 | 配置怎么读、读哪个路径 | 找配置加载代码，确认 args 形式（GoFrame `-gf.gcfg.file` / 其它 `-conf`） | — |
| B3 | 有无自动 migrate | 找 migrate/AutoMigrate；没有就要手工灌 schema | P9 |
| B4 | 有无真 `/healthz` | `grep -rn 'healthz' <src> --include=*.go` | P11 |
| B5 | 前端资源是否 embed | 决定镜像要不要 `COPY resource/` | P6 |
| B6 | 自带 Dockerfile 能否用 | `ls <src>/manifest/docker/Dockerfile`；默认不用，用 Jenkinsfile 内嵌 | P6 |
| B7 | 目标分支有真实提交 | `git ls-remote <url> refs/heads/<branch>` 对比 `dev` | P5 |
| B8 | 记下源码仓当前 sha | `git -C <src> rev-parse --short HEAD`；交付前再比一次，必须没变 | P19 |

## C. 集群

| # | 检查 | 命令 | 坑 |
|---|---|---|---|
| C1 | 资源名不撞车 | `kubectl get deploy,svc,cm,ingress -n <ns> \| grep -w <name>` 无命中 | P15 |
| C2 | 拉取与 TLS Secret 在 | `kubectl get secret -n <ns> aws-ecr zymix-io-tls` | P14 |
| C3 | Ingress 入口 IP | `kubectl get ingress -n <ns>` 看现有 ADDRESS | — |
| C4 | 参考同类服务的实际配置 | 读 `deployment/miniapp_config/zymix-{dev,stage}/` 快照里最近的同类服务（ticket-tailor、rent-rewards、minigame-ranking） | — |

## D. 数据库 / Redis

先读 [db-topology.md](db-topology.md)：miniapp 一服务一库，要建。两个环境是两套完全不同的库。

| # | 检查 | 命令 | 坑 |
|---|---|---|---|
| D0 | 判定要不要建库 | miniapp：一服务一库，要建 | — |
| D1 | test 的库在 docker 容器 | `ssh -i ~/.ssh/dev_zz.pem ubuntu@43.129.216.91` → `sudo docker exec dev-postgres17 psql`（不是跳板机） | — |
| D2 | 密码以 TCP 认证为准 | `docker inspect` 取 `POSTGRES_PASSWORD` → 主机映射端口 `psql -c 'select 1'` | P2 |
| D3 | Pod 内可达内网地址 | `kubectl run -n <ns> --rm -it netcheck --image=busybox --restart=Never -- nc -zv <内网IP> <port>` | P3 |
| D4 | 库是否已存在 | `provision-db.sh ...`（不带 `--apply` 即 dry-run，会打印「已存在」） | P9 |
| D5 | 服务有没有自动 migrate | 见 B3。没有 → schema 必须一起灌，不能只建空库 | P9 |
| D6 | schema 文件清单与顺序 | 找基线 + 增量目录，写成 `schema-order.txt`，确认哪些文件不存在要跳过 | P9 |
| D7 | prod 的 DDL 通道 | prod 的库在腾讯云 CDB，管理员账号建库、业务账号灌 schema；在 `prod-jenkins` 上公网 `psql`，算闸门 3 | — |
| D8 | Redis db 号不与同集群其他服务冲突 | 读同 namespace 其它服务的 CM | — |

## E. 镜像仓

| # | 检查 | 命令 | 坑 |
|---|---|---|---|
| E1 | region 与仓库名 | `ssh <jump> "aws ecr describe-repositories --region <region> --repository-names <repo>"` | P7 |
| E2 | 镜像 namespace | miniapp：`zymix_mini_app/<repo>` | P7 |

## F. 流水线

| # | 检查 | 命令 / 依据 | 坑 |
|---|---|---|---|
| F1 | Job 是否已存在 | `jcli list-jobs app-game` | — |
| F3 | `jcli` 在本机是否可用 | `jcli who-am-i`；不通则改走 `ssh <jump>` 上的 jcli | — |
| F4 | agent label | miniapp test `dev` / prod `built-in` | — |
| F5 | prod：哪个分支会自动触发构建 | `jcli get-job <prod-job> \| grep -A6 GenericTrigger` 读出 `regexpFilterExpression`。这个分支你不能推，推了等于点 Build | P18 |

## H. 闸门 0（Probe 收尾，必须过用户确认）

Probe 的最后一步：把三张表填满，逐项过给用户。填不满就是 Probe 没做完。
模板 [../templates/inventory.md](../templates/inventory.md)。

| # | 检查 | 依据 | 坑 |
|---|---|---|---|
| H1 | 敏感信息逐个 key 列全 | 不许「等等 / 若干 / 其它配置」；每个 key 标明用途 | — |
| H2 | 每个 key 的来源三选一 | 复用现网 `<ns>/<cm 名>.<key>` / AI 生成`<规则>` / 需用户提供 | — |
| H3 | 「需用户提供」的当场问全 | 外部凭据（第三方 appSecret、S3、合作方 token） | — |
| H4 | prod 不沿用 test 的外部凭据与 JWT | 逐个重新要 | — |
| H5 | 每个 key 标明本机真值文件路径 | miniapp→`*.local.yaml`。留本机不删 | P25 |
| H6 | DB 表：host / 库 / schema / 账号 / 是否新建（miniapp 填是）/ 表从哪来 | — | P9 |
| H7 | Redis 表：地址 / db 号 / 密码来源 | 并列出同 namespace 还有谁在用这个 db 号 | — |
| H8 | 用户已确认 | 三张表原样并入 rollout 文档「事实」段 | — |

## G. 生成后（Scaffold 末尾）

| # | 检查 | 命令 | 坑 |
|---|---|---|---|
| G1 | 校验脚本通过 | `python3 <本 skill 目录>/validate.py --class miniapp --env <e> --dir <d>` | P4 P8 P13 |
| G2 | 真值 CM 被忽略 | `git check-ignore -v --no-index <dir>/k8s/00-configmap.local.yaml` 有输出（`--no-index` 不能省：已跟踪文件会让 check-ignore 静默） | P13 |
| G4 | 本机真值文件在、权限对、没被跟踪 | `ls -l <真值文件>` 是 `600`；`git check-ignore -v --no-index <f>` 有输出；`git ls-files --error-unmatch <f>` 报错 | P25 |
| G5 | 生成的 key 集合与闸门 0 表一致 | 多出来或少掉的都要回头对 | — |
