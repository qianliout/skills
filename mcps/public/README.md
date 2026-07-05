# Public MCP Services

公共 MCP 按服务独立维护。这个目录保存可复用的 MCP 配置说明，实际启用范围由 `mcps/profiles.json` 控制。

## 运维分类

| 分类 | MCP | 典型用途 |
| ---- | --- | -------- |
| 云资源管理 | `alibabacloud-mcp`、`aws-mcp`、`azure-mcp` | 查询和管理云厂商资源 |
| 主机与远程执行 | `ssh-mcp`、`commands-mcp`、`filesystem`、`filesystem-mcp` | 远程主机操作、本地命令执行、受控文件访问 |
| 容器与编排 | `kubernetes-mcp`、`docker-mcp` | K8s 资源查询、容器环境排查、本地集群管理 |
| 配置与自动化 | `ansible-mcp`、`terraform-mcp` | Playbook、IaC、环境检查、自动化变更 |
| CI/CD | `jenkins-mcp` | Jenkins 作业、构建、日志、测试结果和 SCM 信息 |
| 监控与可观测 | `prometheus-mcp`、`grafana-mcp`、`elasticsearch-mcp` | 指标查询、仪表盘、日志检索、问题定位 |
| 告警与协作 | `pagerduty-mcp`、`slack-mcp` | 事件响应、值班流转、团队协作通知 |
| 数据存储 | `mysql-mcp`、`postgres-mcp`、`redis-mcp` | 数据库查询、缓存排查、连接和状态检查 |
| Web 与资料获取 | `fetch-mcp`、`web_reader`、`playwright`、`puppeteer-mcp` | 抓取网页、浏览器自动化、验证 Web 行为 |
| 思考与记忆 | `sequential-thinking`、`neural-memory` | 复杂排查拆解、长期上下文记忆 |
| 设计协作 | `figma-developer-mcp`、`supercharged-figma`、`4_5v_mcp` | Figma 设计读取、设计资产和界面协作 |

## 推荐启用顺序

运维日常优先启用 `filesystem`、`jenkins-mcp`、`kubernetes-mcp`、`prometheus-mcp` 和对应云厂商 MCP。需要执行变更时再启用 `ansible-mcp`、`terraform-mcp`、`ssh-mcp` 或 `commands-mcp`，并优先使用只读或受限配置。

排查数据库、中间件或缓存问题时，再按需启用 `mysql-mcp`、`postgres-mcp`、`redis-mcp` 和 `elasticsearch-mcp`。涉及告警流转和团队沟通时，组合 `pagerduty-mcp` 与 `slack-mcp`。
