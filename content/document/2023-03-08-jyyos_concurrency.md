---
title: "并发和线程"
date: 2023-03-08T20:14:58+08:00
update: 2023-03-08T20:14:58+08:00
draft: false
ShowToc: false
ShowBreadCrumbs: false
tags: [ostep]
---

> http://ostep.org/Chinese/26.pdf

假设有这样的一段[代码](/code/jyyos_concurrency.go)，启动了两个协程，然后都循环了 n 次并进行 ++ 操作。

{{< gist fzdwx 825f29e8da6f97451e17099055e3d0e9 >}}

正常来说，结果就应该是 2n，但实际的结果却距离 2n 还有很大的差距。

## 1. 从汇编来看

其中的 `count++` 这一行代码，在 RISC-V中可能有多条组成: 加载 -> 修改 -> 存储

```asm
lw t0 count     // t0 = count
addi t0 t0 1    // t0 = t0 + 1
sw t0 count     // count = t0
```

而我们启动了两个协程，这两个协程都会执行这三条指令，所以就会出现这样的情况:

1. 协程 A 加载 count 的值，得到 0
2. 协程 B 加载 count 的值，得到 0
3. 协程 A 修改 count 的值，得到 1
4. 协程 B 修改 count 的值，得到 1
5. 协程 A 存储 count 的值，得到 1
6. 协程 B 存储 count 的值，得到 1

这就导致了，确实是执行了两次 `count++`，但是最终的结果却是 1


## 2. 从操作系统的上下文切换来看

如果两个协程都分属于不同的线程，那么在操作系统的上下文切换中，就会出现这样的情况:

1. 协程 A 加载 count 的值，得到 0
2. 协程 A 修改 count 的值，得到 1
3. 这个时候，假如操作系统进行上下文切换，切换到协程 B
4. 协程 B 加载 count 的值，得到 0
5. 协程 B 修改 count 的值，得到 1
6. 协程 B 存储 count 的值，得到 1
7. 切换到协程 A
8. 协程 A 存储 count 的值，得到 1

这也会导致结果是 1


{{< block type="tip" title="竞态条件">}}
这种情况就是竞态条件: 结果取决于代码的时间执行。由于运气不好(在执行的过程中发生上下文切换)，得到了错误的结果。

这段代码也被称为临界区，因为这段代码访问了共享变量，在 golang 中可以用 `go run -race main.go` 来进行检测
{{< /block >}} 