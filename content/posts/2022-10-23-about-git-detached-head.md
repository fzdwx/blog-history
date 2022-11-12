---
title: "关于 git 游离分支"
date: 2022-10-23T00:09:44+08:00
draft: false
tags: ["github","git"]
summary: 如何在切换了分支之后恢复游离分支提交的代码。
---

刚刚改[nvim](https://github.com/fzdwx/nvim)配置时，不知道怎么回事，出现了游离分支(英文名称大概是 _detached head_ )。主要症状就是
git提交不了，由于我用的 lazygit ，它的提示不明显，我以为提交了。然后后面打开 idea 看到底是什么。发现提示是游离分支，这个时候我也没在意。
最致命的操作来了: 我直接 checkout main 分支，然后今天晚上修改的记录全没了。

我的解决方案:

1. 查看`git log`，只能显示当前分支的修改 commit 记录。 **无效**
2. 利用 idea 的 local history 功能，只能找到文件，文件里面的内容是空白的。 **无效**
3. 搜索 detached head 的解决方案，只能搜到没切换分支前的解决方案，不适用与我的现象。 **无效**
4. 最后搜索 git 查看所有 commit ，找到了`git reflog`，它能显示可引用的历史版本记录，最后找到我要的那个 commit
   之后直接`git rest --hard xxx`完美解决。


说实话，有点慌也有点烦，如果找不回来我可能会弃坑 nvim 了。