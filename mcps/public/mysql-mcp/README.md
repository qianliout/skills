# mysql-mcp

通过 MCP 协议查询和管理 MySQL 数据库。

- **npm**: `@f4ww4z/mcp-mysql-server`
- **GitHub**: https://github.com/f4ww4z/mcp-mysql-server
- **运行方式**: `npx`

> 另有一个社区活跃版 `@berthojoris/mcp-mysql-server`，提供更多 DDL 工具（create_table / alter_column 等），本目录以简洁版为主。

---

## 核心功能

| 工具 | 用途 |
|------|------|
| `connect_db` | 连接指定数据库 |
| `query` | 执行 SELECT 查询（预编译语句防注入） |
| `execute` | 执行 INSERT / UPDATE / DELETE |
| `list_tables` | 列出所有表 |
| `describe_table` | 查看表结构 |

---

## 配置方式

### 方式一：连接字符串（推荐）

```json
{
  "mcpServers": {
    "mysql": {
      "command": "npx",
      "args": [
        "-y",
        "@f4ww4z/mcp-mysql-server",
        "mysql://user:password@localhost:3306/database"
      ]
    }
  }
}
```

### 方式二：环境变量

```json
{
  "mcpServers": {
    "mysql": {
      "command": "npx",
      "args": ["-y", "@f4ww4z/mcp-mysql-server"],
      "env": {
        "MYSQL_HOST": "localhost",
        "MYSQL_USER": "ops_readonly",
        "MYSQL_PASSWORD": "${MYSQL_PASSWORD}",
        "MYSQL_DATABASE": "mydb"
      }
    }
  }
}
```

### 生产环境

**创建只读用户**：
```sql
CREATE USER 'ops_readonly'@'%' IDENTIFIED BY '<strong_password>';
GRANT SELECT ON mydb.* TO 'ops_readonly'@'%';
FLUSH PRIVILEGES;
```

配置：
```json
{
  "mcpServers": {
    "mysql": {
      "command": "npx",
      "args": [
        "-y",
        "@f4ww4z/mcp-mysql-server",
        "mysql://ops_readonly:${MYSQL_PASSWORD}@prod-mysql-host:3306/mydb"
      ]
    }
  }
}
```

---

## 备选方案：功能更全的版本

如果需要 DDL 操作（建表 / 改表），可以用 `@berthojoris/mcp-mysql-server`：

```json
{
  "mcpServers": {
    "mysql": {
      "command": "npx",
      "type": "stdio",
      "args": ["-y", "@berthojoris/mcp-mysql-server"],
      "env": {
        "DB_HOST": "127.0.0.1",
        "DB_PORT": "3306",
        "DB_USER": "ops_user",
        "DB_PASSWORD": "${MYSQL_PASSWORD}",
        "DB_NAME": "mydb",
        "MCP_PERMISSIONS": "list,read,utility,ddl",
        "MCP_CATEGORIES": "database_discovery,custom_queries,schema_management,analysis"
      }
    }
  }
}
```

> 注意：上游版本已扩展到远超 14 个工具；生产环境建议只授予只读账号，并显式收缩 `MCP_PERMISSIONS` / `MCP_CATEGORIES`。

### 本地 MySQL：全功能配置

如果你就是要连接**本地 MySQL**，并且希望把该 MCP 的能力尽量开满，推荐直接用环境变量方式，避免密码出现在进程参数里。

已提供可直接复制的模板文件：

- `local-mysql-full.mcp.json`
- `local-mysql-full.env.example`

推荐配置：

```json
{
  "mcpServers": {
    "mysql-local-full": {
      "command": "npx",
      "type": "stdio",
      "args": ["-y", "@berthojoris/mcp-mysql-server"],
      "env": {
        "DB_HOST": "127.0.0.1",
        "DB_PORT": "3306",
        "DB_USER": "root",
        "DB_PASSWORD": "<YOUR_MYSQL_PASSWORD>",
        "DB_NAME": "<YOUR_DATABASE_NAME>",
        "MCP_PERMISSIONS": "list,read,create,update,delete,execute,ddl,utility,transaction,procedure",
        "MCP_CATEGORIES": "database_discovery,crud_operations,bulk_operations,seed_operations,custom_queries,schema_management,utilities,transaction_management,stored_procedures,views_management,triggers_management,index_management,constraint_management,table_maintenance,query_optimization,analysis"
      }
    }
  }
}
```

说明：

- `MCP_PERMISSIONS` 打开了列表、读写、自定义 SQL、DDL、事务、存储过程等高权限能力
- `MCP_CATEGORIES` 打开了完整分类集合，对应上游全量工具集
- 如果账号密码里包含 `@`、`:`、`/` 等特殊字符，优先用 `env` 方式，不要直接拼接连接串
- 这是**高权限配置**，只适合本地开发库；生产库请改成只读账号 + 精简权限
- 首次接入后建议先调用 `list_all_tools`，确认实际启用的工具集合

> 备注：上游文档当前版本已经扩展到更高的工具数量，明显多于本 README 前面提到的简化版能力。

---

## 安全注意事项

- **生产环境必须用只读用户**：MySQL 层面 `GRANT SELECT` 即可
- 连接字符串里的密码会出现在进程参数中，建议用 `env` 方式注入
- 该包使用预编译语句，已内置 SQL 注入防护
- 不要授予 `DROP`、`ALTER`、`TRUNCATE`、`DELETE` 权限

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "mysql": {
      "command": "npx",
      "args": ["-y", "@f4ww4z/mcp-mysql-server"],
      "env": {
        "MYSQL_HOST": "prod-mysql.cxxxxxx.ap-southeast-1.rds.amazonaws.com",
        "MYSQL_USER": "ops_readonly",
        "MYSQL_PASSWORD": "${MYSQL_PASSWORD}",
        "MYSQL_DATABASE": "mydb"
      }
    }
  }
}
```
