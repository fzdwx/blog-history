---
layout: post
title: "About rofi"
date: 2022-09-18 22:15:39 +08:00
categories: launcher linux
---

## rofi

今天发现了一个 linux 下的 application launcher [rofi](https://github.com/davatorium/rofi)，它可以快速切换窗口和启动程序。
我用它和 `wmctrl` 进行配合使用。

**我的使用过程**：

1.archlinux install

```shell
yay -S rofi
```

2.添加自定义快捷键 绑定 hotkey 为  `alt` + `space` 触发 `rofi -show`。

3.press `alt` + `space`，然后使用 `shift` + `left` or `right` 进行切换 mode 。

---

**更改主题以及显示 icon**:

1.生成配置文件

```shell
mkdir -p ~/.config/rofi
rofi -dump-config > ~/.config/rofi/config.rasi
```

2.显示icon

```shell    
sed -i '8c show-icons: true;' ~/.config/rofi/config.rasi
```

3.更换主题

参考 https://github.com/lr-tech/rofi-themes-collection#installing-themes

## wmctrl

**我的 `wmctrl` 的配置示例**:

使用 `xprop WM_CLASS` 获取前缀。

```shell
alias chrome="wmctrl -x -a google-chrome || google-chrome-stable > /dev/null 2>&1 &"
alias note="wmctrl -x -a obsidian || /usr/bin/obsidian > /dev/null 2>&1 &"
alias codew="wmctrl -x -a code || /opt/code/code > /dev/null 2>&1 &"
alias idea="wmctrl -x -a jetbrains-idea || /opt/idea/bin/idea.sh > /dev/null 2>&1 &"
alias discord="wmctrl -x -a discord || /opt/discord/Discord > /dev/null 2>&1 &"
```