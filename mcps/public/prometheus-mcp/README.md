# prometheus-mcp

通过 MCP 协议查询 Prometheus 监控指标。支持直接 URL 连接和 K8s 集群自动发现。

- **npm**: `mcp-prometheus`
- **GitHub**: https://github.com/jeanlopezxyz/mcp-prometheus
- **运行方式**: `npx`

---

## 核心功能

| 工具 | 用途 |
|------|------|
| `query` | 执行 PromQL 即时查询 |
| `queryRange` | 执行 PromQL 范围查询（时间区间） |
| `getTargets` | 查看所有抓取目标状态 |
| `getRules` | 查看告警/记录规则 |
| `getPrometheusStatus` | Prometheus 服务健康状态 |
| `getClusterHealthOverview` | 集群健康概览 |
| `diagnoseNode` | 节点级别诊断 |
| `diagnoseNamespace` | 命名空间级别诊断 |
| `getTopResourceConsumers` | 找出资源消耗最高的 Pod |
| `investigatePod` | Pod 级别深度排查 |
| `compareTimeRanges` | 对比两个时间段指标变化 |

---

## 配置方式

### Mac 本地（OrbStack K8s 自带 Prometheus）

如果本地 K8s 中有 Prometheus，可以端口转发：

```bash
# 先转发端口
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090 &
```

```json
{
  "mcpServers": {
    "prometheus": {
      "command": "npx",
      "args": ["-y", "mcp-prometheus@latest"],
      "env": {
        "PROMETHEUS_URL": "http://localhost:9090"
      }
    }
  }
}
```

### 生产环境（K8s 集群内自动发现）

如果 MCP server 部署在 K8s 集群内，可以零配置自动发现 Prometheus：

```json
{
  "mcpServers": {
    "prometheus": {
      "command": "npx",
      "args": [
        "-y",
        "mcp-prometheus@latest",
        "--namespace", "monitoring",
        "--service", "prometheus-operated",
        "--service-port", "9090",
        "--service-scheme", "https"
      ]
    }
  }
}
```

### 生产环境（外部 Prometheus）

直接指定 URL：

```json
{
  "mcpServers": {
    "prometheus": {
      "command": "npx",
      "args": ["-y", "mcp-prometheus@latest"],
      "env": {
        "PROMETHEUS_URL": "https://prometheus.prod.example.com"
      }
    }
  }
}
```

> 如果 Prometheus 有认证，URL 中可以带 basic auth：`https://user:pass@prometheus.prod.example.com`

---

## 安全注意事项

- Prometheus 的 query API 是只读的，但可以消耗大量资源（大范围查询、高基数聚合）
- 生产环境建议使用**只读 Prometheus 用户**或 API 代理层限制请求速率
- K8s 自动发现模式使用集群内的 `kubeconfig`，确保 RBAC 权限最小化
- URL 中的用户名密码在进程参数中可见，建议用环境变量 + shell 包装

---

## 快速上手

```bash
# Mac 本地：先转发本地 K8s Prometheus 端口
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090 &

# 验证连接
curl http://localhost:9090/api/v1/query?query=up
```

---

## MCP 客户端接入

**本地开发（端口转发）**：
```json
{
  "mcpServers": {
    "prometheus": {
      "command": "npx",
      "args": ["-y", "mcp-prometheus@latest"],
      "env": {
        "PROMETHEUS_URL": "http://localhost:9090"
      }
    }
  }
}
```

**生产环境（直接 URL）**：
```json
{
  "mcpServers": {
    "prometheus": {
      "command": "npx",
      "args": ["-y", "mcp-prometheus@latest"],
      "env": {
        "PROMETHEUS_URL": "https://prometheus.prod.example.com"
      }
    }
  }
}
```
