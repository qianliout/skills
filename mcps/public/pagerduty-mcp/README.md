# pagerduty-mcp

通过 MCP 协议查询 PagerDuty：Incident 列表、Service 状态、OnCall 值班信息。

- **npm**: `@vineethnkrishnan/pagerduty-mcp`
- **GitHub**: https://github.com/vineethkrishnan/mcp-pool（monorepo，`packages/pagerduty`）
- **运行方式**: `npx`

> 另有一个 Python 版 `wpfleger96/pagerduty-mcp-server`，支持 Incident 的 acknowledge/resolve 操作。

---

## 核心功能

| 工具 | 用途 |
|------|------|
| `list_incidents` | 查询 Incident（过滤状态、服务、时间范围） |
| `get_incident` | 获取单个 Incident 详情 |
| `list_services` | 列出所有 Service 及状态 |
| `get_oncall_schedule` | 查询当前/未来值班人员 |
| `get_user` | 获取用户信息 |

---

## 前置条件

- PagerDuty **只读 API Key**（推荐）：
  1. PagerDuty → Integrations → API Access Keys → Create API Key
  2. 选择 `Read-only` 权限
  3. Key 格式：`u+xxxxxxxxxxxxxxxx`

---

## 配置方式

### Mac 本地 / 生产环境

```json
{
  "mcpServers": {
    "pagerduty": {
      "command": "npx",
      "args": ["-y", "@vineethnkrishnan/pagerduty-mcp"],
      "env": {
        "PAGERDUTY_API_KEY": "${PD_API_KEY}",
        "PAGERDUTY_BASE_URL": "https://api.pagerduty.com"
      }
    }
  }
}
```

**EU 实例**（欧洲数据中心）：
```json
{
  "env": {
    "PAGERDUTY_API_KEY": "${PD_API_KEY}",
    "PAGERDUTY_BASE_URL": "https://api.eu.pagerduty.com"
  }
}
```

---

## 备选方案：支持 Incident 操作的 Python 版

如果需要 AI 能 acknowledge/resolve Incident，用 Python 版：

```bash
pip install pagerduty-mcp-server
```

```json
{
  "mcpServers": {
    "pagerduty": {
      "command": "python3",
      "args": ["-m", "pagerduty_mcp_server"],
      "env": {
        "PAGERDUTY_API_KEY": "${PD_API_KEY}"
      }
    }
  }
}
```

---

## 安全注意事项

- **API Key 用只读权限**（`Read-only`），防止 AI 误操作关掉真实告警
- 如果确实需要 acknowledge/resolve 权限，创建单独的 API Key 并精确控制
- PagerDuty API Key 格式 `u+...` 是用户级 Token，权限范围是用户本身
- 建议使用 Service Account 的 API Key，而非个人账号
- 定期轮换 API Key

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "pagerduty": {
      "command": "npx",
      "args": ["-y", "@vineethnkrishnan/pagerduty-mcp"],
      "env": {
        "PAGERDUTY_API_KEY": "${PD_API_KEY}"
      }
    }
  }
}
```
