# MCP Services

这个目录统一维护 MCP 服务源码、启动配置和使用说明。每个 MCP 使用一个独立目录。

## 目录

- `public`：公共 MCP 服务及配置
- `private`：自己维护的私有 MCP 服务及配置
- `profiles.json`：不同客户端启用的 MCP 列表

每个 MCP 目录使用 `README.md` 记录简介、来源和配置方法，使用 `config.json` 保存不含密钥的启动配置。

## 配置规则

- Token、API Key 和密码不得写入仓库。
- 敏感配置使用 `${ENV_NAME}` 环境变量占位。
- 服务源码、配置和说明放在同一个 MCP 目录中。
- 公共和私有 MCP 不得混放。
