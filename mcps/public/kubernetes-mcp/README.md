# kubernetes-mcp

通过 MCP 协议查询和管理 Kubernetes 集群资源。本目录推荐使用 **Red Hat / containers 组织** 维护的版本，功能最全面。

- **npm**: `kubernetes-mcp-server`
- **GitHub**: https://github.com/containers/kubernetes-mcp-server（⭐ ~1,700）
- **运行方式**: `npx`

> 另有两个备选：`mcp-server-kubernetes`（Flux159，TypeScript）和 `@strowk/mcp-k8s`（Go）。本目录以 containers 版为准。

---

## 核心功能

| 工具集 | 包含的典型工具 | 说明 |
|--------|-------------|------|
| **core** | Pod/Deployment/Service/ConfigMap 等全部 K8s 资源的 CRUD | 核心 K8s 操作 |
| **config** | kubeconfig 上下文/集群切换 | 多集群管理 |
| **helm** | install / list / uninstall | Helm 操作 |
| **tekton** | Pipeline / Task 管理 | CI/CD |
| **kubevirt** | 虚拟机管理 | 虚拟化 |
| **kiali** | 服务网格可视化 | Istio |

关键特性：
- **原生 Go 实现**，不依赖 kubectl/helm 命令行
- **只读模式** `--read-only`：禁止任何写操作
- **禁用破坏性操作** `--disable-destructive`：屏蔽 delete/patch 等
- **多集群支持**：自动读取 kubeconfig 中的全部 context
- 支持 **TOML 配置文件** 进行细粒度控制

---

## 快速上手

```bash
# Mac 本地 OrbStack K8s，只读模式
npx -y kubernetes-mcp-server@latest --read-only

# 启动后 AI 可通过 MCP 查询 Pod/Deployment/Service 等资源
```

---

## 配置方式

### Mac 本地（OrbStack K8s）

本地 OrbStack 的 kubeconfig 通常已配置好，直接使用：

```json
{
  "mcpServers": {
    "kubernetes": {
      "command": "npx",
      "args": [
        "-y",
        "kubernetes-mcp-server@latest",
        "--read-only"
      ]
    }
  }
}
```

> `--read-only` 确保本地调试时不会误操作集群。

### 生产环境

**建议配置：只读模式 + 禁用破坏性操作**

```json
{
  "mcpServers": {
    "kubernetes": {
      "command": "npx",
      "args": [
        "-y",
        "kubernetes-mcp-server@latest",
        "--read-only",
        "--disable-destructive",
        "--toolsets", "core,config,helm"
      ],
      "env": {
        "KUBECONFIG": "/home/ops/.kube/config"
      }
    }
  }
}
```

**如果需要允许特定变更操作**（如 rollout restart），去掉 `--read-only` 但保留 `--disable-destructive`，再在 TOML 配置文件中精确放开需要的操作：

```toml
# kubernetes-mcp.toml
read_only = false
disable_destructive = false
toolsets = ["core", "config", "helm"]

# 白名单：只允许特定资源的特定操作
[[resource_filters]]
api_group = "apps"
resource = "deployments"
verbs = ["get", "list", "describe", "update"]

[[resource_filters]]  
api_group = "apps"
resource = "deployments"
sub_resource = "scale"
verbs = ["get", "update"]
```

---

## 多集群切换

如果你的 kubeconfig 中有多个 context，AI 可以通过工具直接切换：

```
// 列出所有 contexts
{ "tool": "kubectl_context", "params": {} }

// 切换到生产集群
{ "tool": "kubectl_context", "params": { "name": "prod-cluster" } }
```

不想暴露某些集群时，使用 `--allowed-contexts`（仅 `@strowk/mcp-k8s` 支持）或在 kubeconfig 中移除敏感 context。

---

## 安全注意事项

- **生产环境必须启用 `--read-only` 或 `--disable-destructive`**
- kubeconfig 中的凭据会间接暴露给 AI（AI 能看到 context 名称），确保使用最小权限的 service account
- 配合 `allowedRemotePaths` 限制文件上传路径，防止 kubeconfig 被覆盖
- 如果需要允许部分写操作，通过 TOML 配置文件的 `resource_filters` 做细粒度控制

---

## MCP 客户端接入（推荐只读配置）

```json
{
  "mcpServers": {
    "kubernetes": {
      "command": "npx",
      "args": [
        "-y",
        "kubernetes-mcp-server@latest",
        "--read-only",
        "--disable-destructive"
      ]
    }
  }
}
```
