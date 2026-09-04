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
  secret/
  doc/
```

`SCRIPTS` 是本 skill 的 `scripts/`。下面每条都直接跑。

## 流程

1. 读 `app/<svc>-svc/configs/config.yaml`，取出端口、`${VAR}`、是否 Kafka、rpc 依赖。环境相关地址从同环境已有 CM 抄，不编。
2. 写 ConfigMap：骨架用源码配置，敏感位只留 `${VAR}`。不建表。Secret 先跑 `im-fill-secret.sh` 从同 ns 现网 `cloud-*-secret` 回填（同名 key，或 `*_DATABASE_DSN` / `*_REDIS_PASSWORD` / `INTERNAL_AUTH_SECRET`）。只把 MISSING 的 key 问人，补进 `secret.env` 后再 `im-create-secret.sh`。值不打到终端。
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

## 环境

| | test | stage | prod |
| --- | --- | --- | --- |
| namespace | zymix-test | zymix-stage | zymix-prod |
| 跳板机 | test-jenkins | test-jenkins | prod-jenkins |
| ECR | ap-east-1 / siu | eu-west-2 / zymix | eu-west-2 / zymix |
| imagePullSecrets | 不写 | tcr-secret + ecr-secret-apeast1 | 同 stage |
| Kafka SA | test-msk-client | msk-client | msk-client |
| 跑 Job | 主 Job + selective | 只跑 selective | 禁止。agent 不得触发 |

每个环境都改两条 Job：`cloud-im-go-server` 和 `-selective`。先 `im-pull-jenkins.sh`，再加行，再 push。diff 只许新增。

test / stage 的 Job 由 `im-run-jenkins.sh` 跑。prod 不要调用该脚本，也不要 `jcli build` / replay / 点 Build。人要发版自己去 Jenkins。

## 硬规则

- Deployment 的 pod template 必须带这四条 annotation（三个环境一样）：`kubectl.kubernetes.io/restartedAt=2026-09-01T23:53:36+08:00`、`prometheus.io/path=/metrics`、`prometheus.io/port=9100`、`prometheus.io/scrape=true`。`im-scaffold.sh` 已写进模板。
- 敏感信息不进 ConfigMap。Secret 真值不进 git、不打到终端。
- 镜像 tag 不用 `latest`。首发 tag 是 `init`，真正 tag 由 Jenkins `set image` 写。
- 不改已上线服务。不覆盖别人的 Jenkins 行。
- prod 不得由本 skill 触发 Job：不 `jcli build prod-*`，不 replay，不点 Build，不推会命中 prod `master` webhook 的分支。人说「手动跑一下」也拒绝。
- Secret 先读同 ns 现网服务，读不到再问人。不要编密钥。
