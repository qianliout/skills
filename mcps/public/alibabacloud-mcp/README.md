# alibabacloud-mcp

阿里云官方运维 MCP 服务器。覆盖 ECS、VPC、RDS、OSS、Cloud Monitor 等核心服务。

- **PyPI**: `alibaba-cloud-ops-mcp-server`
- **GitHub**: https://github.com/aliyun/alibaba-cloud-ops-mcp-server
- **运行方式**: `uvx`（Python）或 Docker

---

## 核心功能

| 服务 | 典型工具 | 说明 |
|------|---------|------|
| **ECS** | 创建/启动/停止/重启/删除实例、执行远程命令、查看镜像/安全组/可用区 | 云服务器全生命周期 |
| **VPC** | 查看 VPC、VSwitch | 网络资源查询 |
| **RDS** | 列举/启动/停止/重启实例 | 数据库管理 |
| **OSS** | 列举/创建/删除 Bucket、查看对象 | 对象存储 |
| **Cloud Monitor** | CPU、内存、磁盘指标查询 | 云监控 |
| **应用部署** | 自动打包上传 OSS → 部署到 ECS → 跟踪状态 | 一键部署 |
| **LOCAL 工具** | `AnalyzeDeployStack`、`RunShellScript`、`ListDirectory` | 本地项目分析 |

---

## 前置条件

- **uv** 已安装（Python 包管理器）：
  ```bash
  brew install uv
  # 或
  pip install uv
  ```
- **阿里云 AccessKey**（建议使用 RAM 子账号，最小权限）

---

## 配置方式

### Mac 本地 / 生产环境

```json
{
  "mcpServers": {
    "alibaba-cloud-ops-mcp-server": {
      "timeout": 600,
      "command": "uvx",
      "args": [
        "alibaba-cloud-ops-mcp-server@latest"
      ],
      "env": {
        "ALIBABA_CLOUD_ACCESS_KEY_ID": "<Your Access Key ID>",
        "ALIBABA_CLOUD_ACCESS_KEY_SECRET": "<Your Access Key Secret>"
      }
    }
  }
}
```

> `timeout: 600` 是因为部署类操作（上传 OSS + 部署 ECS）耗时较长。

### 安全配置：使用 RAM 子账号（推荐）

在阿里云 RAM 控制台创建子账号，授予**只读 + 必要运维权限**：

```json
{
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:Describe*",
        "ecs:StartInstance",
        "ecs:StopInstance",
        "ecs:RebootInstance",
        "vpc:Describe*",
        "rds:Describe*",
        "rds:RestartDBInstance",
        "oss:ListBuckets",
        "oss:GetBucket*",
        "oss:PutObject",
        "cms:Describe*"
      ],
      "Resource": "*"
    }
  ],
  "Version": "1"
}
```

---

## 安全注意事项

- **AccessKey 不要写在配置文件中**：使用环境变量引用，或通过密钥管理服务注入
- 建议使用 RAM 子账号 + 自定义权限策略，**不要直接用主账号 AK**
- 生产环境去掉 `ecs:DeleteInstance`、`oss:DeleteBucket` 等破坏性权限
- 定期轮换 AccessKey
- `LOCAL` 工具组会在 MCP server 所在机器上执行，注意本地文件安全

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "alibaba-cloud-ops-mcp-server": {
      "timeout": 600,
      "command": "uvx",
      "args": ["alibaba-cloud-ops-mcp-server@latest"],
      "env": {
        "ALIBABA_CLOUD_ACCESS_KEY_ID": "${ALIBABA_AK_ID}",
        "ALIBABA_CLOUD_ACCESS_KEY_SECRET": "${ALIBABA_AK_SECRET}"
      }
    }
  }
}
```
