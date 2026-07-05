# jenkins-mcp

通过 Jenkins 官方 MCP Server 插件，把 Jenkins 作业、构建、日志、测试结果、SCM 信息等能力暴露给 MCP 客户端。

- **Jenkins 插件**: `mcp-server`
- **插件页**: https://plugins.jenkins.io/mcp-server/
- **运行方式**: Jenkins 端安装插件，客户端通过 `mcp-remote` 连接 Jenkins 的 Streamable HTTP 端点
- **推荐端点**: `<jenkins-url>/mcp-server/mcp`
- **健康检查**: `<jenkins-url>/mcp-health`

---

## 前置条件

- Jenkins 版本 `2.533` 或更高
- Jenkins 已安装 `mcp-server` 插件
- Jenkins 用户已生成 API Token
- 本机可使用 `npx`

---

## 配置文件

本目录提供两个模板：

- `config.json`: MCP 客户端配置模板，不包含真实密钥
- `jenkins-mcp.env.example`: 本地环境变量模板

先准备环境变量：

```bash
cp mcps/public/jenkins-mcp/jenkins-mcp.env.example ~/.codex/mcp/jenkins-mcp.env
chmod 600 ~/.codex/mcp/jenkins-mcp.env
```

然后生成 Basic Auth 凭据：

```bash
echo -n "jenkins_username:jenkins_api_token" | base64
```

把 `~/.codex/mcp/jenkins-mcp.env` 填成：

```bash
JENKINS_MCP_URL="https://your-jenkins.example.com/mcp-server/mcp"
JENKINS_MCP_BASIC_AUTH_B64="base64(username:api_token)"
```

---

## Codex 接入

Codex 当前可以通过本地 stdio 包装脚本接入远程 Jenkins MCP：

```bash
codex mcp add jenkins -- ~/.codex/mcp/jenkins-mcp-remote.sh
```

包装脚本读取 `~/.codex/mcp/jenkins-mcp.env`，再使用 `npx -y mcp-remote@latest` 转接 Jenkins 的 Streamable HTTP 端点。

已安装后可检查：

```bash
codex mcp get jenkins
codex mcp list
```

---

## 可用能力

Jenkins 官方插件内置的常用工具包括：

| 工具 | 用途 |
| ---- | ---- |
| `getJobs` | 分页列出 Jenkins jobs |
| `getJob` | 获取指定 job |
| `triggerBuild` | 触发构建，支持参数化构建 |
| `getQueueItem` | 查询队列项 |
| `getBuild` | 查询指定构建或最近一次构建 |
| `getBuildLog` | 分页读取构建日志 |
| `searchBuildLog` | 搜索构建日志 |
| `getTestResults` | 查询测试结果 |
| `getJobScm` | 查询 job 的 SCM 配置 |
| `getBuildScm` | 查询构建的 SCM 信息 |
| `getBuildChangeSets` | 查询构建变更集 |
| `findJobsWithScmUrl` | 按 Git 仓库 URL 查找 job |
| `whoAmI` | 查询当前认证用户 |
| `getStatus` | 查询 Jenkins 健康与就绪状态 |

---

## 安全注意事项

- 不要把 Jenkins API Token 或 base64 后的 Basic Auth 写入仓库
- base64 不是加密，需要按明文凭据保护
- 生产环境建议使用权限收敛的 Jenkins 用户
- 如只需要查看构建和日志，优先授予只读权限
- 触发构建、Replay、更新构建描述等能力可能改变 Jenkins 状态，使用前需要确认权限边界
