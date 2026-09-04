---
name: deploy-im
description: Use when deploying a new IM cloud-*-svc to zymix test/stage/prod, adding a service to cloud-im-go-server, or first-time rollout of a zymix-im-go-cloud service. Not for miniapp.
---

# 部署 IM cloud-svc

只做 `zymix-im-go-cloud` 的 `cloud-*-svc`。不管 miniapp。不改业务仓源码。

本 skill 自带脚本和模板，用本机 `jcli` 和 `ssh`。不要去读、不要去调任何部署仓里的脚本。

## 人只回答

1. 服务短名和环境（test / stage / prod，可多个）
2. 同 namespace 现网 Secret 对不上的 key
3. 执行前 yes；prod 只确认建资源，不跑 Job

## 产物

第二层是环境名。`--out` 由人指定（常见是部署仓的 `add-srv`，那只是落点）：

```text
<out>/<env>/<svc>-svc/
  k8s/
  jenkins-piplines/
  secret/             # <svc>.secret.env —— 真值原样，产物即完整方案（审批后删除）
  doc/
```

`SCRIPTS` 是本 skill 的 `scripts/`。下面每条都直接跑。

## 流程

1. 读 `app/<svc>-svc/configs/config.yaml`，取出端口、`${VAR}`、是否 Kafka、rpc 依赖。环境相关地址从同环境已有 CM 抄，不编。
2. 写 ConfigMap：骨架用源码配置，敏感位只留 `${VAR}`（真值放 Secret，不进 CM）。不建表。Secret 先跑 `im-fill-secret.sh` 从同 ns 现网 `cloud-*-secret` 回填（同名 key，或 `*_DATABASE_DSN` / `*_REDIS_PASSWORD` / `INTERNAL_AUTH_SECRET`），真值原样写进 `secret/<svc>.secret.env` 并可回显。只把 MISSING 的 key 问人，补进 `secret.env` 后再 `im-create-secret.sh`。
3. 跑脚本（先 scaffold / pull / add / fill-secret，确认后再 rollout）：

```bash
SCRIPTS="<本 skill>/scripts"
OUT="<人指定的 add-srv>"

bash "$SCRIPTS/im-scaffold.sh" --env "$ENV" --svc "$SVC" --port "$PORT" --out "$OUT"   # Kafka 再加 --kafka
# 写好 $OUT/$ENV/$SVC/k8s/00-configmap.yaml
bash "$SCRIPTS/im-fill-secret.sh" --env "$ENV" --svc "$SVC" --out "$OUT"
# 若有 MISSING：问人补 secret.env，不要自己编
bash "$SCRIPTS/im-pull-jenkins.sh" --env "$ENV" --svc "$SVC" --out "$OUT"
python3 "$SCRIPTS/im-add-jenkins-svc.py" --env "$ENV" --svc "$SVC" --port "$PORT" --dir "$OUT/$ENV/$SVC/jenkins-piplines"
# 确认后：
bash "$SCRIPTS/im-ensure-ecr.sh" --env "$ENV" --svc "$SVC"
bash "$SCRIPTS/im-create-secret.sh" --env "$ENV" --svc "$SVC" --out "$OUT"
bash "$SCRIPTS/im-apply-k8s.sh" --env "$ENV" --svc "$SVC" --out "$OUT"
bash "$SCRIPTS/im-push-jenkins.sh" --env "$ENV" --svc "$SVC" --out "$OUT" --apply
# 仅 test / stage：
bash "$SCRIPTS/im-run-jenkins.sh" --env "$ENV" --svc "$SVC"
```

4. 看 rollout / 日志，写 `doc/rollout.md`。prod 到 push 为止，不要跑 Job。

### 就位模式（standby）—— stage / prod 分支代码未就绪时的首发

stage/prod 常比代码合入早一步：分支还没推、Job 一跑必然失败或部署到不存在的代码。
此时只「就位资源」，不碰镜像、不跑 Job：

1. 流程同上走到 `im-push-jenkins.sh --apply`（Jenkins 行先占位，diff 只许新增）。
2. `im-scaffold` 产物把 `01-deployment.yaml` 的 `replicas` 改成 `0`（没有 Pod，就不存在拉不到
   镜像的报错；有人预期 ImagePullBackOff 也正常，0 只是更干净）。
3. `im-ensure-ecr.sh`（仓库先建好）→ `im-create-secret.sh` → `im-apply-k8s.sh`。
4. **不跑** `im-run-jenkins.sh`（test/stage 都不跑，除非分支已就绪）。
5. doc 里写明「拉起 = 分支合入后跑 selective Job 推镜像 + `kubectl scale --replicas=1`」。

首发镜像 tag 是 `init`，Job 成功前 ECR 里没有它 —— Pod `ImagePullBackOff` 属预期，
Job 跑完 `set image` 后自愈，不是部署错误。

## 环境

| | test | stage | prod |
| --- | --- | --- | --- |
| namespace | zymix-test | zymix-stage | zymix-prod |
| 跳板机 | test-jenkins | test-jenkins | prod-jenkins* |
| ECR | ap-east-1 / siu | eu-west-2 / zymix | eu-west-2 / zymix |
| imagePullSecrets | 不写 | tcr-secret + ecr-secret-apeast1 | 同 stage |
| Kafka SA | test-msk-client | msk-client | msk-client |
| 跑 Job | 主 Job + selective | 只跑 selective | 禁止。agent 不得触发 |
| ingressClassName | nginx-alb | nginx-alb | **nginx**（不是 nginx-alb） |
| kafka.ensure_topics | true | true | **必须 false**（conf 生产校验拒绝 true，topic 部署侧预建） |

\* 实际所有 kubeconfig（dev/test/stage/prod_config）都在同一台 bastion（test-jenkins 43.198.147.66）
上：本机 ssh config 若没有 `prod-jenkins` 别名，脚本会 `Could not resolve hostname` ——
加别名指向同一 bastion，或用 `ssh test-jenkins` + `--kubeconfig=/opt/jenkins-scripts/config/prod_config`
复刻同样操作。

每个环境都改两条 Job：`cloud-im-go-server` 和 `-selective`。先 `im-pull-jenkins.sh`，再加行，再 push。diff 只许新增。

test / stage 的 Job 由 `im-run-jenkins.sh` 跑。prod 不要调用该脚本，也不要 `jcli build` / replay / 点 Build。人要发版自己去 Jenkins。

## 硬规则

- Deployment 的 pod template 必须带这四条 annotation（三个环境一样）：`kubectl.kubernetes.io/restartedAt=2026-09-01T23:53:36+08:00`、`prometheus.io/path=/metrics`、`prometheus.io/port=9100`、`prometheus.io/scrape=true`。模板已含全部四条；若某次 scaffold 产物缺 `restartedAt`，apply 前手工补（2026-09 实战踩过：模板曾只带 3 条 prometheus annotation）。
- 写 ConfigMap 时，**注释里不要出现 `${...}` 字面量**（如「敏感位只留 `${VAR}`」）——`im-fill-secret.sh` 的正则会把注释里的占位符也扫成 key，制造幽灵 MISSING `VAR`，脚本返回 2 误报缺 key。
- 敏感信息不进 ConfigMap（真值放 Secret）。`secret/<svc>.secret.env` 里的真值原样保留、可回显、可提交——产物即完整方案，主要用于审批、审批后删除。
- 镜像 tag 不用 `latest`。首发 tag 是 `init`，真正 tag 由 Jenkins `set image` 写。
- 不改已上线服务。不覆盖别人的 Jenkins 行。
- prod 不得由本 skill 触发 Job：不 `jcli build prod-*`，不 replay，不点 Build，不推会命中 prod `master` webhook 的分支。人说「手动跑一下」也拒绝。
- Secret 先读同 ns 现网服务，读不到再问人。不要编密钥。

## 已知缺口（2026-09 复盘，详见 docs/retro-2026-09-internal-api-gateway.md）

- 需要 Ingress 的服务：scaffold 不生成、apply 脚本曾不处理（已支持 `03-ingress.yaml`），host/tls/class 由人给定；tls secret 三环境都是 `zymix-io-tls`，class 见环境表。
- 当前 IM cloud-svc 的 Kafka 若为 IAM-only MSK，而业务 binary 是 sarama 裸连（无 IAM 装配）→ 配置里只能抄 MSK 端点，启动 WARN 降级、topic 不建，等业务仓支持 IAM 后换镜像激活（不改 CM）。
- `*_DATABASE_DSN` 自动回填取 PREFER 列表首个命中（多为 user 库）；单库环境（全 svc 共 `db_zymix_*`）恰好正确，**多库环境必须人工核对落库**。
- 业务无 log 段时，日志级别靠 env：Secret 里补 `LOG_LEVEL` / `LOG_FORMAT`（模板 env 只有 APP_ENV）。
