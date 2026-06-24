# elasticsearch-mcp

通过 MCP 协议查询和管理 Elasticsearch / OpenSearch 集群。

- **PyPI**: `elasticsearch-mcp-server`
- **GitHub**: https://github.com/cr7258/elasticsearch-mcp-server（⭐ ~290）
- **运行方式**: `uvx`（Python）

> 官方 `@elastic/mcp-server-elasticsearch`（npm）已 **deprecated**，v0.4+ 仅提供 Docker 镜像。本目录推荐社区活跃 Python 版，功能更全且支持 OpenSearch。

---

## 核心功能（20+ 工具）

| 类别 | 工具 | 说明 |
|------|------|------|
| **索引管理** | `list_indices`、`get_index`、`create_index`、`delete_index` | 索引 CRUD |
| **文档** | `search_documents`、`index_document`、`get_document`、`delete_document`、`delete_by_query` | 文档 CRUD |
| **数据流** | `create_data_stream`、`get_data_stream`、`delete_data_stream` | Data Stream 管理 |
| **集群** | `get_cluster_health`、`get_cluster_stats` | 集群健康/统计 |
| **别名** | `list_aliases`、`get_alias`、`put_alias`、`delete_alias` | 别名管理 |
| **工具** | `analyze_text`、`general_api_request` | 文本分析、通用 API |

安全特性：
- `DISABLE_HIGH_RISK_OPERATIONS=true`：隐藏所有写操作工具
- `DISABLE_OPERATIONS`：精细禁用特定操作
- 支持 ES 7.x/8.x/9.x 和 OpenSearch 1.x-3.x

---

## 前置条件

- **uv** 已安装：`brew install uv` 或 `pip install uv`

---

## 配置方式

### Mac 本地

```json
{
  "mcpServers": {
    "elasticsearch": {
      "command": "uvx",
      "args": ["elasticsearch-mcp-server"],
      "env": {
        "ELASTICSEARCH_HOSTS": "http://localhost:9200",
        "DISABLE_HIGH_RISK_OPERATIONS": "true"
      }
    }
  }
}
```

### 生产环境（API Key 认证，推荐）

```json
{
  "mcpServers": {
    "elasticsearch": {
      "command": "uvx",
      "args": ["elasticsearch-mcp-server"],
      "env": {
        "ELASTICSEARCH_HOSTS": "https://es-prod.example.com:9200",
        "ELASTICSEARCH_API_KEY": "${ES_API_KEY}",
        "VERIFY_CERTS": "true",
        "DISABLE_HIGH_RISK_OPERATIONS": "true",
        "REQUEST_TIMEOUT": "30"
      }
    }
  }
}
```

### 生产环境（用户名/密码）

```json
{
  "mcpServers": {
    "elasticsearch": {
      "command": "uvx",
      "args": ["elasticsearch-mcp-server"],
      "env": {
        "ELASTICSEARCH_HOSTS": "https://es-prod.example.com:9200",
        "ELASTICSEARCH_USERNAME": "${ES_USER}",
        "ELASTICSEARCH_PASSWORD": "${ES_PASS}",
        "VERIFY_CERTS": "true",
        "DISABLE_HIGH_RISK_OPERATIONS": "true"
      }
    }
  }
}
```

### 多集群配置

创建 `es-clusters.json`：
```json
{
  "prod": {
    "hosts": ["https://es-prod-1:9200", "https://es-prod-2:9200"],
    "api_key": "${ES_PROD_API_KEY}"
  },
  "staging": {
    "hosts": ["https://es-staging:9200"],
    "username": "${ES_STAGING_USER}",
    "password": "${ES_STAGING_PASS}"
  }
}
```

```json
{
  "env": {
    "ELASTICSEARCH_CLUSTERS_FILE": "es-clusters.json",
    "DEFAULT_CLUSTER": "prod",
    "DISABLE_HIGH_RISK_OPERATIONS": "true"
  }
}
```

---

## 安全注意事项

- **生产环境必须设置 `DISABLE_HIGH_RISK_OPERATIONS=true`**：禁用 delete_index、delete_document 等破坏性操作
- 精细禁用：`DISABLE_OPERATIONS=create_index,index_document,put_alias`
- 优先使用 API Key 而非用户名/密码，便于审计和轮换
- 启用 SSL 验证：`VERIFY_CERTS=true`
- 设置 `REQUEST_TIMEOUT`（默认不设），防止大查询卡住

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "elasticsearch": {
      "command": "uvx",
      "args": ["elasticsearch-mcp-server"],
      "env": {
        "ELASTICSEARCH_HOSTS": "https://es-prod:9200",
        "ELASTICSEARCH_API_KEY": "${ES_API_KEY}",
        "VERIFY_CERTS": "true",
        "DISABLE_HIGH_RISK_OPERATIONS": "true"
      }
    }
  }
}
```
