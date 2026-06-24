# ssh-mcp-server 配置说明

基于 [ssh-mcp-server](https://github.com/classfang/ssh-mcp-server) 的 SSH MCP 服务器配置。

通过 MCP 协议让 AI 助手安全地在远程服务器上执行 SSH 命令，而无需将 SSH 凭据暴露给 AI 模型。

## 目录结构

```
mcps/public/ssh-mcp/
├── README.md                 # 本文件
├── ssh-config.json           # Mac 本地 OrbStack K8s 集群配置（4 个节点）
└── ssh-config.prod.json      # 生产环境配置模板（含命令白名单）
```

## 前置条件

- **Node.js >= 18**（已满足：v22.21.1）
- **npm/npx** 可用
- SSH 密钥或密码凭据

---

## 一、Mac 本地环境（OrbStack K8s）

### 背景

本地 K8s 集群运行在 OrbStack 虚拟机中。日常可以直接 `ssh k8s-master-01` 连接，这是通过 `~/.ssh/config` 中配置的 OrbStack ProxyCommand 实现的。

但 **ssh-mcp-server 使用的是 ssh2 库（Node.js 原生 SSH 实现），不支持 OpenSSH 的 ProxyCommand**。所以不能直接传 `--host k8s-master-01` 复用 SSH config。

### 解决方案：直连 OrbStack SSH 端口

OrbStack 在 `127.0.0.1:32222` 暴露了一个统一的 SSH 入口，通过**用户名来路由到不同的 VM**。ssh2 库可以直接 TCP 连接该端口。

| SSH config 别名        | 实际连接参数                                          |
|------------------------|------------------------------------------------------|
| `k8s-master-01`        | `127.0.0.1:32222` user=`k8s-master-01`               |
| `k8s-master-01-root`   | `127.0.0.1:32222` user=`root@k8s-master-01`          |
| `k8s-worker-01`        | `127.0.0.1:32222` user=`k8s-worker-01`               |
| `k8s-worker-01-root`   | `127.0.0.1:32222` user=`root@k8s-worker-01`          |

所有节点共用同一个 SSH key：`~/.orbstack/ssh/id_ed25519`

### 方式一：配置文件（推荐，多节点管理）

`ssh-config.json` 已预配置了 4 个节点。在 MCP 客户端配置中引用它：

```json
{
  "mcpServers": {
    "ssh-mcp-server": {
      "command": "npx",
      "args": [
        "-y",
        "@fangjunjie/ssh-mcp-server",
        "--config-file", "mcps/public/ssh-mcp/ssh-config.json"
      ]
    }
  }
}
```

> 路径请根据实际项目根目录调整，MCP 客户端的工作目录通常是项目根目录。

调用时通过 `connectionName` 选择节点：

```json
// 在 k8s-master-01 上执行
{ "tool": "execute-command", "params": { "cmdString": "kubectl get pods -A", "connectionName": "k8s-master-01" } }

// 在 k8s-master-01 上以 root 执行
{ "tool": "execute-command", "params": { "cmdString": "systemctl status containerd", "connectionName": "k8s-master-01-root" } }

// 列出所有可用服务器
{ "tool": "list-servers", "params": {} }
```

### 方式二：命令行参数（单节点）

如果只需要连一个节点，也可以直接用参数：

```json
{
  "mcpServers": {
    "ssh-mcp-server": {
      "command": "npx",
      "args": [
        "-y",
        "@fangjunjie/ssh-mcp-server",
        "--host", "127.0.0.1",
        "--port", "32222",
        "--username", "k8s-master-01",
        "--privateKey", "/Users/liuqianli/.orbstack/ssh/id_ed25519"
      ]
    }
  }
}
```

### 本地测试

在正式接入 MCP 客户端前，可以先在终端里手动测试：

```bash
npx -y @fangjunjie/ssh-mcp-server \
  --host 127.0.0.1 \
  --port 32222 \
  --username k8s-master-01 \
  --privateKey ~/.orbstack/ssh/id_ed25519
```

启动后会看到 MCP stdio server 的启动日志，确认连接成功即可 `Ctrl+C` 退出。

---

## 二、生产环境配置

### 配置文件

`ssh-config.prod.json` 是生产环境模板，包含两类节点：

- **只读节点** (`prod-master-01`)：仅允许 kubectl get/describe/logs 等查看操作
- **运维节点** (`prod-master-01-root`)：允许 restart、rollout restart 等变更操作

### 使用前修改

```bash
# 1. 拷贝模板
cp ssh-config.prod.json ssh-config.prod.actual.json

# 2. 编辑实际值
vim ssh-config.prod.actual.json
```

必改字段：
- `host` — 生产环境 Master 节点 IP 或主机名
- `username` — SSH 用户名
- `privateKey` — SSH 私钥路径（建议使用专用密钥，不要复用个人密钥）

### 安全配置说明

生产环境**强烈建议**配置以下限制：

#### 命令白名单（whitelist）

白名单使用正则表达式匹配完整命令字符串，多个模式用逗号分隔：

```json
"whitelist": "^kubectl get .*,^kubectl describe .*,^kubectl logs .*,..."
```

| 权限级别 | 允许的操作 | 适用场景 |
|---------|-----------|---------|
| 只读 | `kubectl get/describe/logs/top`、`helm list/status/history`、`cat`、`df`、`ps`、`systemctl status`、`journalctl` | 日常排查 |
| 受控变更 | 只读 + `kubectl rollout restart`、`systemctl restart` | 常规运维 |
| 完全放权 | 不设白名单 | **不推荐**，风险极高 |

#### 远端路径限制（allowedRemotePaths）

限制 upload/download 可访问的远端路径：

```json
"allowedRemotePaths": "/tmp,/var/log"
```

未配置时，任意远端路径都可访问（会打印警告），攻击者可能通过 prompt 注入读取 `~/.ssh/authorized_keys` 等敏感文件。

#### 其他安全建议

- 使用**专用 SSH 密钥**，不要复用个人日常密钥
- 若需经过堡垒机，考虑 `transportMode: "shell"` + `commandTemplate`
- 部署 MCP server 的机器本身需要加固，SSH 私钥在内存中

---

## 三、接入 MCP 客户端

### Claude Code

项目根目录创建或编辑 `.mcp.json`：

```json
{
  "mcpServers": {
    "ssh-mcp-server": {
      "command": "npx",
      "args": [
        "-y",
        "@fangjunjie/ssh-mcp-server",
        "--config-file", "mcps/public/ssh-mcp/ssh-config.json"
      ],
      "env": {
        "SSH_MCP_2FA_CODE": "${2FA_CODE}"
      }
    }
  }
}
```

### Cursor

编辑 `.cursor/mcp.json`（格式同上）。

### VS Code / Copilot

编辑 `.vscode/mcp.json`（格式同上）。

> **注意**：`args` 数组中的每个参数和值必须是独立元素，不要写成 `"--host 127.0.0.1"`。

---

## 四、多因素认证（2FA）

当目标服务器需要 2FA 时，启用 `tryKeyboard` 并通过环境变量 `SSH_MCP_2FA_CODE` 提供验证码：

```json
{
  "mcpServers": {
    "ssh-mcp-server": {
      "command": "npx",
      "args": [
        "-y",
        "@fangjunjie/ssh-mcp-server",
        "--config-file", "mcps/public/ssh-mcp/ssh-config.prod.json"
      ],
      "env": {
        "SSH_MCP_2FA_CODE": "<动态验证码>"
      }
    }
  }
}
```

配置文件中对应节点需添加 `"tryKeyboard": true`。

---

## 五、可用工具

| 工具 | 用途 |
|------|------|
| `execute-command` | 在远程服务器上执行命令 |
| `upload` | 上传本地文件到远程服务器 |
| `download` | 从远程服务器下载文件 |
| `list-servers` | 列出所有已配置的 SSH 服务器 |

`upload`/`download` 仅在 `transportMode: "exec"`（默认）下可用。

---

## 六、命令白名单推荐

### K8s 只读排查

```
^kubectl get .*,^kubectl describe .*,^kubectl logs .*,^kubectl top .*,^kubectl cluster-info.*,^kubectl api-resources.*,^kubectl explain .*,^kubectl auth can-i .*,^helm list.*,^helm status.*,^helm history.*,^cat .*,^less .*,^tail .*,^head .*,^df.*,^free.*,^uptime.*,^top -b.*,^ps aux.*,^netstat.*,^ss.*,^systemctl status.*,^journalctl.*,^du .*,^find .*,^wc .*,^grep .*,^awk .*,^sort .*,^uniq .*
```

### K8s 常规运维（含受控变更）

只读白名单基础上追加：

```
^kubectl rollout restart .*,^kubectl scale .*,^kubectl cordon .*,^kubectl uncordon .*,^kubectl drain .*,^systemctl restart (kubelet|containerd|docker).*,^systemctl daemon-reload.*
```

### 黑名单（最小防护）

如果不方便维护白名单，至少加黑名单挡住破坏性操作：

```
^rm -rf .*,^dd if=.*,^mkfs.*,^shutdown.*,^reboot.*,^halt.*,^poweroff.*,^kubectl delete (namespace|cluster).*,^iptables -F.*,^> /dev/sda.*
```

---

## 七、常见问题

### Q: 本地 OrbStack 连接失败？
确认 OrbStack 正在运行，且端口可达：
```bash
ssh -o ProxyCommand=none -p 32222 k8s-master-01@127.0.0.1 -i ~/.orbstack/ssh/id_ed25519 hostname
```
应返回 `k8s-master-01`。

### Q: 生产环境 shell 模式何时使用？
当出现以下情况时切换到 `"transportMode": "shell"`：
- SSH 登录后有 banner/profile 需要加载才能执行命令
- 通过堡垒机/跳板机连接
- exec 模式执行命令返回错误

注意 shell 模式**不支持 upload/download**。

### Q: 如何安全存储密码？
不要在配置文件中明文写密码。优先使用私钥认证。如果必须用密码，可通过环境变量传递：
```json
{
  "args": ["--password", "${SSH_PASSWORD}"],
  "env": { "SSH_PASSWORD": "实际密码" }
}
```

---

## 参考

- GitHub: https://github.com/classfang/ssh-mcp-server
- NPM: https://www.npmjs.com/package/@fangjunjie/ssh-mcp-server
