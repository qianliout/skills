# plugin-creator

## 简介

创建和维护包含清单、Skill、MCP 与应用结构的 Codex 插件。

## 来源

OpenAI Codex 内置系统 Skill，原始位置 `~/.codex/skills/.system/plugin-creator`。

## 安装方案

原始版本随 Codex 安装和升级；本仓库保存快照，方便其他 Agent 读取说明。

本仓库统一安装：在仓库根目录运行 `./scripts/install.sh`，脚本完成公共源码更新后，将该 Skill 复制到 `~/.agents/skills/plugin-creator`。

