---
title: "Fault-Tolerant And Replication"
date: 2022-10-09T12:01:28+08:00
draft: true
---

容错(fault-tolerant)本身时为了提高可用性(high availability)，而我们使用的方法就是复制(replication)。复制到底能解决什么样的故障(Failure)？

最简单的就是`fail-stop`(只要出了错误就立即停止，而不是返回错误的结果)，当然如果你的软件或硬件本身就有问题，那么它是无法解决的(天灾人祸)。

`vmware tf` 提供了两种replication的实现思路:

1. `state transfer`: 状态转移，将master的所有信息(内存的内容等)全部发送给backup。
2. `replicated state machine`: 复制状态机，只发送来自外部的事件指令(输入)，backup就能根据这些指令得到相同的结果。

## Links

1. [论文地址](https://pdos.csail.mit.edu/6.824/papers/vm-ft.pdf)
