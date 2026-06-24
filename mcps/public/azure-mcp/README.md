# azure-mcp

Microsoft 官方 Azure MCP 服务器。覆盖 **43+ Azure 服务**，包括 AKS、App Service、Cosmos DB、Key Vault、SQL Database、Azure Monitor 等。

- **npm**: `@azure/mcp`
- **GitHub**: https://github.com/microsoft/mcp（`servers/Azure.Mcp.Server`）
- **运行方式**: `npx`（也支持 `uvx` / .NET `dnx`）

---

## 核心功能

| 能力 | 说明 |
|------|------|
| **43+ Azure 服务** | AKS、App Service、Cosmos DB、SQL Database、Functions、Storage、Key Vault、AI Search… |
| **Azure Monitor** | 查询指标、日志、告警 |
| **Terraform 文档** | 实时搜索 Terraform on Azure 文档 |
| **Well-Architected Framework** | 架构最佳实践指导 |
| **SRE Agent** | 自动化故障排查 |
| **只读模式** | `readOnly: true` 禁止变更操作 |
| **服务过滤** | 选择性启用需要的 Azure 服务 |

---

## 前置条件

- **Azure CLI** 已登录：
  ```bash
  az login
  ```
- 或通过 VS Code Azure 扩展登录

---

## 配置方式

### Mac 本地

```json
{
  "mcpServers": {
    "azure": {
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"]
    }
  }
}
```

Python 方式（`uvx`）：
```json
{
  "mcpServers": {
    "azure": {
      "command": "uvx",
      "args": ["--from", "msmcp-azure", "azmcp", "server", "start"]
    }
  }
}
```

### 生产环境

生产环境**强烈建议启用只读模式**和**服务过滤**：

通过 VS Code 扩展设置或在 `mcp.json` 中配置：

```json
{
  "mcpServers": {
    "azure": {
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"],
      "env": {
        "AZURE_MCP_COLLECT_TELEMETRY": "false"
      }
    }
  }
}
```

> 精细的服务/操作控制目前在 VS Code 扩展端（`azureMcp.enabledServices`、`azureMcp.readOnly`），MCP 配置文件暂不支持直接传这些参数。

---

## 安全注意事项

- **生产环境必须启用 `readOnly: true`**（通过 VS Code 扩展设置或 proxy 层限制）
- `az login` 会缓存凭据，确保部署 MCP server 的机器安全
- 关闭遥测：`AZURE_MCP_COLLECT_TELEMETRY=false`
- 配合 `enabledServices` 只开放需要的 Azure 服务
- 定期轮换 Service Principal 凭据

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "azure": {
      "command": "npx",
      "args": ["-y", "@azure/mcp@latest", "server", "start"]
    }
  }
}
```
