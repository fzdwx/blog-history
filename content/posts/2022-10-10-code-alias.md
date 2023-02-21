---
title: "Code:alias"
date: 2022-10-10T22:43:27+08:00
draft: false
tags: ["idea"]
ShowToc: false
---

## idea

目前有一个想法，是在命令行下管理脚本的工具。

例如说我有一些常用的脚本:

```sh
cd $(find . -name "*" -type d | fzf)
```

然后通过命令行添加

```sh
cli load "cd $(find . -name "*" -type d | fzf)" -alias cdf
```

然后使用cdf进行运行

```sh
cli cdf 
```

## 后续

> 2022-10-18 22:47

刚刚找到了一个跟我这个想法很契合的项目: https://github.com/denisidoro/navi。

今天一晚上都在调研技术的可行性，但是都达不到我想要的效果。还是这个例子，`cd $(find . -name "*" -type d | fzf)`，
主要有两种思路:

1. 在运行程序的使用利用shell的tab键盘补全，直接替换成这段命令，然后运行。比如说程序叫`qwe`，在shell里面输入`qwe cdf<TAB>`
   ，然后就直接替换为上面的命令。我在go里面找到`cobra`这个包，它能动态补全命令，有点效果，但还不够，不能做到全部替换，遂搁置。
2. 直接在程序里面运行这段命令，我试了之后还是不行，`cd`执行后没有生效，应该还是跟`fork`有关。

然后就到github里面找别人的实现，没想到找到了一个，但是试过之后还是不支持，但确实做的还不错。

想要做成我想要的效果就是实现:

1. 在shell中补全能直接替换所有，而不是一段。
2. 在程序中不用`fork`运行。

还需要在看看。


