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
      "args": ["-y", "@berthojoris/mcp-mysql-server"],
      "env": {
        "MYSQL_HOST": "localhost",
        "MYSQL_USER": "ops_user",
        "MYSQL_PASSWORD": "${MYSQL_PASSWORD}",
        "MYSQL_DATABASE": "mydb"
      }
    }
  }
}
```

> 注意：此版本有多达 14 个工具（包括 DDL），生产环境建议只授予 SELECT 权限。

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
