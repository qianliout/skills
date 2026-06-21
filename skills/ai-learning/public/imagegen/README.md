# imagegen

## 简介

通过 Codex 图片生成工具创建或编辑照片、插画、纹理和视觉资产。

## 来源

OpenAI Codex 内置系统 Skill，原始位置 `~/.codex/skills/.system/imagegen`。

## 安装方案

原始版本随 Codex 安装和升级；实际生成图片依赖 Codex 的 `image_gen` 工具。

本仓库统一安装：在仓库根目录运行 `./scripts/install.sh`，脚本完成公共源码更新后，将该 Skill 复制到 `~/.agents/skills/imagegen`。

