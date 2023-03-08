---
title: "Neovim使用记录  "
date: 2022-09-28T15:59:37+08:00
draft: false
tags: ["nvim","editor"]
summary: 由于最近切换到了 linux,不可避免的经常需要使用 vi 等编辑器,所以这次好好折腾一下.
ShowToc: false
ShowBreadCrumbs: false
---

> 由于最近切换到了linux,不可避免的经常需要使用vi等编辑器,所以这次好好折腾一下.

我的配置地址: https://github.com/fzdwx/nvim ,现在直接使用 [LazyVim](https://github.com/LazyVim/LazyVim).

--- 

> 过期


## 我的配置

### pakcer

我选用的插件管理器是`packer`,我也不知道选什么好,就按最新的来吧.

```lua
--- setup packer
local fn = vim.fn
local install_path = fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'

if fn.empty(fn.glob(install_path)) > 0 then
    packer_bootstrap = fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
    vim.cmd("packadd packer.nvim")
end
--- add plugins
require('packer').startup(function(use)
    -- 自托管
    use 'wbthomason/packer.nvim'
    -- 其他插件
    -- 如果是第一次则同步
    if packer_bootstrap then
        require('packer').sync()
    end
end)
```

### [alpha](https://github.com/goolord/alpha-nvim)

是一个dashboard,也可以说是一个欢迎界面.

```lua
require('packer').startup(function(use)
    -- ...
    --- 添加下面两行进行安装
    use "goolord/alpha-nvim";
    use "kyazdani42/nvim-web-devicons";
    -- ...
end)
```

配置代码太长了就不放了,可以点击这里[ 这里 ](https://github.com/fzdwx/nvim/blob/main/lua/config/plugins/alpha.lua)参考.

### [telescope](https://github.com/nvim-telescope/telescope.nvim)

主要作用是文件的查找与预览.

```lua
require('packer').startup(function(use)
    -- ...
    --- 添加下面代码进行安装
    use {
        'nvim-telescope/telescope.nvim', tag = '0.1.0',
        "ahmedkhalf/project.nvim",
        'nvim-lua/plenary.nvim',
    }
    -- ...
end)
```

- [配置](https://github.com/fzdwx/nvim/blob/main/lua/config/plugins/telescope.lua)
- [key map](https://github.com/fzdwx/nvim/blob/main/lua/config/key/init.lua#L34-L52)

## 一些教程

1. [Rust and nvim](https://rsdlt.github.io/posts/rust-nvim-ide-guide-walkthrough-development-debug/)