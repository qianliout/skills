# 复盘 — internal-api-gateway 三环境首发（2026-09-04）

deploy-im skill 首次实战：test（跑通部署）/ stage / prod（standby 就位）。产物在部署仓
`add-srv/{test,stage,prod}/internal-api-gateway/`。以下按「坑 → 原因 → 规避/修正」整理，
供后续 cloud-*-svc 首发直接避让。

## 人已知的关键点（本次流程已吸收，见 SKILL.md「就位模式」）

部署 stage/prod 时分支代码常常还没合入/推送 —— 此时**不能自动 run Job**（checkout 不到代码、
部署不存在的版本），只能先「就位」：Jenkins 行先改好 push、k8s 资源（CM/Secret/Service/Ingress）
全建好、Deployment `replicas: 0`、ECR 仓库建好；等分支就绪后两步拉起：
跑 selective Job 推镜像 → `kubectl scale --replicas=1`。

## 踩过的坑

### 1. jcli 是 shell alias，skill 脚本子进程拿不到
- 现象：`im-pull/push/run-jenkins.sh` 报 `jcli not found in PATH`。
- 原因：jcli 定义在 `~/.bash_profile` 第 144 行是 `alias jcli='java -jar …/jenkins-cli.jar …'`，
  alias 不进子进程；脚本各自开新 bash。
- 规避：在 jar 同目录（`~/work/golang/bin/`）放同名 wrapper 脚本
  `exec java -jar …/jenkins-cli.jar -s https://jenkins.zymix.io -http -auth @…/.jenkins-cli-auth "$@"`，
  调用时 `PATH="$HOME/work/golang/bin:$PATH"`。脚本内可加检测提示（未做，见待改）。

### 2. ConfigMap 注释里的 `${VAR}` 制造幽灵 MISSING
- 现象：`im-fill-secret.sh` 报 `MISSING VAR`，rc=2，实际并没有缺 key。
- 原因：fill 用正则 `\$\{([A-Z][A-Z0-9_]+)\}` 扫 CM **全文**，注释里「敏感位只留 `${VAR}`」被命中。
- 规避：CM 注释不要写 `${...}` 字面量（SKILL.md 硬规则已加）。

### 3. 模板缺 `restartedAt` annotation（文档与模板不一致）
- 现象：scaffold 产物只有 3 条 prometheus annotation，硬规则要求 4 条。
- 原因：模板没写 `kubectl.kubernetes.io/restartedAt`，SKILL.md 却声称已写入。
- 修正：已补进 canonical `templates/k8s/01-deployment.yaml.tmpl`。老副本如再缺，apply 前手工补。

### 4. 需要 Ingress 的服务，skill 流程不覆盖
- 现象：`im-apply-k8s.sh` 只 apply 00/01/02，Ingress 无人处理；scaffold 也不生成。
- 修正：`im-apply-k8s.sh` 现支持目录里存在 `03-ingress.yaml` 时一并 apply（可选文件）。
- 经验：host 由人定；tls secret 三环境都是 `zymix-io-tls`；**ingress class 各环境不同**：
  test/stage `nginx-alb`，prod `nginx`（照抄各环境现网 gateway ingress，勿统一）。

### 5. 首发 `:init` 镜像不存在 → ImagePullBackOff
- 现象：apply 后 Pod `ImagePullBackOff`。
- 原因：首发 tag `init` 在 Jenkins 首跑成功前 ECR 里没有；Jenkins 跑完 `set image` 写真 tag 后自愈。
- 规避：属预期，写进 doc；不要当故障排查。standby（replicas 0）模式无此噪音。

### 6. 业务 binary 连不上 IAM-only MSK（sarama 裸连）
- 现象：同环境所有 Kafka 用户都是 `*.kafka-serverless.*.amazonaws.com:9098`（IAM-only），
  而该服务代码全走 `mq.DefaultKafkaConfig(brokers,…)`，KafkaConf 无 iam/tls 字段 → 物理连不上。
- 处理：CM broker 仍抄同环境 MSK 端点（用户决定），接受启动 WARN 降级
  （`Kafka routes remain unavailable`、pay_notify 跳过、topic 不建），等业务仓补 IAM 后换镜像激活。
- 教训：先查业务代码的 kafka 客户端装配再定 broker，别假设「参考其他服务」一定成立；
  kafka 初始化失败在 main 里是 WARN 不 crash，可安全先发。

### 7. `*_DATABASE_DSN` 自动回填可能落错库
- 现象：fill 回填的 DSN 来自 PREFER 列表第一个命中（`cloud-user-svc-secret`）。
- 影响：单库环境（全服务共用 `db_zymix_test/stage/prod`）恰好正确；多库环境会拿到 user 库。
- 规避：回填后**人工核对** dbname 与连接串（本次用 `to_regclass('public.partner_notify_outbox')`
  验证表在目标库，test 命中、stage/prod 因 RDS sg 从跳板机不可达而留待发版时查）。

### 8. prod 跳板机别名缺失
- 现象：`ssh prod-jenkins` → `Could not resolve hostname`。
- 原因：所有 kubeconfig 都在这台 bastion（test-jenkins 43.198.147.66），本机 ssh config 只有
  `test-jenkins`，没有 `prod-jenkins`。
- 规避：`~/.ssh/config` 加 `prod-jenkins → 43.198.147.66`，或 prod 操作全部
  `ssh test-jenkins` + `--kubeconfig=/opt/jenkins-scripts/config/prod_config` 复刻（本次用后者）。

### 9. Jenkins 构建机磁盘满 → 整条 Job 失败
- 现象：主/selective Job 在 docker build `chown: No space left on device` / containerd
  `no space left on device`，Push 阶段整体跳过，与部署配置无关。
- 教训：Job 失败先看是不是共享构建机环境问题（看失败点是否在自己服务之外）；磁盘没清前
  盲重试是浪费（15 分钟/轮）。

### 10. 服务无 log 段，日志级别靠 env
- 现象：main 里 logger 级别读 `LOG_LEVEL`/`LOG_FORMAT` env，conf 无 log 段；模板 env 只有 APP_ENV。
- 规避：Secret 里补 `LOG_LEVEL=debug` + `LOG_FORMAT=plain`（envFrom 注入），便于看降级 WARN。

### 11. prod 校验差异
- `kafka.ensure_topics` prod 必须 `false`（conf.Validate 生产拒绝 true），test/stage 可 true。
- prod 强制 redis（`buildIdempotencyStore` 空 addrs 时 prod panic），test/stage 可内存幂等。
- 这些进 CM 前就要按环境分好，别三环境共用一份。

## Skill 不好的地方 / 待改清单

| # | 问题 | 状态 |
| --- | --- | --- |
| 1 | 模板缺 restartedAt（文档声称已写） | 已修 template |
| 2 | 需要 Ingress 的服务流程不覆盖 | 已修 apply 脚本（03 可选）；host 仍靠人给 |
| 3 | 无 standby/就位模式说明 | 已加 SKILL.md 小节 |
| 4 | 环境表缺 ingress class / ensure_topics / jump 共享说明 | 已补表 + 脚注 |
| 5 | fill 扫 CM 注释的 `${VAR}` 制造幽灵 MISSING | SKILL.md 硬规则提示（脚本未过滤注释，可后续改） |
| 6 | `*_DATABASE_DSN` PREFER 固定列表有串库风险 | 文档警示；可加 `--db-hint` |
| 7 | jcli alias 依赖，脚本内无检测 | 待改：脚本开头 `command -v jcli` 失败给 alias/wrapper 提示 |
| 8 | `im-push-jenkins.sh` 正常场景也打 `WARN … no added lines vs pulled original` 随后又 updated，误导 | 待修：比对基线/文案 |
| 9 | 环境差异（MSK IAM 依赖、log env、gooseEnabled 默认关、不建表）散落各服务 | 已汇总到 SKILL.md「已知缺口」 |

## 结论

首发流程在「test 正常 rollout + stage/prod standby」两种形态下都能跑完；主要返工点集中在
**模板/脚本与文档不一致**和**环境差异未成表**。上面修正后，下次首发应只需：
scaffold → 抄同环境 CM 地址写 CM（注释别带 `${VAR}`）→ fill（人工核对 DSN 落库）→
jenkins pull/add/push → ensure-ecr → create-secret → apply（含 03 ingress）→ 按形态跑 Job 或 scale。
