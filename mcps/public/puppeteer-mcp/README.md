# puppeteer-mcp

通过 MCP 协议控制 Chrome 浏览器：导航、截图、点击、填表、执行 JavaScript。

- **npm**: `@playwright/mcp`（推荐替代）
- **GitHub**: https://github.com/microsoft/playwright-mcp
- **运行方式**: `npx`

> 官方 `@modelcontextprotocol/server-puppeteer` 已 **deprecated**。Microsoft 的 `@playwright/mcp` 是官方推荐的替代方案，月下载 21M+。另有 Google 的 `chrome-devtools-mcp`（10M+/月）。

---

## 核心功能

| 工具 | 用途 |
|------|------|
| `browser_navigate` | 导航到 URL |
| `browser_screenshot` | 截图（全页或元素） |
| `browser_click` | 点击元素 |
| `browser_hover` | 悬停元素 |
| `browser_fill` | 填写表单字段 |
| `browser_select` | 选择下拉框值 |
| `browser_evaluate` | 执行 JavaScript |
| `browser_console_messages` | 获取控制台日志 |
| `browser_network_requests` | 获取网络请求日志 |
| `browser_take_screenshot` | 截取元素截图 |

---

## 方案选择

| 方案 | 包名 | 说明 |
|------|------|------|
| **Playwright MCP（推荐）** | `@playwright/mcp` | Microsoft 官方，三浏览器引擎（Chromium/Firefox/WebKit），功能最全 |
| Chrome DevTools MCP | `chrome-devtools-mcp` | Google 官方，仅 Chrome，偏向调试场景 |

---

## 配置方式

### Mac 本地 / 生产环境（Playwright MCP）

```json
{
  "mcpServers": {
    "puppeteer": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest"]
    }
  }
}
```

指定浏览器：
```json
{
  "args": ["-y", "@playwright/mcp@latest", "--browser", "chromium"]
}
```

Headless 模式（无 GUI）：
```json
{
  "args": ["-y", "@playwright/mcp@latest", "--headless"]
}
```

### 备选：Chrome DevTools MCP

```json
{
  "mcpServers": {
    "chrome-devtools": {
      "command": "npx",
      "args": ["-y", "chrome-devtools-mcp@latest"]
    }
  }
}
```

---

## 使用场景

- **自动抓取内部运维平台页面**：打开运维 Dashboard，截图取证
- **调用 REST API**：通过 `browser_evaluate` 执行 `fetch()` 调用内部 API
- **自动化巡检**：定时打开各服务 Health Check 页面，截图存档
- **表单填写**：自动填写运维工单、变更申请

---

## 安全注意事项

- **浏览器运行在 MCP server 本地**，能访问本地网络和文件系统
- 禁止访问 `file://` 协议（防止读取本地敏感文件）
- 生产环境使用 `--headless` 模式减少资源消耗
- 配置网络代理限制可访问的 URL 范围
- 若允许 `browser_evaluate`，本质上可以执行任意 JS，风险相当于给了 AI Node.js 执行权限

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp@latest", "--headless"]
    }
  }
}
```
