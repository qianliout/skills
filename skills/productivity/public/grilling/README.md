# grilling

## 简介

连续追问式审查一个计划、决策或想法，走通决策树的每个分支，逐一解决决策之间的依赖关系；针对每个问题给出推荐答案，一次只问一个问题，等待反馈后再继续；能从代码库/文件系统/工具中找到的是"事实"，应直接查找而非提问，但"决策"必须交给用户确认，在达成一致理解前不得直接执行。触发短语包括 "grill me" 等任意 "grill" 相关表达。

## 规则

以高级开发人员的标准要求自己：对每个问题先深入思考、独立形成答案，能够基于现有信息、代码库或工具自行解决的问题，不要抛回给用户；只有真正需要用户拍板的决策（用户拥有最终选择权、无法从环境中推断）才向用户提问。

## 来源

[mattpocock/skills](https://github.com/mattpocock/skills)，路径 `skills/productivity/grilling`（上游 `skills/productivity/grill-me` 目前是指向 `/grilling` 命令的占位 Skill，本仓库直接安装其背后的实际内容 `grilling`）。

## 安装方案

上游安装：`npx skills add mattpocock/skills --skill=grilling -y -g`。

本仓库统一安装：在仓库根目录运行 `./scripts/install.sh`，脚本完成公共源码更新后，将该 Skill 复制到 `~/.agents/skills/grilling`。
