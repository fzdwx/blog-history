---
title: "记录学习 jyyos 操作系统课"
date: 2023-03-05T22:27:31+08:00
update: 2023-03-08T22:09:34+0800
draft: false
ShowToc: false
ShowBreadCrumbs: false
tags: [ "os","linux" ]
---


> 最近也是又追起了南京大学的操作系统课(前面几次都中途放弃了),记录一下

### 1. 首先就是编译第三节课的一个demo时,找不到 ld 等命令

> <http://jyywiki.cn/OS/2023/build/lect3.ipynb> demo('hello-os', 'i/hello-os')

由于我使用的是 archlinux, `binutils` 编译出来的 ld, gcc 等命令都是不带 x86 的前缀的,
而 Makefile 中定义的都是带 x86 的, 所以需要建立一个链接:

```shell
ln -s /usr/bin/ld /usr/bin/x86_64-linux-gnu-ld
```

{{< block type="tip" title="来自 chatgpt 的解释:">}}
该命令创建了一个名为“x86_64-linux-gnu-ld”的符号链接,指向“/usr/bin/ld”.这个符号链接可以被用作“x86_64-linux-gnu-ld”二进制文件的替代品.
符号链接是一种特殊的文件类型,它是一个指向另一个文件的文件,可以用来在文件系统中创建指向其他文件或目录的别名.

在Linux系统中,“/usr/bin/ld”是一个连接器（linker）,用于将多个目标文件合并为单个可执行文件.通过创建“x86_64-linux-gnu-ld”的符号链接,可以使该链接器的功能可以在不同的系统上使用,并且不需要更改可执行文件的代码.
这个符号链接通常被用于交叉编译（cross-compiling）应用程序,这种情况下,应用程序在不同的硬件平台上运行.
{{< /block >}}

### 2. 使用 vscode 等编辑器时,第一个问题的代码中头文件无法跳转

使用 bear 生成 compile_commands.json, 然后编辑器就会自动识别了

```shell
bear -- make
```

{{< block type="tip" title="来自 chatgpt 的解释:">}}
该命令使用Bear和Make工具,用于自动捕获Makefile的编译命令和编译期间的调用链.

具体来说,Bear是一个工具,它可以将系统调用跟踪器（strace）输出转换为JSON格式的文件,这个文件包含了所有运行期间的系统调用.
Make是一个工具,它用于根据Makefile规则自动构建和编译程序.

当这两个工具一起使用时,可以使用“bear -- make”命令自动捕获Makefile的编译命令和编译期间的调用链,这个过程可以在后续的调试中使用.
该命令的执行将产生一个JSON格式的文件,其中包含编译期间的所有系统调用和它们的参数.这个文件可以用于调试,性能优化,以及自动化编译和构建系统的开发.

总之,“bear -- make”命令可以帮助程序员更好地理解他们的代码在编译期间所做的事情,以及识别代码中的潜在问题.
{{< /block >}}

### 3. 写一个 pstree - M1

> <http://jyywiki.cn/OS/2023/labs/M1>

实现思路:

1. 扫描 `/proc/` 目录下所有为数字的文件夹
2. 读取 `/proc/{pid}/status` 文件
3. 读取 name 以及 ppid
4. 建树并打印树结构

### ~~4. 关于编译新的os-workbench~~

~~今天尝试下载了一下 2023 年的代码仓库,没想到可以下了~~

```shell
~~git clone https://git.nju.edu.cn/jyy/os-workbench.git~~
```

~~然后我就拉了 L0 来跑,但是怎么样都跑不动: `[-Werror=array-bounds]` 是关于数组越界的~~
~~文件是 `os-workbench/abstract-machine/am/build/x86_64-qemu/src/x86/qemu/ioe.o:433`~~

```shell
~~git pull origin L0~~
```

~~解决办法是在 `os-workbench/abstract-machine/Makefile` 的 `CFLAGS` 最后添加 `-Wno-array-bounds`~~

### 5. 跑起来 2023 版的代码

昨天晚上在我在本机的 L0 代码下 `make run` 是跑不起来的,qemu 正常启动了但是界面是黑的,环境是

```shell
Linux archlinux 6.2.2-arch1-1
qemu 7.2
gcc 12.2.1
```

最后只能曲线救国,在 docker 中 build, 然后在本机跑 qemu (docker 中不方便按图形化界面)

```Dockerfile
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update
RUN apt-get install -y build-essential git gcc-multilib qemu-system strace gdb sudo python3 libsdl2-dev libreadline-dev llvm-11 
RUN useradd -ms /bin/bash user
USER user
WORKDIR /home/users
```

```shell
docker build -t jyyos .
# os-workbench
docker run --rm -it -v ${PWD}:/mnt -w /mnt jyyos bash

# exit docker : os-workbench/kernel
make
qemu-system-x86_64 -serial mon:stdio -machine accel=tcg -smp "" -drive format=raw,file=./build/kernel-x86_64-qemu
```

可能还是编译出了问题, 使用 docker 编译后就没有出现第 4 个问题

![run kernel](/images/12333.png)

### 6. 在 AbstractMachine 中显示一张图片 - L0

这个我记得去年是做一个可以动的游戏,根据键盘的输入去做一些响应,而今年的是只要打印一张图片,大概思路:

1. `xxd -i xxx.png > img_data.h`
2. 遍历这个数组,取 rgb 并调用 `draw_title`
3. 解析参数,获取要输出的分辨率,然后在获得宽高的缩放比,最后获得对于的像素点

![1800x1200](/images/1001.png)

![320x240](/images/2023-03-16-21-45-20.png)

感觉我的实现有问题,只是放大了左上角
