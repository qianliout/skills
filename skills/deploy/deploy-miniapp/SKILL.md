---
name: deploy-miniapp
description: Use when deploying a new zymix miniapp or minigame service to test/prod, creating a new Jenkins job plus Ingress, or first-time rollout of an independent miniapp repo.
---

# 部署 miniapp

只做独立仓的小程序 / 小游戏。资源前缀 `zymix-<svc>`，kubeconfig 是 `miniapp_config`。不改业务仓源码。

本 skill 自带脚本和模板，用本机 `jcli` 和 `ssh`。不要去读、不要去调任何部署仓里的脚本。

服务可能是任意语言。怎么编译、听哪个端口、配置怎么读，一律先读 `--src`，不要默认当成 Go。

## 人只回答

1. 服务短名、环境（test / prod，可两个）、源码路径
2. 同 namespace 现网 ConfigMap 对不上的密钥，以及建库连接（`db.secret.env`）
3. 执行前 yes。test 和 prod 都可以跑 Job

## 产物

第二层是环境名。`--out` 由人指定（常见是部署仓的 `add-srv`，那只是落点）：

```text
<out>/<env>/<svc>/
  k8s/                # 00-configmap.yaml、01-deployment.yaml、02-service.yaml、03-ingress.yaml（真值原样）
  jenkins-piplines/
  secret/             # db.secret.env、shared.env —— 真值原样，产物即完整方案（审批后删除，不介意敏感）
  doc/
  probe.json
```

`SCRIPTS` 是本 skill 的 `scripts/`。下面每条都直接跑。

## 流程

1. 跑 `ma-scaffold.sh`，它会读源码并写出 Deployment / Service / Ingress / Jenkinsfile。`probe.json` 里有 `language` 和 `build_mode`。Build 阶段一律在 Jenkinsfile 里 `writeFile` Dockerfile，再 `docker build`，不要改业务仓、也不要只靠 checkout 出来的文件。源码有能用的 Dockerfile 就原样拷进 Jenkinsfile；没有且是 Go，才 host 编译后写 alpine 运行镜像；其他语言没有时按源码语言在 Jenkinsfile 里写一份，不要套 Go 的编译命令。ConfigMap 从源码配置抄到 `00-configmap.yaml`（产物即最终方案，真值原样写入）。
2. 共享 redis / PG 地址先跑 `ma-fill-cm.sh` 从同 ns 现网 CM 回填，真值留在 `secret/shared.env`。只把 MISSING 和本服务独有的密钥问人，补进 `00-configmap.yaml` / `secret/db.secret.env`。值原样保留、可回显。
3. 需要建库时，`ma-scaffold.sh` 已生成 `secret/db.secret.env`，人补连接真值后立刻跑 `ma-provision-db.sh --apply`。先 dry-run 给人看计划，确认后 apply。永不 DROP。没有自动 migrate 的，把 `schema-order.txt` 一起灌。
4. 确认后再 rollout：

```bash
SCRIPTS="<本 skill>/scripts"
OUT="<人指定的 add-srv>"

bash "$SCRIPTS/ma-scaffold.sh" --env "$ENV" --svc "$SVC" --src "$SRC" --git-url "$GIT_URL" --out "$OUT"
bash "$SCRIPTS/ma-fill-cm.sh" --env "$ENV" --svc "$SVC" --out "$OUT"
# 写完 00-configmap.yaml；若要建库：补 secret/db.secret.env 真值后
bash "$SCRIPTS/ma-provision-db.sh" --env "$ENV" --svc "$SVC" --out "$OUT"          # dry-run
bash "$SCRIPTS/ma-provision-db.sh" --env "$ENV" --svc "$SVC" --out "$OUT" --apply
# 确认后：
bash "$SCRIPTS/ma-ensure-ecr.sh" --env "$ENV" --svc "$SVC" --out "$OUT"
bash "$SCRIPTS/ma-apply-k8s.sh" --env "$ENV" --svc "$SVC" --out "$OUT"
bash "$SCRIPTS/ma-create-job.sh" --env "$ENV" --svc "$SVC" --out "$OUT" --apply
bash "$SCRIPTS/ma-run-jenkins.sh" --env "$ENV" --svc "$SVC"
```

5. 看 rollout / 日志，写 `doc/rollout.md`。Ingress 主机要另配 DNS，外网打不开不算发布失败。

## 环境

| | test | prod |
| --- | --- | --- |
| namespace | zymix-dev（不叫 zymix-test） | zymix-prod |
| 跳板机 | test-jenkins | prod-jenkins |
| kubeconfig | miniapp_config | miniapp_config |
| ECR | ap-east-1 / zymix_mini_app | 同 test |
| Ingress | `<svc>-test.zymix.io` | `<svc>.zymix.io` |
| Job | 新建 `test-<svc>` | 新建 `prod-<svc>` |
| agent | dev | built-in |
| 跑 Job | 可以 | 可以 |

一服务一个 Job，一般要新建，不是往共享流水线里加一行。默认加入 View `app-game`。

## 硬规则

- 必须有 Ingress（class `traefik`，TLS `zymix-io-tls`）。Service 是 ClusterIP `9010 -> 容器端口`。
- 不改被部署服务的源码。监听端口、配置路径、有没有 `/healthz`，改清单去适配代码。
- Dockerfile 只写进 Jenkinsfile（`writeFile`）。源码有能用的就原样拷贝，没有就按语言写一份，不要往业务仓落 Dockerfile。
- 产物即完整方案：`00-configmap.yaml`、`*.secret.env` 真值原样写入、可回显、可提交（产物用于审批，审批后删除）。
- 镜像 tag 不用 `latest`。首发 tag 是 `init`，真正 tag 由 Jenkins `set image` 写。
- 不改已上线服务。Job 已存在就只更新本服务那一份 script，不要动别人的 Job。
- Secret 和共享地址先读同 ns 现网服务，读不到再问人。不要编密钥。prod 的 JWT / 第三方凭据不要沿用 test。
- 建库在发镜像之前。人给了连接信息就自动建，幂等，永不 DROP，不复用别人的库名。
- 没有真 `/healthz` 就不要配探针。

## 实战踩坑（2026-09 divination 沉淀）

### 脚手架产物必须核对，别信默认
- 源码里的 `config.yaml` 可能是 k8s 样例清单 / 部署文档，不是应用配置（divination 的 config.yaml 就是一份 Deployment/Service/Ingress 定义）。scaffold 会把它当配置文件挂到 `/app/config`，白挂且该注入的 env 全没进容器。Python/FastAPI 服务多走 `os.getenv`：生成后 grep 源码确认读取方式（`os.getenv` / `open(...)`），env 型就把 CM 改成 envFrom 注入、去掉 volumeMount。
- 跑 scaffold 必须带 `--git-url`，漏了直接退出（`git url empty`）。仓库分支名问人，别猜（本次经历 master / test 反复）。

### jcli 与 Jenkins
- 本机 `jcli` 是 `~/.bash_profile` 的 alias（`java -jar ~/work/golang/bin/jenkins-cli.jar -s https://jenkins.zymix.io -http -auth @~/.jenkins-cli-auth`）。alias 不继承进子 shell，ma-*.sh 里 `command -v jcli` 会失败。先：
  ```bash
  jcli() { java -jar /Users/liuqianli/work/golang/bin/jenkins-cli.jar -s https://jenkins.zymix.io -http -auth @/Users/liuqianli/.jenkins-cli-auth "$@"; }; export -f jcli
  ```
  再跑 ma-*.sh。
- ma-create-job.sh 的 `jcli view add-job` 是 jenkins-zh jcli 语法，jenkins-cli.jar 不支持（只有 `add-job-to-view`）→ 每次 WARN「add to view failed」、Job 没进 View。补：
  ```bash
  java -jar ~/work/golang/bin/jenkins-cli.jar -s https://jenkins.zymix.io -http -auth @~/.jenkins-cli-auth add-job-to-view <线上真实View名> <job>
  ```
  线上真实 View 名可能与默认 `app-game` 不一致（曾有中文 View「小程序小游戏」），先核实：
  `curl -g -sS -u "$(cat ~/.jenkins-cli-auth)" "https://jenkins.zymix.io/api/json?tree=views[name]"`（注意 `[]` 需 `curl -g`）。
- 改分支 ≠ 只改 Jenkinsfile：Job 已存在时 ma-create-job.sh 只 inject `<script>` 段，参数定义区 `<defaultValue>`（BRANCH）与 GenericTrigger 的 `regexpFilterExpression` 不更新，线上残留旧分支。改分支必须本地 Jenkinsfile + config.xml 全部同步后整量 `update-job <job> < config.xml`。
- 云效/codeup 不配 webhook 就纯手动触发；Jenkinsfile 里的 GenericTrigger 只是待命，别当成已自动触发。

### 镜像 push / 拉取的两个 403（症状都像「仓库没建」，其实不是）
- `docker push` 403：构建机 docker 未登录 ECR。built-in（prod-jenkins）没有 dev agent 的预登录。模板已在 Push 段内置 `aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${ECR_REGISTRY}`；手写/旧产物要自己补。
- Pod `ErrImagePull ... no basic auth credentials`：`aws-ecr` imagePullSecret 过期（ECR 令牌 12h，线上 secret 可能是几个月前的）。刷新（token 不进 stdout）：
  ```bash
  ssh <test-jenkins|prod-jenkins> 'TOKEN=$(aws ecr get-login-password --region ap-east-1); kubectl --kubeconfig=/opt/jenkins-scripts/config/miniapp_config create secret docker-registry aws-ecr -n <ns> --docker-server=483898562971.dkr.ecr.ap-east-1.amazonaws.com --docker-username=AWS --docker-password="$TOKEN" --dry-run=client -o yaml | kubectl --kubeconfig=/opt/jenkins-scripts/config/miniapp_config apply -f -'
  ```
  然后删 Pod 重建。老服务 pod 不重启不暴露，新服务首发必踩——发镜像前先刷新一次。

### CM 真值与占位门槛
- `ma-apply-k8s.sh` 卡 `REPLACE_ME|TODO|{{...}}`（检查 local CM + deployment + ingress）。「先留空」就写空串 `""`（可过门槛）；文件里别写 TODO 注释，会被卡。
- envFrom 注入空串会覆盖代码默认值（`os.getenv(k, default)` 拿到空串而不是 default）；想保留代码默认就别写该键。

### 其它
- 钉钉 post failure 引用 `${IMAGE_TAG}`：checkout 之前失败时未定义 → MissingPropertyException（只炸通知，不影响构建结论）。模板已改 `${env.IMAGE_TAG ?: 'N/A'}`。
- prod 构建归人手动触发（部署仓 AGENTS 硬规则，不要 `jcli build prod-*`）。
