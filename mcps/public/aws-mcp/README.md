# aws-mcp

通过 MCP 协议操作 AWS 云资源。本目录推荐 `@yawlabs/aws-mcp`，功能全面、社区活跃。

- **npm**: `@yawlabs/aws-mcp`
- **GitHub**: https://github.com/YawLabs/aws-mcp
- **运行方式**: `npx`

> 官方方案 `mcp-proxy-for-aws`（PyPI/uvx）提供 SigV4 认证代理，但需要额外配置 AWS MCP endpoint。`@yawlabs/aws-mcp` 开箱即用，更省事。

---

## 核心功能

| 工具 | 用途 |
|------|------|
| `aws_call` | 代理 `aws` CLI，覆盖全量 AWS API |
| `aws_resource_list` / `aws_resource_read` / `aws_resource_create` / `aws_resource_update` / `aws_resource_delete` | 通过 Cloud Control API 做资源 CRUD（含 dry-run diff） |
| `aws_multi_region` | 跨多区域并行查询 |
| `aws_iam_simulate` | 预检 IAM 权限，确认操作是否会被拒绝 |
| `aws_docs_search` / `aws_docs_read` | 实时搜索/阅读 AWS 文档 |
| `aws_script` | JS 沙箱，编写批量自动化脚本 |

---

## 前置条件

- **AWS CLI v2** 已安装：`brew install awscli`
- **AWS 凭据**已配置（SSO 或 IAM User）：
  ```bash
  aws configure sso    # SSO
  # 或
  aws configure        # IAM User (Access Key)
  ```
- Node.js >= 22

---

## 配置方式

### Mac 本地

```json
{
  "mcpServers": {
    "aws": {
      "command": "npx",
      "args": ["-y", "@yawlabs/aws-mcp@latest"],
      "env": {
        "AWS_PROFILE": "default",
        "AWS_REGION": "us-east-1"
      }
    }
  }
}
```

多 profile 切换：
```json
{
  "mcpServers": {
    "aws": {
      "command": "npx",
      "args": ["-y", "@yawlabs/aws-mcp@latest"],
      "env": {
        "AWS_PROFILE": "prod",
        "AWS_REGION": "ap-southeast-1"
      }
    }
  }
}
```

### 生产环境

生产环境建议使用**只读 IAM Policy 的凭据**，避免 AI 操作生产资源：

```json
{
  "mcpServers": {
    "aws": {
      "command": "npx",
      "args": ["-y", "@yawlabs/aws-mcp@latest"],
      "env": {
        "AWS_PROFILE": "ops-readonly",
        "AWS_REGION": "ap-southeast-1"
      }
    }
  }
}
```

对应的 IAM Policy 示例（只读）：
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:Describe*",
        "ecs:Describe*",
        "eks:Describe*",
        "s3:List*",
        "s3:Get*",
        "rds:Describe*",
        "cloudwatch:Get*",
        "cloudwatch:List*",
        "iam:Get*",
        "iam:List*",
        "iam:Simulate*"
      ],
      "Resource": "*"
    }
  ]
}
```

---

## 安全注意事项

- **生产环境强烈建议只读 IAM Policy**，通过 `aws_iam_simulate` 可以预检权限
- SSO profile 过期时 MCP 会引导重新登录
- 不要给 AI 使用 `AdministratorAccess` 或 `PowerUserAccess` 的 profile
- 如使用 `aws_resource_delete`，务必先用 dry-run diff 确认影响范围

---

## MCP 客户端接入

```json
{
  "mcpServers": {
    "aws": {
      "command": "npx",
      "args": ["-y", "@yawlabs/aws-mcp@latest"],
      "env": {
        "AWS_PROFILE": "ops-readonly",
        "AWS_DEFAULT_REGION": "ap-southeast-1"
      }
    }
  }
}
```

---

## 备选方案

如果只需要做 AWS API 代理（不需要 Cloud Control API 等高级功能），可以用官方方案：

```json
{
  "mcpServers": {
    "aws-proxy": {
      "command": "uvx",
      "args": ["mcp-proxy-for-aws@1.6.2", "https://<your-mcp-endpoint>.us-east-1.amazonaws.com/mcp"],
      "env": {
        "AWS_PROFILE": "default",
        "AWS_REGION": "us-east-1"
      }
    }
  }
}
```
