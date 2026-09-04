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
  k8s/
  jenkins-piplines/
  secret/
  doc/
  probe.json
```

`SCRIPTS` 是本 skill 的 `scripts/`。下面每条都直接跑。

## 流程

1. 跑 `ma-scaffold.sh`，它会读源码并写出 Deployment / Service / Ingress / Jenkinsfile。`probe.json` 里有 `language` 和 `build_mode`。Build 阶段一律在 Jenkinsfile 里 `writeFile` Dockerfile，再 `docker build`，不要改业务仓、也不要只靠 checkout 出来的文件。源码有能用的 Dockerfile 就原样拷进 Jenkinsfile；没有且是 Go，才 host 编译后写 alpine 运行镜像；其他语言没有时按源码语言在 Jenkinsfile 里写一份，不要套 Go 的编译命令。ConfigMap 从源码配置抄到 `00-configmap.local.yaml`（真值写在 CM 里，example 入库、local 不进 git）。
2. 共享 redis / PG 地址先跑 `ma-fill-cm.sh` 从同 ns 现网 CM 回填。只把 MISSING 和本服务独有的密钥问人，补进 `00-configmap.local.yaml`。值不打到终端。
3. 需要建库时，人填好 `secret/db.secret.env` 后立刻跑 `ma-provision-db.sh --apply`。先 dry-run 给人看计划，确认后 apply。永不 DROP。没有自动 migrate 的，把 `schema-order.txt` 一起灌。
4. 确认后再 rollout：

```bash
SCRIPTS="<本 skill>/scripts"
OUT="<人指定的 add-srv>"

bash "$SCRIPTS/ma-scaffold.sh" --env "$ENV" --svc "$SVC" --src "$SRC" --out "$OUT"
bash "$SCRIPTS/ma-fill-cm.sh" --env "$ENV" --svc "$SVC" --out "$OUT"
# 写完 00-configmap.local.yaml；若要建库：人填 secret/db.secret.env 后
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
- 敏感信息不进 git。`00-configmap.local.yaml` 和 `*.secret.env` 真值不打到终端。
- 镜像 tag 不用 `latest`。首发 tag 是 `init`，真正 tag 由 Jenkins `set image` 写。
- 不改已上线服务。Job 已存在就只更新本服务那一份 script，不要动别人的 Job。
- Secret 和共享地址先读同 ns 现网服务，读不到再问人。不要编密钥。prod 的 JWT / 第三方凭据不要沿用 test。
- 建库在发镜像之前。人给了连接信息就自动建，幂等，永不 DROP，不复用别人的库名。
- 没有真 `/healthz` 就不要配探针。
