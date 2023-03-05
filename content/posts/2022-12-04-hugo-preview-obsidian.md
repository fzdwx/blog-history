---
title: "在 Obsidian 中预览 hugo "
date: 2022-12-04T22:45:02+08:00
draft: false
summary: 前段时间玩过几天的 obsidian，由于太费神了所以转向了 hugo ,然后直接用文本编辑器写 md ，体验还是不太好，然后我想起还有
obsidian 这个软件，所以就有了这个插件。
tags: ["obsidian","project"]
ShowToc: false
ShowBreadCrumbs: false
---

> 前段时间玩过几天的 obsidian，由于太费神了所以转向了 hugo ,然后直接用文本编辑器写 md ，体验还是不太好，然后我想起还有
> obsidian 这个软件，所以就有了这个插件。

**当前主要功能**：

1. 开一个 `custome iframe` 预览 hugo (via https://github.com/Ellpeck/ObsidianCustomFrames)
2. 后台启动 `hugo server`![](static/images/Pasted%20image%2020221205140050.png)
    1. 当前还有一点问题，子进程( hugo 进程)在程序推出时不会关闭。

**遇到的问题**:

1. 获取 obsidian 打开的目录不知道 api( cwd ),后提 issue 知道了获取方法。

---

仓库: https://github.com/fzdwx/hugo-preview-obsidian

![运行图例，左编辑区域，右预览区域](/images/12.png)

## 更新

1. 支持自定义 exec command, 例如可以用来启动终端。 使用 `ALT+F12` 唤起。
    1. 由于我使用 git
       进行同步，时常需要打开终端并且进入到具体的目录，所以需要一个快速启动终端在当前的目录下的命令： `wezterm start --class float --cwd ${cwd}`。
    2. 目前只提供了 cwd 这个变量，它会替换为当前笔记的路径
2. 添加定义 `hugo` 的路径，如果不设置则使用系统的 `hugo` 命令 -- v0.1.5

![自定义 command 配置示例](/images/13.png)