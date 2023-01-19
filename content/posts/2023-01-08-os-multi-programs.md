---
title: "操作系统的分时多任务"
date: 2023-01-08T08:44:38+08:00
draft: false
tags: [os,note,risc-v]
summary: 记录如何实现一个简单的支持运行多个程序的操作系统，比如如何暂停和恢复应用程序(换栈)，以及如何实现一个抢占式操作系统。
---

{{< block type="tip">}}
提高系统的性能和效率是操作系统的核心目标之一：
1. 通过提前加载应用程序到内存，减少应用程序切换开销
2. 通过协作机制支持程序主动放弃处理器，提高系统执行效率
3. 通过抢占机制支持程序被动放弃处理器，保证不同程序对处理器资源使用的公平性，也进一步提高了应用对 I/O 事件的响应效率
{{< /block >}}

通过特权级机制我们可以轻松实现一个顺序执行程序的操作系统：
1. 在硬件级特权隔离机制的帮助之下，运行在更高特权级的操作系统不会受到有意或者无意出错的应用的影响
2. 在硬件异常触发机制的帮助之下，可以全方位监控运行在用户态低特权级的应用执行
3. 一旦应用越过了特权级界限或主动申请获得操作系统的服务，就会触发 Trap 进入到内核栈中进行处理
4. 无论原因是应用出错或应用申请更高级别的权限，操作系统就会开始运行下一个程序

可以看到这个操作系统的特是: **在内存中同一时间最多只需要驻留一个应用**。因为只要当一个应用结束运行或运行出错时，操作系统才会加载另一个应用程序到该内存 。

而一次只能运行一个程序是显然不符合我们对于操作系统的期望的，所以人们就考虑开始在内存中尽量同时驻留多个应用，提高处理器的利用率。

{{< block type="tip" title="多道程序">}}
一个程序执行完毕后或主动放弃执行，处理器才能执行另外一个程序
{{< /block >}}

![多道程序操作系统的结构](/images/Pasted%20image%2020230108192734.png)

1. 首先 Qemu 把多个应用程序和 MultiprogOS 的 image 镜像加载到内存中
2. RustSBI(bootloader)完成基本的硬件初始化后，跳转到 MultiprogOS 的起始位置
3. MultiprogOS 首先进行正常运行前的初始化工作，建立栈空间和清空 bss 段
4. 然后通过 AppManager 从 app 列表中把所有 app 都加载到内存中，并按指定顺序在用户态一个个的执行

{{< block type="tip" title="协作式操作系统">}}
在**多道程序**运行方式下，一个程序如果不让出处理器，其他程序是无法执行的。如果一个应用由于 
I/O 操作让处理器空闲或让处理器忙等，那其他需要处理器资源进行计算的应用还是没法使用空闲的处理器。

所以就相当让应用在执行 I/O 操作或空闲时，可以主动 **释放处理器**，让其他应用继续执行。由操作系统提供这样的服务(syscall)给应用程序调用,这种操作系统就是支持 多道程序 或 协作式多任务 的**协作式操作系统**
{{< /block >}}

![协作式操作系统](/images/Pasted%20image%2020230108193817.png)

1. 把 Appmanager 拆分为负责加载应用的 Loader 和管理应用运行过程的 TaskManger
2. Taskmanager 通过  task 任务控制块来管理应用程序的执行过程，支持应用程序主动放弃 CPU 并切换到另一个应用继续执行
3. 应用程序在运行时有自己所在的内存空间和栈，确保被切换时相关信息不会被其他应用破坏
4. 如果当前应用程序正在运行，则该应用对应的任务处于 Running 状态
5. 如果该应用主动放弃处理器，则切换到 Ready 状态
6. 操作系统进行任务切换时，需要把暂停任务的上下文(即任务用到的通用寄存器)保存起来
7. 把要继续执行的任务的上下文恢复为暂停前的内容

## 抢占式操作系统

由于应用程序员在编写程序时，无法做到在程序合适的位置放置 **放弃处理器的系统调用请求**，这样系统的整体利用率还是无法提高。

所以还需要有一种机制能强制打断应用程序的执行，来提高系统的利用率。在计算机体系的硬件设计中，外设可以通过硬件中断机制来与处理器进行 I/O 交互操作。这种打断机制可以随时打断应用程序的执行，并让操作系统完成对外设的 I/O 响应。

而操作系统可以进一步用某种固定时长为时间间隔的外设中断(比如时钟中断)来强制打断一个程序的执行，这样一个程序只能运行一段时间(可以简称为一个**时间片**, time slice)就一定会让出处理器，且操作系统可以在处理外设的 I/O 响应后，让不同的应用程序分时占用处理器执行，并可通过统计程序占用处理器的总执行时间来评估程序对处理器资源的消耗。这种运行方式就是**分时共享(time sharing)** 或 **抢占式多任务(multitasking)**,也可以合称为**分时多任务**。

我们可以把:
- 一个程序一次完整执行过程称为一次**任务**(task)
- 一个程序在一个时间片上占用处理器执行的过程称为一个**任务片**（task slice)

操作系统对不同程序的执行过程中的任务片进行调度和管理，即通过平衡各个程序在整个时间段上的任务片数量就能达到一定程序的系统公平和高效的系统效率。

{{< block type="tip">}}
在一个包含多个时间片的时间段上，会有属于不同程序的多个任务片在轮流占用处理器执行，这样的系统就是支持分时多任务或抢占式多任务的抢占式操作系统。
{{< /block >}}

![分时多任务操作系统](/images/Pasted%20image%2020230108201513.png)

1. 改进 Trap Handle，支持时钟中断，从而可以抢占应用的执行
2. 改进 TaskManger，提供任务调度功能，可以在收到时钟中断后统计任务的使用时间片，如果任务的时间片用完后，则切换任务

## 多道程序的放置与加载

每个应用都按照它的编号被分别放置并加载到内存中的不同位置，因为是一次性全部加载的，所以在切换到另一个应用执行时会很快，不需要清空前一个应用然后在加载当前应用的开销。

### 多道程序放置

1. 调整每个用户应用程序构建时的链接脚本`linker.ld`中的起始地址`BASE_ADDRESS`,这个地址就是应用被内核加载到内存中的起始地址，所以每个应用也知道自己会被加载到某个地址运行
2. 比如说第一个应用的地址范围是`BASE_ADDRESS` ～ `BASE_ADDRESS`+`APP_LIMIT`,第二个应用的地址范围是`BASE_ADDRESS`+`APP_LIMIT`~`BASE_ADDRESS`+2 * `APP_LIMIT`。
3. 可以看出这就是另一种形式的硬编码，与每次复制应用程序到`BASE_ADDRESS`而言没什么区别
4. 这么做的原因是因为操作系统的能力还比较弱，目前应用程序的编址方式是基于绝对位置的，并没做到与位置无关，内核也没有提供相应的地址重定位机制

```python
import os  
  
base_address = 0x80400000  
step = 0x20000  
linker = 'src/linker.ld'  
  
app_id = 0  
apps = os.listdir('src/bin')  
apps.sort()  
for app in apps:  
    app = app[:app.find('.')]  
    lines = []  
    lines_before = []  
    with open(linker, 'r') as f:  
        for line in f.readlines():  
            lines_before.append(line)  
            // 替换初始的base_address 到每个应用具体的内存地址
            line = line.replace(hex(base_address), hex(base_address+step*app_id))  
            lines.append(line)  
    with open(linker, 'w+') as f:  
        f.writelines(lines)  
    // 编译应用程序
    os.system('cargo build --bin %s --release' % app)  
    print('[build.py] application %s start with address %s' %(app, hex(base_address+step*app_id)))  
    // 还原到初始的base_address
    with open(linker, 'w+') as f:  
        f.writelines(lines_before)  
    app_id = app_id + 1
```

### 多道程序的加载

前面一个操作系统的所有应用都是使用同一个固定的加载物理地址，所以内存中最多只能驻留一个应用，只要当它运行完毕或运行出错时才由操作系统加载一个新的应用来替换它。

但是我们要实现所有的应用在内核初始化的时候就一起加载到内存中。为了防止覆盖，所以要加载到不同的物理地址上:

```rust
/// Load nth user app at  
/// [APP_BASE_ADDRESS + n * APP_SIZE_LIMIT, APP_BASE_ADDRESS + (n+1) * APP_SIZE_LIMIT).  
pub fn load_apps() {  
    extern "C" {  
        fn _num_app();  
    }  
    let num_app_ptr = _num_app as usize as *const usize;  
    let num_app = get_num_app();  
    let app_start = unsafe { core::slice::from_raw_parts(num_app_ptr.add(1), num_app + 1) };  
    // clear i-cache first  
    unsafe {  
        asm!("fence.i");  
    }  
    // load apps  
    for i in 0..num_app {  
        // 计算方式同放置时一样
        let base_i = get_base_i(i);  
        // clear region  
        (base_i..base_i + APP_SIZE_LIMIT)  
            .for_each(|addr| unsafe { (addr as *mut u8).write_volatile(0) });  
        // load app from data section to memory  
        let src = unsafe {  
            core::slice::from_raw_parts(app_start[i] as *const u8, app_start[i + 1] - app_start[i])  
        };  
        let dst = unsafe { core::slice::from_raw_parts_mut(base_i as *mut u8, src.len()) };  
        dst.copy_from_slice(src);  
    }  
}
```

```asm
    .align 3  
    .section .data  
    .global _num_app  
_num_app:  
    .quad 4  s
    .quad app_0_start  
    .quad app_1_start  
    .quad app_2_start  
    .quad app_3_start  
    .quad app_3_end  
  
    .section .data  
    .global app_0_start  
    .global app_0_end  
app_0_start:  
    .incbin "../user/target/riscv64gc-unknown-none-elf/release/00power_3.bin"  
app_0_end:  
  
    .section .data  
    .global app_1_start  
    .global app_1_end  
app_1_start:  
    .incbin "../user/target/riscv64gc-unknown-none-elf/release/01power_5.bin"  
app_1_end:  
  
    .section .data  
    .global app_2_start  
    .global app_2_end  
app_2_start:  
    .incbin "../user/target/riscv64gc-unknown-none-elf/release/02power_7.bin"  
app_2_end:  
  
    .section .data  
    .global app_3_start  
    .global app_3_end  
app_3_start:  
    .incbin "../user/target/riscv64gc-unknown-none-elf/release/03sleep.bin"  
app_3_end:
```

### 执行应用程序

当应用程序的初始化放置完成后，或者某个应用程序结束或出错时就要调用`run_next_app`运行下一个程序。

此时 CPU 是 S 模式，而要切换到 U 模式下运行。这一过程与[执行应用程序](/posts/2022-12-30-os-privilege/#执行应用程序)类似。不同的是操作系统知道每个应用程序预先加载在内存中的位置，这就需要设置应用程序返回不同 Trap 上下文(保存了 放置程序起始地址的`epc`寄存器内容)：
1. 跳转到应用程序(i)的入口点 entry<sub>i</sub>
2. 切换到用户栈 stack<sub>i</sub>

这样的一个支持把多个应用的代码和数据放置到内存中，并能够依次执行每个应用的操作系统就完成了，但是它的任务调度的灵活性还有很大改进空间。


## 任务切换

上面这这个操作系统还是一个应用会一直占用 CPU 直到它结束或者出错。为了提高效率，我们需要介绍新的概率: **任务**、**任务切换**、**任务上下文**。

首先我们把应用程序在不同时间段的执行过程分为两类：
1. 占用处理器执行有效任务的计算阶段
2. 不必占用处理器的等待阶段(比如等待 I/O)

这些阶段就形成了一个"暂停~运行..."组合的控制流或执行历史。

### 任务

如果操作系统能在某个应用程序处于等待阶段的时候，把处理器转给另外一个处于计算阶段的应用程序，那么只要转换的开销不大，那么处理器的执行效率就会大大提高。

这需要应用程序在运行途中能主动让出 CPU 的使用权，等到操作系统让它再次执行后，那它才能继续执行。

我们把
1. 应用程序的一次执行过程称为一个**任务**
2. 应用执行过程中的一个时间片段或空闲片段称为“**计算任务片**”或“**空闲任务片**”

当应用程序的所有任务片都完成后，应用程序的一次任务也就完成了。从一个程序的任务切换到另外一个程序的任务称为“**任务切换**”，为了确保切换后的任务能正确继续执行，操作系统需要支持让任务的执行“暂停”和“继续”。

一条控制流需要支持“暂停～继续”，就需要提供一种控制流切换的机制，而且需要保证程序执行的控制流被切换出去之前和切换回来之后，能够继续正确执行。这需要让程序执行的状态(上下文 context)，即**在执行过程中同步变化额度资源(如寄存器，栈等)保持不变，或者变化在它的预期之内**。不是所有的资源都需要保存，事实上只有那些对于程序接下来的正确执行仍然有用，且在它被切换出去的时候有被覆盖风险的那些资源才有被保持的价值。这些需要保存与恢复的资源称为**任务上下文(task context)**。

### 不同类型的上下文与切换

在控制流切换的过程中，我们需要结合硬件机制和软件来实现保存和恢复任务上下文。任务的一次切换涉及到被换出和即将被换入的两条控制流(两个应用的不同任务)。前面介绍的两种上下文保存/恢复的例子：
1. RISC-V 中的函数调用，为了支持嵌套函数调用，不仅需要硬件平台提供的跳转指令，同时还需要保存和恢复[函数调用上下文](/posts/2022-12-10-risc-v/#risc-v-寄存器名称)(比如说返回地址—— ra 寄存器，比如说需要保存的寄存器—— s0~s10)。
	1. 在这个例子中，函数调用包含在普通控制流(与异常控制流相对)之类，且始终用一个固定的栈来保存执行的历史记录，因此函数调用并不涉及控制流的特权级切换。
	2. 但是我们依然可以看成调用者与被调用者两个执行过程的“切换”
2. 在前面的特权级的笔记中涉及到了某种异常（Trap）控制流，即两条控制流的特权级切换,需要保存和恢复[系统调用(Trap)上下文](/posts/2022-12-30-os-privilege/#特权级切换)。为了让内核能够完全掌控应用的执行，且不会被应用破坏整个系统，就必须利用硬件提供的特权级机制，让应用和内核运行在不同的特权级。

应用程序与操作系统打交道的核心在于硬件提供的 Trap 机制，也就是在 U 运行的应用控制流和在 S 运行的 Trap 控制流(操作系统的陷入处理部分)之间的切换。Trap 控制流是 Trap 触发的一瞬间生成的，它几乎唯一的目标就是处理 Trap 并恢复到原应用控制流。Trap 控制流需要把 Trap 上下文(几乎所有的通用寄存器)保存在自己的内核栈上，可以回看[Trap 上下文的保存与恢复](/posts/2022-12-30-os-privilege/#trap-上下文的保存与恢复)。

## 任务切换的设计与实现

现在要介绍的是一种与 Trap 不同的异常控制流,它们都是描述两条控制流之间的切换，如果将它和 Trap 切换进行比较，会有如下异同:
-   与 Trap 切换不同，它不涉及特权级切换
-   与 Trap 切换不同，它的一部分是由编译器帮忙完成的
-   与 Trap 切换相同，它对应用是透明的

任务切换是来自两个不同应用在内核中的 Trap 控制流之间的切换。当一个应用 Trap 到 S 模式的操作系统内核中进一步处理(操作系统的 Trap 控制流)的时候，Trap 控制流会调用一个特殊的 `__switch` 函数：在 `__switch` 返回之后，将继续从调用该函数的位置继续向下执行，但是其中却隐藏者复杂的控制流切换过程：
1. 调用 `__switch` 之后直到它返回前，原 Trap 控制流 A 会被切换出去，CPU 会运行另一个应用在内核中的 Trap 控制流 B 
2. 然后在某个合适的时机，原 Trap 控制流 A 才会从某一条 Trap 控制流 C（很可能不是 B）切换回来继续执行并最终返回

`__switch`函数和一个普通的函数之间的核心差别就是它会**换栈**。

![](/images/Pasted%20image%2020230110104125.png)

当 Trap 控制流准备调用 `__switch` 函数使任务从运行状态进入暂停状态的时候，在调用之前，内核栈会保存应用执行状态的 Trap 上下文以及内核在对 Trap 处理过程中留下的调用栈信息。由于之后还需要恢复并继续执行，所以必须要保存 CPU 当前的某些寄存器(如下图第一阶段中的最下一部分)，这些就是**任务上下文**。这些任务上下文都被保存在 `TaskManager` 中，从内存布局来看就是 `.data` 段中。

对于当前正在执行的任务的 Trap 控制流，我们用一个名为 `current_task_cx_ptr` 的变量来保存放置当前任务上下文的地址；而用 `next_task_cx_ptr` 的变量来保存放置下一个要执行任务的上下文的地址。利用 C 语言的引用来描述的话就是：
```c
TaskContext *current_task_cx_ptr = &tasks[current].task_cx;
TaskContext *next_task_cx_ptr    = &tasks[next].task_cx;
```

![switch 换栈](/images/Pasted%20image%2020230110110143.png)

假设某次 `__switch` 调用要从 Trap 控制流 A 切换到 B，一共可以分为四个阶段，在每个阶段中我们都给出了 A 和 B 内核栈上的内容：
1. 在 Trap 控制流 A 调用函数之前，A 的内核栈上只有 Trap 上下文和 Trap 处理函数的调用栈信息，而 B 是之前被切换出去的(处于暂停状态)
2. A 在 A 任务上下文空间中保存 CPU 当前寄存器的快照
3. 读取 `next_task_cx_ptr` 指向的 B 任务上下文,恢复寄存器后，就做到了一个函数跨两条控制流执行： *通过换栈实现了控制流的切换*
	1. 恢复 `ra`
	2. 恢复`s0~s11`
	3. 恢复 `sp`
4. 上一步寄存器恢复完成后，可以看到通过恢复 `sp` 寄存器换到了任务 B 的内核栈上，进而实现了控制流的切换。当 CPU 执行 `ret` 指令完成 `__switch` 函数返回后，任务 B 就可以从调用 `__switch` 的位置继续向下执行

这时候任务 A 处于暂停状态，而任务 B 恢复了上下文并处于运行状态。


{{< block type="details" title="__switch 的实现">}}

```asm
.altmacro  
.macro SAVE_SN n  
    sd s\n, (\n+2)*8(a0)  
.endm  
.macro LOAD_SN n  
    ld s\n, (\n+2)*8(a1)  
.endm  
    .section .text  
    .globl __switch  
__switch:  
    # 阶段 1
    # __switch(  
    #     current_task_cx_ptr: *mut TaskContext,  
    #     next_task_cx_ptr: *const TaskContext  
    # )  
    # 阶段 2 保存 curr 寄存器 sp ra s0~s11
    # save kernel stack of current task  
    sd sp, 8(a0)  
    # save ra & s0~s11 of current execution  
    sd ra, 0(a0)  
    .set n, 0  
    .rept 12  
        SAVE_SN %n  
        .set n, n + 1  
    .endr  
    # 阶段 3 恢复 next 寄存器
    # restore ra & s0~s11 of next execution  
    ld ra, 0(a1)  
    .set n, 0  
    .rept 12  
        LOAD_SN %n  
        .set n, n + 1  
    .endr  
    # restore kernel stack of next task  
    ld sp, 8(a1)  
    # 阶段 4
    ret  
```

{{< /block >}}

1. 保存 `ra` 是记录 `__switch` 返回后跳转的位置(`ret`执行完毕后)
2. `s0~s11` 是规定被调用者保存的寄存器

对应的 TaskContext 的代码:
```rust
pub struct TaskContext {
    ra: usize,
    sp: usize,
    s: [usize; 12],
}

// 在 rust 中调用 __switch
global_asm!(include_str!("switch.S"));

use super::TaskContext;

extern "C" {
    pub fn __switch(
        current_task_cx_ptr: *mut TaskContext,
        next_task_cx_ptr: *const TaskContext
    );
}
```

## 多道程序与协作式调度

{{< block type="tip" >}}
任务相关概念的扩展:
- 任务运行状态: 任务从开始到结束执行过程中所处的不同运行状态，比如:未初始化、准备执行、正在执行、已推出
- 任务控制块： 管理程序的执行过程的任务上下文，控制程序的执行与暂停
- 任务相关系统调用： 应用程序和操作系统直接的接口，用于程序主动暂停 `sys_yield` 和主动退出 `sys_exit`
{{< /block >}}

### 多道程序背景与 yield 系统调用

我们知道 CPU 的处理速度远快于外设的 I/O 的，只有当 I/O 响应之后 CPU 才能继续计算。那么这是如何实现的？

通常外设会提供一个可读的寄存器记录它目前的工作状态，于是 CPU 需要不断原地循环读取它直到它的结果显示设备已经将请求处理完毕了，才能继续执行（这就是 **忙等** 的含义）。

而如果经常让 CPU 忙等的话，效率肯定是不符合预期的。多道程序是如何优化呢？
1. 内核管理多个应用程序
2. 如果 I/O 的时间很常，可以切换任务去处理其他应用
3. 在某次切换回来时去读取设备寄存器，如果已经返回则继续执行
4. 这样，只要同时存在的应用够多，就能在一定程度上隐藏 I/O 处理的延迟

这种任务切换应该是应用程序主动调用 `sys_yield` 来实现的。
![紫色是外设开始处理 I/O,蓝色和绿色的两个应用程序分别占用 CPU 的时间](/images/Pasted%20image%2020230110202921.png)

### 任务控制块与任务运行状态

在引入了任务切换机制后，内核需要管理多个未完成的应用，而且我们不能对应用完成的顺序做任何假定。所以我们必须维护任务的运行状态:
```rust
pub enum TaskStatus{
	UnInit, // 未初始化 
	Ready,  // 准备运行
	Running,// 正在运行
	Exited, // 已退出
}
```

内核还需要一个保存应用的更多信息，将它们保存在 **任务控制快** 中:
```rust
pub struct TskControlBlock{
	pub task_status: TaskStatus,
	pub task_cx:     TaskContext, // 任务上下文，内有ra,sp,s0~s11等寄存器
}
```

### 任务管理器

一个全局的管理器，包含了所有要执行的任务
```rust
pub struct TaskManager {
    num_app: usize, // 任务管理器管理的应用数目
    inner: UPSafeCell<TaskManagerInner>,
}

struct TaskManagerInner {
    tasks: [TaskControlBlock; MAX_APP_NUM],
    current_task: usize, // 正在执行的应用编号
}
```

我们可重用并扩展之前初始化 `TaskManager` 的全局实例 `TASK_MANAGER` ：
1. 每个应用的上下文(`TaskContext`)的 `ra` 都默认是 `__restore`
2. `init_app_cx` 为每个应用的内核栈都构建一个 `TrapContext`，且设置 `sepc`( Trap 返回后继续执行的位置) 的值为每个 App 的入口

{{< block type="details" title="初始全局 TaskManger代码">}}
```rust
lazy_static! {  
    /// Global variable: TASK_MANAGER  
    pub static ref TASK_MANAGER: TaskManager = {  
        let num_app = get_num_app();  
        let mut tasks = [TaskControlBlock {  
            task_cx: TaskContext::zero_init(),  
            task_status: TaskStatus::UnInit,  
        }; MAX_APP_NUM];  
        for (i, task) in tasks.iter_mut().enumerate() {  
            task.task_cx = TaskContext::goto_restore(init_app_cx(i));  
            task.task_status = TaskStatus::Ready;  
        }  
        TaskManager {  
            num_app,  
            inner: unsafe {  
                UPSafeCell::new(TaskManagerInner {  
                    tasks,  
                    current_task: 0,  
                })  
            },  
        }  
    };  
}
```
{{< /block >}}

### sys_yield 和 sys_exit 的实现

1. `sys_yield` 与 `sys_exit` 的第一步就是更改当前任务的状态
	1. `sys_yield` -> Ready
	2. `sys_exit` -> Exited
2. 第二步都是运行下一个任务
	1. `self.find_next_task()` 找到下一个状态处于 `Ready` 的应用 ID
	2. 更改为 `Running` 状态
	3. 更新 `current_task`
	4. 根据 current 和 next 进行换栈，也就是调用 `__switch`

```rust
/// Switch current `Running` task to the task we have found,    
/// or there is no `Ready` task and we can exit with all applications completed    
fn run_next_task(&self) {  
        if let Some(next) = self.find_next_task() {  
            let mut inner = self.inner.exclusive_access();  
            let current = inner.current_task;  
            inner.tasks[next].task_status = TaskStatus::Running;  
            inner.current_task = next;  
            let current_task_cx_ptr = &mut inner.tasks[current].task_cx as *mut TaskContext;  
            let next_task_cx_ptr = &inner.tasks[next].task_cx as *const TaskContext;  
            drop(inner);  
            // before this, we should drop local variables that must be dropped manually  
            unsafe {  
                __switch(current_task_cx_ptr, next_task_cx_ptr);  
            }  
            // go back to user mode  
        } else {  
            println!("All applications completed!");  
            use crate::board::QEMUExit;  
            crate::board::QEMU_EXIT_HANDLE.exit_success();  
        }  
    }  
}
```


![应用的运行状态变化](/images/Pasted%20image%2020230110211219.png)

### 第一次进入用户态

1. 第一次运行应用程序，调用 `__switch` 函数是用一个默认的 TaskContext 与 `task.0` ,进行换栈
2. 每个应用程序的 TaskContext 的 `ra`  都默认是 `__restore`, 且都压入了一个默认的 `TrapContext`,这个 `TrapContect` 的 `sepc` 设置的值为每个应用程序的入口。即：
3. 第一次运行时，调用 `__switch`，换入 `task.0`
4. 这时候 `ra` 会被设置为 `__restore` 的地址
5. 返回后进入 `__restore` 的处理流程
6. 由于`sret` 会跳转到 `sepc` 的地址，即 `task.0` 的入口
7. 在运行 `__restore` 的过程中，特权级会被切换到用户态

这里也只是一个简单的协作式操作系统，需要每个应用显示的调用 `yeild` 才能共享 CPU。

## 分时多任务系统与抢占式调度

对 **任务** 的概念进行进一步扩展和延伸：
- 分时多任务： 操作系统管理每个应用程序，以时间片为单位来分时占用处理器运行应用
- 时间片轮转调度： 操作系统在一个程序用完其时间片后，就抢占当前程序并调用下一个程序执行，周而复始，形成对应用程序在任务级别上的时间片轮转调度

{{< block type="tip">}}
<mark style="background: #FFB8EBA6;">抢占式调度</mark>是应用程序 *随时* 都有被内核切换出去的可能。现代的任务调度算法基本都是抢占式的，它要求每个应用只能连续执行一段时间(一般是以<mark style="background: #ADCCFFA6;">时间片</mark>作为应用连续执行时长的度量单位)，然后内核就会将它强制性切换出去。

算法需要考虑：
1. 每次在换出之前给一个应用多少时间片去执行
2. 要换入哪个应用

从以下角度来评价调度算法：
1. 性能(吞吐量和延迟)
	1. 吞吐量: 某个时间点将一组应用放进去，在固定时间内执行完毕的应用最多
2. 公平性(多个应用分到的时间片占比不能过大)
{{< /block >}}

这里使用<mark style="background: #ADCCFFA6;">时间片轮转算法</mark>进行调度：使用最原始的 RR 算法，维护一个任务队列，每次从队头去一个应用执行完一个时间片，然后丢入队尾，在继续去队头的应用执行。

### RISC-V 中的中断
时间片轮转调度的核心机制就在于计时，操作系统的计时功能是依靠硬件提供的时钟中断来实现的。而中断与 `ecall` 都是 `Trap`,但是中断是异步于当前的指令(即中断的原因与正在执行的指令无关)。

RISC-V 的中断可以分成三类：
-   **软件中断** (Software Interrupt)：由软件控制发出的中断
-   **时钟中断** (Timer Interrupt)：由时钟电路发出的中断
-   **外部中断** (External Interrupt)：由外设发出的中断

在判断中断是否会被屏蔽的时候，有以下规则：
-   如果中断的特权级低于 CPU 当前的特权级，则该中断会被屏蔽，不会被处理
-   如果中断的特权级高于与 CPU 当前的特权级或相同，则需要通过相应的 CSR 判断该中断是否会被屏蔽

中断产生后，硬件会完成如下事务：
-   当中断发生时，`sstatus.sie` 字段会被保存在 `sstatus.spie` 字段中，同时把 `sstatus.sie` 字段置零，这样软件在进行后续的中断处理过程中，所有 S 特权级的中断都会被屏蔽
-   当软件执行中断处理完毕后，会执行 `sret` 指令返回到被中断打断的地方继续执行，硬件会把 `sstatus.sie` 字段恢复为 `sstatus.spie` 字段内的值

### 时钟中断与计时器

由于软件需要一种计时机制，RISC-V 要求处理器有一个内置时钟：
1. 频率一般低于 CPU 主频
2. 还有一个计数器用来统计处理器自上电以来经过了多少个内置时钟的时钟周期
3. 在 RISC-V 中一般保存在 64 位的 CSR `mtime` 中
4. 还有一个 64 位的 CSR `mtimecmp` 的作用是：一旦计数器 `mtime` 的值超过了 `mtimecmp`，就会触发一次时钟中断。这使得我们可以方便的通过设置 `mtimecmp` 的值来决定下一次时钟中断何时触发
5. 它们都是 M 级别的寄存器，只能通过 M 级别的 SEE 来访问(RustSBI)

{{< block type="details" title="相关代码">}}
1. `CLOCK_FREQ` 是不同平台的时钟频率，单位是赫兹，也就是一秒钟之内计数器的增量
2. `set_next_trigger` 设置下一次打断的是时间
3. `set_timer` 就是设置寄存器 `mtimecmp` 的值
```rust
use crate::config::CLOCK_FREQ;  
use crate::sbi::set_timer;  
use riscv::register::time;  
  
const TICKS_PER_SEC: usize = 100;  
const MSEC_PER_SEC: usize = 1000;  
  
/// read the `mtime` registerpub 
fn get_time() -> usize {  
    time::read()  
}  
  
/// get current time in milliseconds  
pub fn get_time_ms() -> usize {  
    time::read() / (CLOCK_FREQ / MSEC_PER_SEC)  
}  
  
/// set the next timer interrupt  
pub fn set_next_trigger() {  
    set_timer(get_time() + CLOCK_FREQ / TICKS_PER_SEC);  
}
```
{{< /block >}}

### 抢占式调度

在 `trap_handler` 放在中添加以下代码，即根据当原因是 S 级特权级时钟打断时，重新设置打断，并暂停当前应用然后运行下一个应用。
```rust
match scause.cause() {
    Trap::Interrupt(Interrupt::SupervisorTimer) => {
        set_next_trigger();
        suspend_current_and_run_next();
    }
}
```

然后添加一些初始化代码：
```rust 
#[no_mangle]  
pub fn rust_main() -> ! {  
    // ...
    trap::enable_timer_interrupt();  // 设置 `sie.stie` 使得 S 特权级时钟中断不会被屏蔽
    timer::set_next_trigger();  // 设置第一个 10ms 的计时器
    // ...
}
```


1. 当第一个应用运行了 10ms 后，第一个 S 特权级时钟中断就会触发
2. 由于应用运行在 U 特权级，且 `sie` 寄存器被正确设置，该中断不会被屏蔽，而是跳转到 S 特权级内的我们的 `trap_handler` 里面进行处理，并顺利切换到下一个应用

现在的操作系统已经支持：
1. 操作系统进行主动调度
2. 程序可以主动出让时间片(`sys_yield`)


## 练习

### 1. 显示操作系统切换任务的过程

包装 `__switch` 函数，然后打印切换任务的 id

```rust
/// switch 交换两个 task,替换执行流  
pub fn switch__(current_task_cx_ptr: *mut TaskContext, next_task_cx_ptr: *const TaskContext) {  
    unsafe {  
        let current = current_task_cx_ptr.as_ref().unwrap();  
        let next = next_task_cx_ptr.as_ref().unwrap();  
        debug!(  
            "switch from {:?} to {:?}",  
            current.get_app_id(),  
            next.get_app_id(),  
        );  
        __switch(current_task_cx_ptr, next_task_cx_ptr);  
    }  
}
```

### 2.统计每个应用执行后的完成时间：用户态完成时间和内核态完成时间

1. 根据 `user/src/lib.rs` 中可得知，用户程序执行完毕后都会调用 `syscall` 这个系统调用
```rust
#[no_mangle]  
#[link_section = ".text.entry"]  
pub extern "C" fn _start() -> ! {  
    clear_bss();  
    exit(main());  
    panic!("unreachable after sys_exit!");  
}
```
2. 即操作系统处理这个 `syscall` 时就是用户态完成时间，处理完毕后就是内核态完成时间
3. 调用 `mark_current_exited` 时是用户态结束时间
4. 关于内核态结束时间
	1. 调用 `__swich` 后会执行 `ret` 指令直接运行下一个程序
	2. 想到一个简单的办法，在运行下一个程序的开头先调用一个自定义的 syscall: `mark_prev_kernel_end` 就可以标记上一个应用程序内核态完成时间
	3. 发现了 bug, 这里能成功运行是因为这几个程序在一个时钟周期就运行完毕了，但是如果程序的执行时间大于几个时间周期，而 `mark_prev_kernel_end` 只在第一次运行时设置，这样就有问题，因为 `switch` 回来后程序不是从头开始的
	4. 只能在汇编 `ret` 前加一个方法调用:
		```rust
		// ...
		addi sp, sp, -8  
		sd ra, 0(sp)  
		call mark_prev_kernel_end  
		ld ra, 0(sp)  
		addi sp, sp, 8  
  
		# return to next task  
		ret
		```
	5. 然后在应用程序的 `main` 结束后，调用标记用户态退出时间
```text
DEBUG - Task 0 user end time: 99257,kernel end time 102332 | switch cost: 3075
DEBUG - Task 1 user end time: 123140,kernel end time 124516 | switch cost: 1376
DEBUG - Task 2 user end time: 149108,kernel end time 150363 | switch cost: 1255
DEBUG - Task 3 user end time: 37651703,kernel end time 37652583 | switch cost: 880
DEBUG - Task 4 user end time: 56401809,kernel end time 56402745 | switch cost: 936
```

