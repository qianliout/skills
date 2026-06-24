# grafana-mcp

通过 MCP 协议操作 Grafana：查询 Dashboard、Prometheus 指标、Loki 日志、管理告警和 OnCall。

- **npm**: `@leval/mcp-grafana`
- **GitHub**: https://github.com/levalhq/mcp-grafana
- **运行方式**: `npx`

---

## 核心功能（43 个工具）

| 类别 | 典型工具 | 说明 |
|------|---------|------|
| **Dashboard** | 搜索/获取/创建/更新/删除 Dashboard | 面板管理 |
| **Datasources** | 列出/获取 Datasource 信息 | 数据源查询 |
| **Prometheus** | 即时查询、范围查询、指标元数据 | 集成 PromQL |
| **Loki** | 日志查询、Label 值获取 | 日志检索 |
| **Alerting** | 查询/创建/静默告警规则 | 告警管理 |
| **Incident** | 创建/查询/更新 Incidents | 事件管理 |
| **OnCall** | 查询值班排班、谁在值班 | 值班管理 |
| **Sift** | 执行调查分析 | 根因分析 |
| **Pyroscope** | 持续 Profiling 查询 | 性能分析 |

---

## 前置条件

- Grafana 实例可访问
- **Service Account Token**（推荐）或用户名/密码

创建 Service Account：
1. Grafana → Administration → Service Accounts → Add service account
2. 选择 Role（建议 `Viewer` 只读）
3. 生成 Token（格式 `glsa_xxxxxxxxxxxx`）

---

## 配置方式

### Mac 本地

```json
{
  "mcpServers": {
    "grafana": {
      "command": "npx",
      "args": ["-y", "@leval/mcp-grafana"],
      "env": {
        "GRAFANA_URL": "http://localhost:3000",
        "GRAFANA_SERVICE_ACCOUNT_TOKEN": "glsa_xxxxxxxxxxxx"
      }
    }
  }
}
```

### 生产环境

```json
{
  "mcpServers": {
    "grafana": {
      "command": "npx",
      "args": ["-y", "@leval/mcp-grafana"],
      "env": {
        "GRAFANA_URL": "https://grafana.prod.example.com",
        "GRAFANA_SERVICE_ACCOUNT_TOKEN": "${GRAFANA_TOKEN}"
      }
    }
  }
}
```

**使用用户名/密码（备选）**：
```json
{
  "env": {
    "GRAFANA_URL": "https://grafana.prod.example.com",
    "GRAFANA_USERNAME": "${GRAFANA_USER}",
    "GRAFANA_PASSWORD": "${GRAFANA_PASS}"
  }
}
```

### TLS 配置

自签名证书场景：
```json
{
  "env": {
    "GRAFANA_URL": "https://grafana.internal",
    "GRAFANA_SERVICE_ACCOUNT_TOKEN": "${GRAFANA_TOKEN}",
    "TLS_SKIP_VERIFY": "true"
  }
}
```

mTLS 场景：
```json
{
  "env": {
    "TLS_CERT_FILE": "/path/to/client.crt",
    "TLS_KEY_FILE": "/path/to/client.key",
    "TLS_CA_FILE": "/path/to/ca.crt"
  }
}
```

---

## 安全注意事项

- **Service Account 用 `Viewer` 角色**：禁用 Dashboard 编辑、Datasource 管理等写权限
- **不要给 Admin 角色**的 Token，避免 AI 意外修改面板或数据源
- 生产环境走 HTTPS，配置 TLS 证书验证
- Token 通过环境变量注入，不要写在配置文件中

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "grafana": {
      "command": "npx",
      "args": ["-y", "@leval/mcp-grafana"],
      "env": {
        "GRAFANA_URL": "https://grafana.prod.example.com",
        "GRAFANA_SERVICE_ACCOUNT_TOKEN": "${GRAFANA_TOKEN}"
      }
    }
  }
}
```
