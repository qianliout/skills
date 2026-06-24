# slack-mcp

通过 MCP 协议操作 Slack：发送消息、读取对话、搜索历史、管理用户组。

- **npm**: `slack-mcp-server`
- **GitHub**: https://github.com/korotovsky/slack-mcp-server
- **运行方式**: `npx`

> 官方 `@modelcontextprotocol/server-slack` 已归档。社区版 `slack-mcp-server` 月下载 115k+，最活跃。

---

## 核心功能（~18 个工具）

| 工具 | 用途 |
|------|------|
| `search_messages` | 搜索消息历史 |
| `get_conversation_history` | 获取指定频道对话历史 |
| `get_thread_replies` | 获取线程回复 |
| `send_message` | 发送消息到指定频道/用户 |
| `add_reaction` | 添加 emoji 反应 |
| `list_channels` | 列出工作区所有频道 |
| `list_users` | 列出工作区所有用户 |
| `get_user_profile` | 获取用户详细信息 |
| `get_unread_messages` | 获取未读消息 |
| `get_saved_items` | 获取已保存的消息/文件 |
| `user_group_create` / `user_group_update` / `user_group_delete` | 用户组管理 |

---

## 配置方式

### Token 类型

| Token 类型 | 环境变量 | 说明 |
|-----------|---------|------|
| **Browser/Stealth Token** | `SLACK_MCP_XOXC_TOKEN` + `SLACK_MCP_XOXD_TOKEN` | 无需创建 Slack App，直接复用浏览器登录态 |
| **Bot Token** | `SLACK_MCP_XOXB_TOKEN` | Slack App Bot，需 OAuth 安装 |
| **User Token** | `SLACK_MCP_XOXP_TOKEN` | 用户 OAuth Token |

### Mac 本地 / 生产环境

**方式一：Bot Token（推荐，权限可控）**

1. 在 https://api.slack.com/apps 创建 Slack App
2. OAuth & Permissions → Bot Token Scopes:
   - `channels:history`、`channels:read`
   - `chat:write`
   - `reactions:read`、`reactions:write`
   - `users:read`
   - `search:read`
3. 安装到工作区，获取 Bot Token (`xoxb-...`)

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "slack-mcp-server"],
      "env": {
        "SLACK_MCP_XOXB_TOKEN": "${SLACK_BOT_TOKEN}"
      }
    }
  }
}
```

**方式二：Stealth Token（无需创建 App）**

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "slack-mcp-server"],
      "env": {
        "SLACK_MCP_XOXC_TOKEN": "${SLACK_XOXC_TOKEN}",
        "SLACK_MCP_XOXD_TOKEN": "${SLACK_XOXD_TOKEN}"
      }
    }
  }
}
```

> Stealth Token 从浏览器 DevTools → Application → Cookies 中提取。**安全性低**，仅建议个人开发用。

### 限制启用的工具

```json
{
  "env": {
    "SLACK_MCP_XOXB_TOKEN": "${SLACK_BOT_TOKEN}",
    "SLACK_MCP_ADD_MESSAGE_TOOL": "true",
    "SLACK_MCP_REACTION_TOOL": "false",
    "SLACK_MCP_MARK_TOOL": "false"
  }
}
```

---

## 安全注意事项

- **Bot Token 权限最小化**：只授予必要的 Scopes
- **不要在公共频道测试发送消息**：生产环境建议先发到 `#ops-test` 私有频道验证
- Stealth Token 模式会暴露完整用户权限，**禁止在共享 MCP server 上使用**
- Token 通过环境变量注入，不要硬编码

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "slack": {
      "command": "npx",
      "args": ["-y", "slack-mcp-server"],
      "env": {
        "SLACK_MCP_XOXB_TOKEN": "${SLACK_BOT_TOKEN}"
      }
    }
  }
}
```
