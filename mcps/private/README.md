# Private MCP Services

这个目录用于维护自己编写或不公开的 MCP 服务。每个 MCP 建立独立目录，并至少包含：

- `README.md`：简介、运行方式和配置说明
- `config.json`：不含密钥的客户端启动配置

源码可以直接放在 MCP 目录中。密钥通过环境变量提供，不提交真实值。
