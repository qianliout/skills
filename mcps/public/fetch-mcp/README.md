# fetch-mcp

通过 MCP 协议抓取网页内容，自动将 HTML 转换为 Markdown 供 AI 阅读。

- **PyPI**: `mcp-server-fetch`
- **GitHub**: https://github.com/modelcontextprotocol/servers（官方参考服务器）
- **运行方式**: `uvx`
- **状态**: ✅ 官方维护中，活跃

---

## 核心功能

| 工具 | 用途 |
|------|------|
| `fetch` | 抓取 URL 内容，返回干净的 Markdown |

特性：
- **HTML → Markdown 自动转换**：剥离样式和脚本，只保留文本内容
- **分块读取**：通过 `start_index` / `max_length` 参数分批获取大页面
- **自定义 User-Agent**：防止被目标网站拦截
- **代理支持**：通过 `--proxy-url` 走 HTTP 代理
- **robots.txt** 默认遵守，可跳过

---

## 配置方式

### Mac 本地

```json
{
  "mcpServers": {
    "fetch": {
      "command": "uvx",
      "args": [
        "mcp-server-fetch",
        "--user-agent", "OpsMCP/1.0"
      ]
    }
  }
}
```

> 需要安装 `uv`：`brew install uv`

### 生产环境（通过 HTTP 代理）

```json
{
  "mcpServers": {
    "fetch": {
      "command": "uvx",
      "args": [
        "mcp-server-fetch",
        "--proxy-url", "http://proxy.internal:8080",
        "--user-agent", "OpsMCP/1.0"
      ]
    }
  }
}
```

### 忽略 robots.txt

```json
{
  "args": [
    "mcp-server-fetch",
    "--ignore-robots-txt",
    "--user-agent", "OpsMCP/1.0"
  ]
}
```

> 仅在内网运维平台等自有站点中使用，公网站点请尊重 robots.txt。

---

## 使用场景

- **抓取内部运维平台状态页面**：监控面板 HTML → Markdown → AI 分析
- **读取 API 文档**：离线文档站点的 https 页面一键转为文本
- **查看 GitHub Release Notes**：抓取变更日志，AI 总结版本变化
- **抓取第三方服务状态页**：AWS/GCP Status Dashboard → AI 判断是否影响业务

---

## 安全注意事项

- **仅抓取可信 URL**：fetch 会下载完整内容到内存，恶意页面可能消耗大量资源
- 默认 `max_length=5000` 限制了返回内容大小，可通过工具参数调整
- 通过 `--proxy-url` 强制走内网代理，避免直接访问公网
- 该工具**只能 GET**，不能 POST/PUT/DELETE，相对安全
- 内网站点建议加 `--ignore-robots-txt` 和自定义 `--user-agent`

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "fetch": {
      "command": "uvx",
      "args": [
        "mcp-server-fetch",
        "--user-agent", "OpsMCP/1.0"
      ]
    }
  }
}
```

### 调用示例

```json
// 抓取完整页面
{ "tool": "fetch", "params": { "url": "https://status.aws.amazon.com", "max_length": 10000 } }

// 分块读取（从第 5001 个字符开始）
{ "tool": "fetch", "params": { "url": "https://example.com/docs", "max_length": 5000, "start_index": 5000 } }

// 获取原始 HTML（不转 Markdown）
{ "tool": "fetch", "params": { "url": "https://example.com", "raw": true } }
```
