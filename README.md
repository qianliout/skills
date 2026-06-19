# skills

这个仓库用于统一维护你的开发工具能力栈，包含三类内容：

- 本仓库自己维护的本地 `skill`
- 需要批量安装的社区 `skill`
- 需要批量同步的 `MCP` 配置模板

仓库目标很简单：

- 只保留一个统一入口脚本
- 本地能力和外部能力分开维护
- 配置尽量声明式，少改脚本，多改清单
- 默认写入全局配置，避免在仓库根目录产生运行时文件
- 仍然支持显式写入项目级配置

## 适用场景

- 你有一批自己长期维护的 `skill`
- 你同时依赖社区公共 `skill`
- 你希望把常用 `MCP` 作为标准工具栈复用到不同项目
- 你希望新机器或新项目能快速完成初始化

## 目录结构

```text
skills/
├── bootstrap-agent-stack.sh
├── agent-stack/
│   ├── link-local-skills.sh
│   ├── install-community-skills.sh
│   ├── sync-mcp-config.sh
│   └── manifests/
│       ├── community-skills.txt
│       └── mcp-servers.json
├── alibabacloud-sysom-diagnosis/
├── go/
├── go-api-layer/
├── go-code-style/
├── go-comment-style/
├── go-gin-openapi-json/
├── go-logging/
├── go-model-hierarchy/
├── go-query-dal/
├── go-service-layer/
├── go-test-writer/
└── md-style/
```

目录约定如下：

- 根目录的每个本地 `skill` 都是一个独立目录，并且必须包含 `SKILL.md`
- 根目录只暴露一个入口脚本 `bootstrap-agent-stack.sh`
- `agent-stack/` 存放内部实现脚本和清单
- `agent-stack/manifests/community-skills.txt` 维护社区 `skill` 列表
- `agent-stack/manifests/mcp-servers.json` 维护标准 `MCP` 配置模板
- `.mcp.json` 这类运行时文件不建议常驻仓库根目录

## 快速开始

先给脚本可执行权限：

```bash
chmod +x bootstrap-agent-stack.sh agent-stack/*.sh
```

先看一遍将要执行的动作：

```bash
./bootstrap-agent-stack.sh --dry-run
```

正式执行：

```bash
./bootstrap-agent-stack.sh
```

默认行为如下：

- 同步本仓库里的本地 `skill`
- 安装清单中的社区 `skill`
- 生成或合并全局 `~/.claude/mcp.json`

## 常用命令

查看帮助：

```bash
./bootstrap-agent-stack.sh --help
```

只同步本地 `skill`：

```bash
./bootstrap-agent-stack.sh --no-community-skills --no-mcp
```

只安装社区 `skill`：

```bash
./bootstrap-agent-stack.sh --no-local-skills --no-mcp
```

只同步 `MCP` 配置：

```bash
./bootstrap-agent-stack.sh --no-local-skills --no-community-skills
```

写入全局 `Claude` 配置：

```bash
./bootstrap-agent-stack.sh --global
```

显式写入当前项目 `.mcp.json`：

```bash
./bootstrap-agent-stack.sh --project
```

## 脚本说明

`bootstrap-agent-stack.sh` 是唯一对外入口，负责串联以下三个动作：

- `agent-stack/link-local-skills.sh`
- `agent-stack/install-community-skills.sh`
- `agent-stack/sync-mcp-config.sh`

三个内部脚本分别负责：

- 同步本仓库的本地 `skill` 到 `~/.codex/skills`、`~/.cursor/skills`、`~/.trae/skills`、`~/.zed/skills`、`~/.warp/skills`、`~/.reasonix/skills`
- 按清单批量安装社区 `skill`，默认只安装到 `codex`、`trae`、`cursor`、`zed`、`warp`、`reasonix`
- 把标准 `MCP` 配置合并到目标配置文件

## 维护方式

推荐把维护动作分成三层：

### 第一层：维护你自己的本地 skill

适合放在仓库根目录，保持一个目录一个 `skill`：

- `go`
- `go-api-layer`
- `go-service-layer`
- `md-style`

维护规则：

- 每个目录都必须有 `SKILL.md`
- 需要 agent 适配时放到 `agents/`
- 需要参考资料时放到 `references/`
- 一个 `skill` 只关心一类稳定能力，不要做成大杂烩

### 第二层：维护公共 skill 清单

社区 `skill` 不建议直接拷贝到仓库里，而是通过清单声明：

- 文件位置：`agent-stack/manifests/community-skills.txt`

维护规则：

- 一行一个安装项
- 优先写全量包名，例如 `owner/repo@skill`
- 短名可以使用，但脚本会在安装前自动解析为真实安装坐标
- 只有在确认稳定且长期使用时才加入清单
- 临时尝鲜的公共 `skill` 不要直接进主清单

### 第三层：维护 MCP 标准配置

`MCP` 更适合维护“模板”而不是维护真实机器配置：

- 文件位置：`agent-stack/manifests/mcp-servers.json`

维护规则：

- 仓库里只放通用模板
- 机器相关路径用占位值
- API Key 用占位值或环境变量，不要提交真实密钥
- 优先用全局 `mcp.json`
- 只有确实需要项目隔离时才显式使用 `.mcp.json`

## 推荐的维护流程

平时新增或调整能力时，建议按下面的顺序做：

1. 如果是你自己定义的新能力，先新增一个本地 `skill` 目录
1. 如果是外部公共能力，先评估是否值得进清单
1. 如果是工具接入，先写到 `mcp-servers.json` 模板
1. 每次改完先执行一次 `./bootstrap-agent-stack.sh --dry-run`
1. 确认无误后再执行正式同步

## 我建议你这样组织代码

从维护成本和长期可控性看，这个仓库最适合按“能力来源”组织，而不是按“工具名字”组织。

推荐原则如下：

- 本地 `skill` 和社区 `skill` 分开
- `skill` 和 `MCP` 分开
- 脚本和清单分开
- 模板和真实运行配置分开
- 单入口对外，内部多脚本分工

当前结构已经基本符合这个方向，但后续可以继续往下面演进。

### 当前结构为什么是合理的

- 根目录本地 `skill` 直观，方便你直接编辑
- `agent-stack/` 收纳了所有“安装和同步逻辑”
- 清单文件集中，后续加减内容不需要频繁改脚本
- 外层只有一个入口，使用成本低

### 后续建议的演进方向

如果未来仓库继续变大，我建议再拆成四个逻辑区：

- `skills-local/`
- `skills-community/`
- `mcp/`
- `scripts/`

更具体一点，可以演进成这样：

```text
skills/
├── bootstrap-agent-stack.sh
├── scripts/
│   └── agent-stack/
├── manifests/
│   ├── community-skills.txt
│   ├── mcp-servers.json
│   └── profiles/
├── skills-local/
│   ├── go/
│   ├── go-api-layer/
│   └── md-style/
└── docs/
```

这个结构更适合下面这些场景：

- 本地 `skill` 数量继续增加
- 需要区分不同角色的能力包
- 需要多套 `MCP` 配置模板
- 需要团队共享而不是只给自己用

## 推荐的分层策略

为了让这个仓库长期可维护，我建议你把内容分成四层：

### 核心层

这里放你最稳定、最高频、最有个人方法论沉淀的能力：

- 你自己维护的本地 `skill`
- 必装的基础 `MCP`
- 单入口脚本

### 标准层

这里放团队或自己长期复用的公共能力：

- 社区 `skill` 主清单
- 通用 `MCP` 模板

### 实验层

这里放不稳定、试用中、可能会删掉的内容：

- 新发现但还没验证的社区 `skill`
- 还不确定是否长期使用的 `MCP`
- 临时脚本

建议未来单独加一个文件：

- `agent-stack/manifests/community-skills.experimental.txt`

### 环境层

这里放机器相关和项目相关配置，不建议进仓库：

- 本机真实路径
- API Key
- 特定项目覆盖配置

## 关于 skill 和 MCP 的维护边界

建议用下面的标准判断一个能力应该放哪：

放进本地 `skill`：

- 这是你自己的工作方法
- 它依赖你的项目规范
- 它的价值主要来自提示词和流程设计

放进社区 `skill` 清单：

- 它已经在社区成熟可用
- 你不想自己维护实现
- 你只是复用，不需要深度定制

放进 `MCP` 模板：

- 它本质是工具接入
- 它需要文件、浏览器、设计工具、数据库等外部能力
- 它更像运行时配置，而不是提示词能力

## 建议补充的文件

如果你准备长期维护这个仓库，我建议后续再补几个文件：

- `.gitignore`
- `docs/architecture.md`
- `docs/changelog.md`
- `agent-stack/manifests/community-skills.experimental.txt`
- `agent-stack/manifests/mcp-servers.experimental.json`

## 安全建议

- 不要把真实 API Key 写进仓库
- 不要把真实个人路径直接固化到模板里
- `filesystem` 只授权工作区目录，不要授权系统根目录
- `MCP` 配置变更前先做 `--dry-run`

## 当前维护建议总结

如果只考虑你现在这个仓库，我建议你按照下面的原则继续维护：

1. 根目录只放本地 `skill` 和单入口脚本
1. 所有安装逻辑统一收口到 `agent-stack/`
1. 所有公共能力都通过清单维护，不直接散落到脚本中
1. 所有 `MCP` 只维护模板，不维护真实密钥和机器路径
1. 新增能力时优先判断它属于本地 `skill`、社区 `skill` 还是 `MCP`

这样维护的优点是：

- 使用入口简单
- 代码组织清晰
- 扩展成本低
- 后续迁移到团队共用仓库也不难
