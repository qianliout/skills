# skill-forge

## 简介

设计、调试和打包面向 Claude Code 的完整 Skill。

## 来源

[sanyuan0704/code-review-expert](https://github.com/sanyuan0704/code-review-expert)，路径 `skills/skill-forge`。

## 安装方案

上游安装：`npx skills add sanyuan0704/code-review-expert@skill-forge -y -g`。

本仓库统一安装：先在仓库根目录运行 `./scripts/update-public.sh` 同步公共源码到 `./.sources/`，再运行 `./scripts/install.sh`，即可将该 Skill 复制到 `~/.agents/skills/skill-forge`。

