---
title: "写一个自己的github action"
date: 2022-10-15T19:25:10+08:00
draft: false
summary: "起因是因为想要有一种可以不用编辑文件而作用到网站上的方式，然后就了解到了 github action 的形式。"
tags: ["project"]
ShowToc: false
---

主要原理就是通过 github action 的来监听 issue 的相关事件，然后读取issue中的内容创建文件提交到 git 上，最后直接部署。这样就能随时编辑并展示了。

具体可以看 [add event to myb log](https://github.com/fzdwx/add-event-to-myblog)这个仓库，
以及[使用方式](https://github.com/fzdwx/fzdwx.github.io/blob/main/.github/workflows/add-event.yml)。

接下来介绍如何开发一个 github action:

### 1. 克隆官方提供的template

官方主要对 typescript 的支持比较好，提供了一系列的[工具包](https://github.com/actions/toolkit)，没办法只能同ts来进行开发，

https://github.com/actions/typescript-action

### 2. 定义想要在运行时用户输入的参数

通过编辑`action.yml`这个文件来定义想要在运行时定义的参数，比如说`GITHUB_TOKEN`:

```yaml
name: 'add event to my blog'
description: 'add event to my blog'
author: 'fzdwx'
branding:
  icon: 'archive'
  color: 'white'
inputs: # 在这个key下面添加自定义参数
  token:
    required: true
    description: 'the repo PAT or GITHUB_TOKEN'
runs:
  using: 'node16'
  main: 'dist/index.js'
```

参数有三个属性:

```yaml
required: 是否必须
description: 描述
default: 默认值
```

### 3. 实现想要的功能

详细可以查看我的[主要代码](https://github.com/fzdwx/add-event-to-myblog/blob/v2.1/src/main.ts)。我的里面主要做了:

1. 根据当前issue number[获取该issue的内容](https://github.com/fzdwx/add-event-to-myblog/blob/v2.1/src/main.ts#L16)。
2. 根据预定义的模板，[创建文件内容](https://github.com/fzdwx/add-event-to-myblog/blob/v2.1/src/main.ts#L18-L33)。
3. 提交到[git](https://github.com/fzdwx/add-event-to-myblog/blob/v2.1/src/main.ts#L34-L38)上。

### 4. 发布到marketplace

需要勾选 **Publish this Action to the GitHub Marketplace**，可能需要2fa认证，找一个 github 支持(我用的是 authy，防止后面忘记了)就ok了。

![Figure 1](/images/8.png)

成功 release 后就能在别的项目中使用了。