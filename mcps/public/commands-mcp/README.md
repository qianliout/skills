# commands-mcp

安全地在服务器上执行白名单内的 Shell 命令的 MCP 服务器。提供两个主流选择：

| 方案 | 包名 | 运行时 | 推荐场景 |
|------|------|--------|---------|
| **mcp-shell-server**（推荐） | `mcp-shell-server` | Python (uvx) | 生产环境，安全控制最完善 |
| shell-command-mcp | `shell-command-mcp` | Node.js (npx) | 快速上手，简单需求 |

- **GitHub (Python)**: https://github.com/tumf/mcp-shell-server
- **GitHub (Node)**: https://github.com/egoist/shell-command-mcp

---

## 方案一：mcp-shell-server（推荐，安全控制最强）

### 核心功能

| 功能 | 说明 |
|------|------|
| 命令白名单 | `ALLOW_COMMANDS` 环境变量，逗号分隔 |
| 正则模式匹配 | `ALLOW_PATTERNS` 支持正则表达式限制命令格式 |
| 超时控制 | 默认 30s，可配 `MCP_SHELL_DEFAULT_TIMEOUT_SECONDS` |
| 输出上限 | `MCP_SHELL_OUTPUT_LIMIT_BYTES`（默认 1MiB） |
| 默认参数加固 | 自动拒绝 `find -exec`、`awk system()`、`xargs`、git alias exec 等危险用法 |
| 审计日志 | 结构化日志 + 密钥脱敏 |

### 配置

```json
{
  "mcpServers": {
    "shell": {
      "command": "uvx",
      "args": ["mcp-shell-server"],
      "env": {
        "ALLOW_COMMANDS": "ls,cat,pwd,grep,wc,touch,find,head,tail,du,df,free,ps,top,uptime,netstat,ss,systemctl,journalctl,kubectl,helm",
        "MCP_SHELL_DEFAULT_TIMEOUT_SECONDS": "30",
        "MCP_SHELL_MAX_TIMEOUT_SECONDS": "300",
        "MCP_SHELL_OUTPUT_LIMIT_BYTES": "1048576"
      }
    }
  }
}
```

> **前置条件**：需要安装 `uv`（Python 包管理器）：`brew install uv` 或 `pip install uv`

---

## 方案二：shell-command-mcp（Node.js，更轻量）

### 核心功能

单一工具 `execute_command`。通过 `ALLOWED_COMMANDS` 环境变量控制。

### 配置

```json
{
  "mcpServers": {
    "shell-command": {
      "command": "npx",
      "args": ["-y", "shell-command-mcp"],
      "env": {
        "ALLOWED_COMMANDS": "cat,ls,echo,pwd,grep,head,tail,df,free,ps"
      }
    }
  }
}
```

> `ALLOWED_COMMANDS="*"` 允许所有命令，**极度危险，生产环境严禁使用**。

---

## K8s 运维场景推荐白名单

```
ls,cat,pwd,grep,wc,head,tail,du,df,free,ps,uptime,netstat,ss,systemctl,journalctl,kubectl,helm,crictl,nerdctl,curl,wget
```

---

## 安全注意事项

- **绝对不要**把 `rm`、`dd`、`mkfs`、`shutdown`、`reboot`、`iptables`、`kill` 等加入白名单
- 白名单匹配的是命令名（argv[0]），不是完整命令行字符串
- Python 方案 (`mcp-shell-server`) 有默认参数加固，比简单白名单更安全
- 生产环境务必配置超时和输出上限，避免执行结果撑爆上下文

---

## 快速上手

```bash
# 确认 uv 已安装
brew install uv

# 验证 mcp-shell-server 可用
uvx mcp-shell-server --help
```

---

## MCP 客户端接入

**推荐（mcp-shell-server）**：
```json
{
  "mcpServers": {
    "shell": {
      "command": "uvx",
      "args": ["mcp-shell-server"],
      "env": {
        "ALLOW_COMMANDS": "ls,cat,pwd,grep,wc,head,tail,du,df,free,ps,uptime,netstat,ss,systemctl,journalctl,kubectl,helm"
      }
    }
  }
}
```

**备选（shell-command-mcp，纯 Node.js）**：
```json
{
  "mcpServers": {
    "shell-command": {
      "command": "npx",
      "args": ["-y", "shell-command-mcp"],
      "env": {
        "ALLOWED_COMMANDS": "cat,ls,echo,pwd,grep,head,tail,df,free,ps"
      }
    }
  }
}
```
