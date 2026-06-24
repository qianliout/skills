# docker-mcp

通过 MCP 协议管理 Docker 容器、镜像、网络和数据卷。

- **npm**: `mcp-docker-server`
- **GitHub**: https://github.com/ofershap/mcp-server-docker
- **运行方式**: `npx`

> 另有一个 Python 版本 `mcp-server-docker`（PyPI/uvx），功能更丰富但需要 Python 环境。本目录以 npm 版为准。

---

## 核心功能

| 工具 | 用途 |
|------|------|
| `list_containers` | 列出所有容器（含运行/停止状态） |
| `start_container` / `stop_container` | 启停容器 |
| `restart_container` | 重启容器 |
| `remove_container` | 删除容器 |
| `get_container_logs` | 获取容器日志 |
| `exec_container` | 在容器内执行命令 |
| `inspect_container` | 查看容器详情 |
| `get_container_stats` | 查看容器资源使用统计 |
| `list_images` | 列出本地镜像 |
| `pull_image` | 拉取镜像 |
| `remove_image` | 删除镜像 |
| `list_networks` / `list_volumes` | 查看网络/数据卷 |

---

## 配置方式

### 快速上手（Mac 本地 OrbStack）

OrbStack 内置 Docker，直接零配置运行：

```bash
npx -y mcp-docker-server
# 启动后即可通过 MCP 工具操作 Docker
```

### Mac 本地（OrbStack 的 Docker 环境）

OrbStack 内置 Docker 支持，MCP server 直接通过本地 socket 连接，无需额外配置：

```json
{
  "mcpServers": {
    "docker": {
      "command": "npx",
      "args": ["-y", "mcp-docker-server"]
    }
  }
}
```

若需要通过 SSH 连接远程 Docker 守护进程：

```json
{
  "mcpServers": {
    "docker": {
      "command": "npx",
      "args": ["-y", "mcp-docker-server"],
      "env": {
        "DOCKER_HOST": "ssh://user@remote-host"
      }
    }
  }
}
```

### 生产环境

生产环境建议通过 SSH tunnel 连接远程 Docker daemon，避免暴露 Docker socket：

```json
{
  "mcpServers": {
    "docker": {
      "command": "npx",
      "args": ["-y", "mcp-docker-server"],
      "env": {
        "DOCKER_HOST": "ssh://ops@prod-node-01"
      }
    }
  }
}
```

> 需要在 `~/.ssh/config` 中配置好 `prod-node-01` 的 SSH 连接。

---

## 安全注意事项

- **生产环境慎用 `remove_container` / `remove_image`**：误删可能导致服务中断
- 如不需要变更操作，可使用 Python 版 (`ckreiling/mcp-server-docker`) 并限制为只读模式
- Docker socket 就是 root 权限，连接远程 daemon 时务必走 SSH 加密通道
- 建议在生产环境配置命令白名单（配合 commands-mcp），不允许 AI 直接操作 `docker rm -f`

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "docker": {
      "command": "npx",
      "args": ["-y", "mcp-docker-server"]
    }
  }
}
```
