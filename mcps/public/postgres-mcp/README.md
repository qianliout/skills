# postgres-mcp

通过 MCP 协议查询和管理 PostgreSQL 数据库。

- **npm**: `mcp-postgres`
- **GitHub**: https://github.com/kristofer84/mcp-postgres
- **运行方式**: `npx`

> 官方 `@modelcontextprotocol/server-postgres` 已归档/不再维护，本目录推荐社区活跃版 `mcp-postgres`。

---

## 核心功能

| 工具 | 用途 |
|------|------|
| `list_tables` | 列出所有表 |
| `get_schema` | 获取完整库 schema |
| `describe_table` | 查看表结构（列、类型、约束） |
| `query` | 执行 SELECT 查询 |
| `execute` | 执行 INSERT / UPDATE / DELETE |
| `create_table` / `alter_table` | DDL 操作 |

安全特性：
- **只读模式** `DB_READ_ONLY=true`：禁止所有写操作
- **语句超时** `DB_STATEMENT_TIMEOUT`：防止慢查询拖死服务
- **SSL 支持**：自动下载 AWS RDS CA 证书

---

## 配置方式

### Mac 本地

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "mcp-postgres@latest"],
      "env": {
        "DB_HOST": "localhost",
        "DB_PORT": "5432",
        "DB_USER": "postgres",
        "DB_PASSWORD": "<密码>",
        "DB_NAME": "<数据库名>",
        "DB_READ_ONLY": "true",
        "DB_STATEMENT_TIMEOUT": "30000"
      }
    }
  }
}
```

也可以用 `DATABASE_URL` 一行搞定：
```json
{
  "env": {
    "DATABASE_URL": "postgresql://user:pass@localhost:5432/dbname"
  }
}
```

### 生产环境

**生产环境必须启用只读模式**：

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "mcp-postgres@latest"],
      "env": {
        "DB_HOST": "<生产 PostgreSQL 地址>",
        "DB_PORT": "5432",
        "DB_USER": "ops_readonly",
        "DB_PASSWORD": "${PG_PASSWORD}",
        "DB_NAME": "<数据库名>",
        "DB_SSL_MODE": "require",
        "DB_READ_ONLY": "true",
        "DB_STATEMENT_TIMEOUT": "30000"
      }
    }
  }
}
```

对应的 PostgreSQL 只读用户创建：
```sql
CREATE USER ops_readonly WITH PASSWORD '<strong_password>';
GRANT CONNECT ON DATABASE mydb TO ops_readonly;
GRANT USAGE ON SCHEMA public TO ops_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO ops_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO ops_readonly;
```

---

## 安全注意事项

- **生产环境必须创建专用只读用户**，不要用 superuser 或 owner 账号
- 配合 `DB_READ_ONLY=true` 双重保险（服务端 + 数据库端都限制）
- `DB_STATEMENT_TIMEOUT` 设为 30s，避免大查询影响生产库
- 通过 SSL 加密连接（`DB_SSL_MODE=require`）
- 密码用环境变量注入，不要硬编码在配置文件中

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "mcp-postgres@latest"],
      "env": {
        "DB_HOST": "localhost",
        "DB_PORT": "5432",
        "DB_USER": "ops_readonly",
        "DB_PASSWORD": "${PG_PASSWORD}",
        "DB_NAME": "mydb",
        "DB_SSL_MODE": "require",
        "DB_READ_ONLY": "true",
        "DB_STATEMENT_TIMEOUT": "30000"
      }
    }
  }
}
```
