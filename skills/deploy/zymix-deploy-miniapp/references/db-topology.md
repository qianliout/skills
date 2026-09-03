# 数据库拓扑（Probe 前先看这页，能省掉一半探查）

miniapp 一服务一个库，且两个环境是两套完全不同的东西：

| 环境 | 实例 | 怎么连 |
| --- | --- | --- |
| test | 主机 `43.129.216.91` 上的 docker 容器 `dev-postgres17` | `ssh -i ~/.ssh/dev_zz.pem ubuntu@43.129.216.91` → `sudo docker exec dev-postgres17 psql`（不是跳板机） |
| prod | 腾讯云 CDB `de-postgres-…tencentcdb.com:28960` | 在 `prod-jenkins` 上公网 `psql` |

prod 有两个角色：管理员（建库用）和业务账号（灌 schema / 运行时用），不是同一个。
集群内连库必须用内网 IP，公网地址在 Pod 里不通（见 P3）。

> IM 云服务类是一个环境一个共享库、新服务不建库——那是 zymix-deploy-im 的拓扑，
> 别在本 skill 里套用；走错 skill 会白建一个没人连的库（P17）。

## 建库用 provision-db.sh

`templates/db/provision-db.sh`，默认 dry-run，幂等，永不 DROP：

```bash
bash <本 skill 目录>/templates/db/provision-db.sh \
  --conn <project>/<env>/db.secret.env \
  --class miniapp --env test --db <dbname> --owner <role> \
  --schema-dir <src>/resource/sql --schema-list <project>/<env>/schema-order.txt
# 看清计划后再加 --apply（prod 还要 --prod-confirm）
```

连接参数放 `db.secret.env`（脚本强制要求这个后缀，`.gitignore` 已挡），
miniapp 用到两种 `MODE`：`ssh-docker`（test）/ `jump-psql`（prod）。

## 空库 = CrashLoop

只建库不建表，服务启动读 `sys_config` 之类的配置表会直接
`CrashLoopBackOff`，而日志长得像镜像/网络/密码问题。Probe 的 B3 必须先确认
服务有没有自动 migrate：没有就得连 schema 一起灌，别留半截。
`provision-db.sh` 收尾会数表，0 张会大声告警。
