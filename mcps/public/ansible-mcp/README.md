# ansible-mcp

Red Hat / Ansible 官方 MCP 服务器。让 AI 助手通过标准化协议使用 Ansible 开发工具。

- **npm**: `@ansible/ansible-mcp-server`
- **容器镜像**: `ghcr.io/ansible/devtools-mcp-server:latest`
- **文档**: https://docs.ansible.com/projects/vscode-ansible/mcp/
- **运行方式**: `npx`（需 Node.js 24+）或 Docker
- **状态**: Technical Preview

> ⚠️ 本目录之前记录的 `bsahane/mcp-ansible`（社区 Python 版）已被官方版取代。官方版由 Red Hat 维护，功能更贴近 Ansible 开发工作流。

---

## 核心功能

| 类别 | 工具 | 说明 |
|------|------|------|
| **信息与文档** | Zen of Ansible、Best Practices、Tool Discovery | 获取 Ansible 设计哲学、最佳实践、工具列表 |
| **环境管理** | Environment Info、Setup Automation、Tool Installation | 检查 Python/Ansible 版本，自动配置 venv 和安装依赖 |
| **项目脚手架** | Playbook Creation、Collection Creation | 按最佳实践生成 Playbook 和 Collection 骨架 |
| **代码质量** | Ansible Lint（含自动修复）、Execution Environment Builder | 代码检查、自动修复、构建执行环境定义 |
| **Playbook 执行** | Ansible Navigator | 智能环境检测 + 容器管理执行 Playbook |

---

## 前置条件

**方式一：npm（需要 Node.js 24+）**

```bash
# Mac 安装 Node.js 24
brew install node@24
# 或
nvm install 24
```

**方式二：Docker（无需 Node.js，推荐）**

```bash
# Mac OrbStack 自带 Docker，无需额外安装
docker --version
```

- Python 3.11+（Docker 镜像已内置）
- Ansible 开发工具（可自动安装）

---

## 配置方式

### 快速上手

```bash
# 验证 MCP server 是否能正常启动（npm 方式）
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"0.1"}}}' \
  | npx -y @ansible/ansible-mcp-server --stdio

# 或 Docker 方式
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"0.1"}}}' \
  | docker run --rm -i ghcr.io/ansible/devtools-mcp-server:latest --stdio

# 响应中应包含 "serverInfo": {"name": "ansible-mcp-server"}
```

### Mac 本地（npm 方式）

```json
{
  "mcpServers": {
    "ansible": {
      "command": "npx",
      "args": [
        "-y",
        "@ansible/ansible-mcp-server",
        "--stdio"
      ],
      "env": {
        "WORKSPACE_ROOT": "/Users/liuqianli/work/ansible"
      }
    }
  }
}
```

### Mac 本地（Docker 方式，推荐）

```json
{
  "mcpServers": {
    "ansible": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "/Users/liuqianli/work/ansible:/workspace",
        "-e", "WORKSPACE_ROOT=/workspace",
        "ghcr.io/ansible/devtools-mcp-server:latest",
        "--stdio"
      ]
    }
  }
}
```

> 将 `/Users/liuqianli/work/ansible` 替换为你的 Ansible 项目路径。如果只需只读访问，volume 挂载加 `:ro`。

### 生产环境（Docker 方式）

```json
{
  "mcpServers": {
    "ansible": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-v", "/home/ops/ansible:/workspace:ro",
        "-e", "WORKSPACE_ROOT=/workspace",
        "ghcr.io/ansible/devtools-mcp-server:latest",
        "--stdio"
      ]
    }
  }
}
```

> `:ro` 表示只读挂载，防止 AI 意外修改 Playbook。如需执行 Playbook，去掉 `:ro`。

### 生产环境（Podman 替代 Docker）

```json
{
  "mcpServers": {
    "ansible": {
      "command": "podman",
      "args": [
        "run", "--rm", "-i",
        "-v", "/home/ops/ansible:/workspace:ro",
        "-e", "WORKSPACE_ROOT=/workspace",
        "ghcr.io/ansible/devtools-mcp-server:latest",
        "--stdio"
      ]
    }
  }
}
```

### Cursor IDE（自动集成）

如果安装了 Ansible VS Code 扩展，MCP server 自动启动，只需在设置中启用：

```json
{
  "ansible.mcpServer.enabled": true
}
```

无需手动配置 `.cursor/mcp.json`。

---

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `WORKSPACE_ROOT` | Ansible 项目根目录路径 | `.`（当前目录） |
| `NODE_OPTIONS` | Node.js 额外参数（仅 npm 方式） | — |

---

## 安全注意事项

- **生产环境用 Docker + 只读挂载 `:ro`**：Playbook 和 Inventory 不会被 AI 意外修改
- **不要让 AI 直接操作 Vault 解密密码**：敏感凭据应在 CI/CD 流水线中注入，而非暴露给 MCP
- `ansible-navigator` 执行 Playbook 时会实际连接目标主机，**确保容器内 SSH key 权限最小化**
- WORKSPACE_ROOT 即权限边界：只挂载需要的 Ansible 项目目录，不要挂载 `/` 或 `~/.ssh`
- 如果不需要执行 Playbook（只需 lint 和 scaffold），挂载一个空目录即可，完全隔离

---

## MCP 客户端接入

### Claude Code

```bash
claude mcp add ansible -- npx -y @ansible/ansible-mcp-server --stdio

# 或 Docker:
claude mcp add ansible -- docker run --rm -i \
  -v /path/to/ansible:/workspace \
  -e WORKSPACE_ROOT=/workspace \
  ghcr.io/ansible/devtools-mcp-server:latest --stdio
```

### Claude Desktop / Cursor / VS Code / Gemini / IBM Bob

```json
{
  "mcpServers": {
    "ansible": {
      "command": "npx",
      "args": ["-y", "@ansible/ansible-mcp-server", "--stdio"],
      "env": {
        "WORKSPACE_ROOT": "/path/to/your/ansible/project"
      }
    }
  }
}
```

### VS Code (Copilot Chat)

```json
{
  "mcp": {
    "servers": {
      "ansible": {
        "command": "npx",
        "args": ["-y", "@ansible/ansible-mcp-server", "--stdio"],
        "env": {
          "WORKSPACE_ROOT": "${workspaceFolder}"
        }
      }
    }
  }
}
```

---

## 与旧社区版的区别

| 维度 | 官方版（本目录） | 旧社区版 (`bsahane/mcp-ansible`) |
|------|:--:|:--:|
| 维护方 | Red Hat | 个人开发者 |
| 安装方式 | npx / Docker | git clone + pip |
| Node.js 依赖 | 24+（npm 方式） | 无（纯 Python） |
| 功能侧重 | 开发质量（lint/scaffold/navigator） | 运维执行（playbook/ad-hoc/vault） |
| 状态 | Technical Preview | 社区维护中 |
