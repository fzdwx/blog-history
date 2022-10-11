---
title: "Code:alias"
date: 2022-10-10T22:43:27+08:00
draft: false
---

目前有一个想法，是在命令行下管理脚本的工具。

比如说我有一些常用的脚本:

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

