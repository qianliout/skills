# skill-installer

## 简介

从 OpenAI 技能列表或 GitHub 仓库安装 Codex Skill。

## 来源

OpenAI Codex 内置系统 Skill，原始位置 `~/.codex/skills/.system/skill-installer`。

## 安装方案

原始版本随 Codex 安装和升级；其安装能力依赖 Codex 提供的工具环境。

本仓库统一安装：在仓库根目录运行 `./scripts/install.sh`，脚本完成公共源码更新后，将该 Skill 复制到 `~/.agents/skills/skill-installer`。

