---
title: "在shell脚本中执行cd后改变main shell的路径"
date: 2022-10-11T16:55:35+08:00
draft: false
tags: ["linux","idea"]
ShowToc: false
---

## 起因

昨天晚上想用fzf与cd联动，就是fzf的结果传递给cd来执行于是有了这么一条命令:

```shell
cd $(fd --type d | fzf)
```

这个命令也确实能完成任务，但是问题有两个:

1. 如果直接退出的话会回到家目录，因为`$(..)`的执行结果为空
2. 每次都要输入这么多会很麻烦

## 用alias

然后尝试用alias来试试，所以就往`.zshrc`里面添加:

```shell
alias cdf="cd $(fd --type d | fzf)"
```

结果是直接不能运行，因为它直接识别了`$(..)`这一段，然后直接运行了，但是后面就不会运行。

## 用shell脚本

然后就写了这个文件:

```shell
#!/bin/sh
path=$(fd --type d --strip-cwd-prefix --hidden --follow --exclude .git --exclude node_modules | fzf)

if [ -z "$path" ]; then
    exit
fi

cd "$path" || exit
```

结果也是不行，后面我在最下面加了一行`echo "$PWD"`，我看到是执行了的，但是程序退出了就失效了。

## 解决

最后我搜索到可以使用`source xxx`或者`. xxx`来解决，最后是alias+shell脚本来完成这个操作的:

```shell
alias cdf="source /path/to/cdf"
```

同时它也解决我上面提到的两个问题。

## source为什么能解决？

之所以直接用shell脚本直接运行会不行，是因为它不是在当前shell环境中运行的，而是一个子shell，所以结果就不能改变当前的文件目录了。

而`source`或者`.`就代表着在当前的shell环境中执行，所以就能成功。

## 更新

### 2022/11/18

今天发现一种更容易解决的办法,就是在写一个 shell 方法:

```shell
function cd() {
    cd "$(fzf)"
}
```

把它加入到`.zshrc`(我用的是 zsh)中，然后在命令行中输入 `cd` 就好了。  