# terraform-mcp

HashiCorp 官方 Terraform MCP 服务器。查询 Terraform Registry、管理 HCP Terraform / Terraform Enterprise 工作空间。

- **GitHub**: https://github.com/hashicorp/terraform-mcp-server（⭐ 1.4k）
- **运行方式**: Docker（官方镜像 `hashicorp/terraform-mcp-server:1.0.0`）

> 有一个已归档的旧 npm 版 `terraform-mcp-server`（thrashr888），不再维护，请用官方版。

---

## 核心功能

| 工具集 | 功能 | 说明 |
|--------|------|------|
| **registry** | 搜索 Provider / Module / Policy | 公共 Terraform Registry |
| **terraform** | 工作空间 CRUD、Run 管理、变量管理、State 查看 | HCP Terraform / TFE 操作 |

---

## 前置条件

- **Docker** 或 **Podman** 运行环境
- HCP Terraform / Terraform Enterprise 账号
  - Team API Token：`Settings → API Tokens` → 创建
  - 或 User Token：`User Settings → Tokens` → 创建

---

## 配置方式

### Mac 本地 / 生产环境（Stdio 模式）

```json
{
  "mcpServers": {
    "terraform": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "-e", "TFE_TOKEN",
        "hashicorp/terraform-mcp-server:1.0.0"
      ],
      "env": {
        "TFE_TOKEN": "${TFE_API_TOKEN}",
        "TFE_ADDRESS": "https://app.terraform.io"
      }
    }
  }
}
```

> `-i` 标志是 stdio 模式必需的（MCP 通过 stdin/stdout 通信）。

### 自托管 Terraform Enterprise

```json
{
  "env": {
    "TFE_TOKEN": "${TFE_API_TOKEN}",
    "TFE_ADDRESS": "https://tfe.internal.example.com",
    "TFE_SKIP_TLS_VERIFY": "false"
  }
}
```

### 启用特定工具集

```json
{
  "args": [
    "run",
    "--rm",
    "-i",
    "-e", "TFE_TOKEN",
    "hashicorp/terraform-mcp-server:1.0.0",
    "--toolsets", "registry,terraform"
  ]
}
```

> 如果只需要查询 Registry 文档（不操作 TFE），可设为 `--toolsets registry`。

---

## 安全注意事项

- **TFE Token 务必只给最小权限**：Team Token 的权限受 Team 的 Workspace 权限限制
- 生产环境建议用 Team API Token（而不是 User Token），便于权限管理和审计
- 不要给 `manage workspaces` 以外的 admin 权限
- 如果不需要变更操作，Terraform 端的 Workspace 权限设为 `Read`
- 禁用 TFE 操作：`--toolsets registry`（仅查询公共 Registry）

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "terraform": {
      "command": "docker",
      "args": [
        "run",
        "--rm",
        "-i",
        "-e", "TFE_TOKEN",
        "hashicorp/terraform-mcp-server:1.0.0"
      ],
      "env": {
        "TFE_TOKEN": "${TFE_API_TOKEN}",
        "TFE_ADDRESS": "https://app.terraform.io"
      }
    }
  }
}
```
