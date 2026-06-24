# redis-mcp

通过 MCP 协议查询和管理 Redis（支持 Standalone 和 Cluster 模式）。

- **npm**: `mcp-redis`
- **GitHub**: 无公开仓库（发布者 `itapi`）
- **运行方式**: `npx`

> 官方 `@modelcontextprotocol/server-redis` 已归档。另有一个权限可控版 `@liangshanli/mcp-server-redis`。

---

## 核心功能

| 工具 | 用途 |
|------|------|
| `redis_keys` | 按 pattern 查询 key（如 `user:*`） |
| `redis_get` | 获取 key 的值 |
| `redis_set` | 设置 key（支持 TTL） |
| `redis_del` | 删除 key |
| `redis_command` | 执行任意 Redis 命令（Hash / List / Set / Sorted Set 操作） |
| `redis_info` | 服务器诊断信息（内存、连接数、CPU 等） |

---

## 配置方式

### Mac 本地

```json
{
  "mcpServers": {
    "redis": {
      "command": "npx",
      "args": ["-y", "mcp-redis"],
      "env": {
        "REDIS_URL": "redis://localhost:6379"
      }
    }
  }
}
```

带密码：
```json
{
  "mcpServers": {
    "redis": {
      "command": "npx",
      "args": ["-y", "mcp-redis"],
      "env": {
        "REDIS_URL": "redis://localhost:6379",
        "REDIS_PASSWORD": "${REDIS_PASSWORD}"
      }
    }
  }
}
```

### 生产环境

**Redis Cluster**：
```json
{
  "mcpServers": {
    "redis-cluster": {
      "command": "npx",
      "args": ["-y", "mcp-redis"],
      "env": {
        "REDIS_CLUSTER_NODES": "redis://10.0.0.1:7000,redis://10.0.0.2:7001,redis://10.0.0.3:7002",
        "REDIS_PASSWORD": "${REDIS_PASSWORD}"
      }
    }
  }
}
```

**Sentinel**：使用 `REDIS_URL` 指向 Sentinel 地址（底层 ioredis 自动处理）。

---

## 备选方案：权限可控版

如果需要精细控制（只允许读、禁止删 key 等），用 `@liangshanli/mcp-server-redis`：

```json
{
  "mcpServers": {
    "redis": {
      "command": "npx",
      "args": ["-y", "@liangshanli/mcp-server-redis"],
      "env": {
        "HOST": "localhost",
        "PORT": "6379",
        "PASSWORD": "${REDIS_PASSWORD}",
        "ALLOW_INSERT": "true",
        "ALLOW_UPDATE": "false",
        "ALLOW_DELETE": "false",
        "ALLOW_CREATE": "false",
        "ALLOW_DROP": "false"
      }
    }
  }
}
```

---

## 安全注意事项

- **生产环境禁止 `redis_del` / `FLUSHDB` / `FLUSHALL` 等破坏性命令**
- Redis 本身没有用户权限体系，通过 MCP 的 `ALLOW_DELETE=false` 等开关做应用层限制
- 密码不要硬编码，用 `${REDIS_PASSWORD}` 环境变量引用
- 对于 Redis Cluster，连接字符串中的密码会明文出现在进程参数中，建议用 `REDIS_PASSWORD` 环境变量
- 生产环境默认 ACL 只给读权限：`ACL SETUSER ops_readonly on >password ~* +@read`

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "redis": {
      "command": "npx",
      "args": ["-y", "mcp-redis"],
      "env": {
        "REDIS_URL": "redis://prod-redis:6379",
        "REDIS_PASSWORD": "${REDIS_PASSWORD}"
      }
    }
  }
}
```
