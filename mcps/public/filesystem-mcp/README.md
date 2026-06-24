# filesystem-mcp

基于官方 `@modelcontextprotocol/server-filesystem` 的 MCP 服务器配置。让 AI 助手安全地读写指定目录中的文件。

- **npm**: `@modelcontextprotocol/server-filesystem`
- **GitHub**: https://github.com/modelcontextprotocol/servers（monorepo，`src/filesystem/`）
- **运行方式**: `npx`

---

## 核心功能

| 工具 | 用途 |
|------|------|
| `read_text_file` | 读取文本文件 |
| `read_media_file` | 读取图片/音频等媒体文件 |
| `read_multiple_files` | 批量读取多个文件 |
| `write_file` | 写入文件（创建或覆盖） |
| `edit_file` | 编辑文件（含 dry-run diff 预览） |
| `create_directory` | 创建目录 |
| `list_directory` | 列出目录内容 |
| `directory_tree` | 递归查看目录树（JSON 输出） |
| `move_file` | 移动/重命名文件 |
| `search_files` | 按 glob 模式搜索文件 |
| `get_file_info` | 获取文件元信息 |

> 所有操作被严格限制在配置中指定的目录范围内，无法访问范围之外的路径。

---

## 快速上手

```bash
# Mac 本地：只暴露你的工作目录和 kube 配置
npx -y @modelcontextprotocol/server-filesystem ~/work ~/.kube

# 会启动 MCP stdio server，Ctrl+C 退出
```

---

## 配置方式

### Mac 本地

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/Users/liuqianli/work",
        "/Users/liuqianli/.kube"
      ]
    }
  }
}
```

> `args` 末尾可以指定多个允许访问的目录，AI 只能在这些目录内读写。

### 生产环境

生产环境应严格限制目录范围，建议只暴露运维相关的路径：

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/etc/kubernetes",
        "/var/log",
        "/tmp",
        "/opt/deploy"
      ]
    }
  }
}
```

也可以通过环境变量 `ALLOWED_DIRECTORIES`（逗号分隔）来动态指定。

---

## 安全注意事项

- **目录白名单即权限边界**：配置中列出的目录就是 AI 的全部文件访问范围，务必最小化
- **生产环境禁止暴露 `/`、`/etc`、`~/.ssh`** 等敏感路径
- 工具注释了 `readOnlyHint` / `destructiveHint` 标签，支持只读模式的客户端可以利用这些标签限制写操作
- 该包由 Anthropic/ModelContextProtocol 官方维护，推荐优先使用

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "<允许的目录1>",
        "<允许的目录2>"
      ]
    }
  }
}
```
