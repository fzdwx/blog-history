---
title: "在 Obsidian 中预览 hugo "
date: 2022-12-04T22:45:02+08:00
draft: false
summary: 前段时间玩过几天的 obsidian，由于太费神了所以转向了 hugo ,然后直接用文本编辑器写 md ，体验还是不太好，然后我想起还有 obsidian 这个软件，所以就有了这个插件。
tags: [obsidian,plugin]
---

> 前段时间玩过几天的 obsidian，由于太费神了所以转向了 hugo ,然后直接用文本编辑器写 md ，体验还是不太好，然后我想起还有 obsidian 这个软件，所以就有了这个插件。

**当前主要功能**：
1. 开一个 `custome iframe` 预览 hugo (via https://github.com/Ellpeck/ObsidianCustomFrames)
2. 后台启动`hugo server`
	1. 当前还有一点问题，子进程( hugo 进程)在程序推出时不会关闭。


**遇到的问题**:
1. 获取 obsidian 打开的目录不知道 api( cwd ),后提 issue 知道了获取方法。


---

仓库: https://github.com/fzdwx/hugo-preview-obsidian

![运行图例，左编辑区域，右预览区域](/images/12.png)

