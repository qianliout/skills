# Security Checklist

在代码审查涉及安全、并发和运行时风险时使用。

## Input and Output Safety

- XSS、SQL/NoSQL/command 注入、SSRF、路径穿越。
- 未校验的模板输出、HTML 注入、用户输入拼接命令或查询。
- 不安全的对象合并、反序列化和文件路径处理。

## Auth and Access Control

- 缺少认证、授权、租户隔离或资源归属校验。
- 信任客户端传入的角色、用户 ID、权限标记。
- 新增接口没有权限保护或错误地复用旧权限。

## Secrets and Sensitive Data

- 密钥、token、PII 是否出现在代码、配置、日志或报错中。
- 默认配置是否暴露内部实现细节。
- 错误信息是否泄漏堆栈、SQL、内部地址或敏感字段。

## Runtime Risks

- 是否存在无限制循环、超大内存缓冲、缺少 timeout 或 rate limit 的外部调用。
- 是否在请求路径执行阻塞操作或高成本计算。
- 是否存在资源耗尽风险，如连接、文件句柄、goroutine、线程或缓存无上限增长。

## Race Conditions

- 共享状态是否缺少同步保护。
- 是否存在 check-then-act、read-modify-write 之类的竞态模式。
- 并发更新数据库时是否缺少事务、乐观锁或原子操作。
- 分布式场景下是否缺少幂等、排序、锁或缓存失效策略。

## Review Questions

- 两个请求同时命中这段代码会发生什么。
- 这个操作是否原子，是否可能被打断。
- 共享状态在哪里，谁会并发访问它。
- 失败或重试时，是否会产生越权、重复写入或状态错乱。
