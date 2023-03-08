---
title: "操作系统的特权级机制"
date: 2022-12-30T13:54:36+08:00
draft: false
docs: [os,risc-v]
summary: 特权级是为了隔离操作系统中用户程序与操作系统的,主要是防止用户程序的错误不会导致操作系统的一种机制.
---

应用程序会不可避免的出现错误,如果一个程序出现错误会导致其他程序或操作系统都无法运行那就是不可接受的.

所以人们提出*特权级*（Privilege）这一保护计算机系统不受有意或无意出错的程序破坏的机制,它让应用程序运行在**用户态**
,而操作系统运行在**内核态**,并且实现用户态和内核态的隔离.

![一个支持顺序执行多个应用程序的操作系统结构图](/images/Pasted%20image%2020221230141140.png)

主要通过 RustSBI 完成基本的硬件初始化后,跳转到操作系统的起始位置,操作系统然后建立栈空间并情况 bss 段（置0）,然后通过
AppManager 从 app 列表中一次加载各个 app 到指定的内存在用户态执行.app 在执行时,会通过系统调用的方式得到操作系统提供的功能,比如输出字符串.

## 特权级的软硬件协同设计

实现特权级机制的根本原因是**应用程运行的安全性不可充分信任**
.所以,计算机科学家和工程师想到了一个方法：让相对安全可靠的操作系统运行在一个硬件保护的安全执行环境中,不受到程序的破坏；而让应用程序运行在另外一个无法破坏操作系统的受限执行环境中.

- 应用程序不能随意访问地址空间
- 应用程序不能执行某些可能破坏计算机系统的指令

同时为了应用程序能获得操作系统的服务——应用程序和操作系统还需要有交互的手段.

- 低特权级的软件只能做高特权级允许它做的操作
- 超出低特权级能力的功能必须寻求高特权级的帮助

这样**高特权级**(操作系统)就成为**低特权级**（一般应用）的**执行环境的总要组成部分**.

为了实现这样的特权级机制,需要进行软硬件协同设计.一种简介的方式是： 处理器设置两个不同安全等级的执行环境,**用户态特权级的执行环境和内核态特权级的执行环境**.

- 明确指出可能破坏计算机系统的内核态特权指令集子集
- 规定内核态特权级指令子集中的指令只能在内核态特权级的执行环境中执行
- 处理器在执行指令前会进行特权级安全检查,如果在用户态环境中执行内核态特权级指令就会产生异常

传统的`call`和`ret`指令组合会直接绕过硬件的特权级保护检查,所以需要新的指令：

- `ecall`： 执行环境调用,具有**用户态**到**内核态**的执行环境切换能力的**函数调用**指令
    - 从当前特权级切换到比当前高一级
- `eret`： 执行环境返回,基友**内核态**到**用户态**的执行环境切换能力的**函数返回**指令
    - 切换到不高于当前特权级

硬件有了这样的机制之后,还需要操作系统的配合才能完成对操作系统自身的保护.

1. 操作系统需要提供能在执行`eret`前**准备和恢复用户态执行应用程序的上下文**
2. 在用户程序调用`ecall`后能**检查应用程序的系统调用参数**,确保参数不会破坏操作系统

## RISC-V 特权级架构

| 级别  | 编码  | 名称                           |
|-----|-----|------------------------------|
| 0   | 00  | 用户/应用模式 (U,User/Application) |
| 1   | 01  | 监督模式 (S,Supervisor)          |  
| 2   | 10  | 虚拟监督模式 (H,Hypervisor)        |
| 3   | 11  | 机器模式 (M,Machine)             | 

级别数值越大则特权级越高,掌控硬件的能力越强.即 M 最强,U 最弱,在 CPU 层面只有 M 是必须的.

![在特权级架构的角度看待一套支持应用程序运行的执行环境](/images/Pasted%20image%2020221230152533.png)

白色表示执行环境,黑色表示相邻两层执行环境之间的接口.SSE 代表**监督模式执行环境**,例如 RustSBI.

按需实现 RISC-V 特权级：

1. 简单的嵌入式应用只需实现 M
2. 带有一定保护能力的嵌入式系统需要实现 M、U
3. 复杂的多任务系统需要实现 M、S、U

### 操作系统异常控制流

1. 中断： 由外部设备引起的外部 I/O 时间如时钟中断、控制台中断等.外设中断是异步产生的,与处理器的执行无关.
2. 异常： 处理器执行指令期间检测到不正常的或非法的内部事件(如除零、数组越界等)
3. 陷入: 程序在执行过程中通过系统调用请求操作系统服务时而有意引发的事件

要处理上面的异常,都需要操作系统保存与恢复被 打断/陷入 前应用程序的控制流上下文.

{{< block type="tip">}}
控制流上下文： 确保下一刻能继续正确执行控制流指令的物理资源,也可称为控制流所在执行环境的状态.

这里的物理资源即计算机硬件资源,如 CPU 的寄存器、内存等.
{{< /block >}}

**执行环境**的另一种功能是对**上层软件**的执行进行监管管理： 当**上层软件**执行出现了异常或特殊情况,导致需要用到**执行环境
**中提供的功能,因此需要暂停**上层软件**的执行,转而运行**执行环境**的代码.

而**上层软件**和**执行环境**的**特权等级**往往不同,所以这个过程可能(大部分情况下)会有 CPU 的**特权级切换**.当**执行环境
**的代码运行结束后,我们就需要回到**上层软件**暂停的位置**继续执行**.在 RISC-V 中,这种异常控制流被称为**异常**,是 RISC-V
中的 **trap** 的一种.

用户态应用直接触发从用户态到内核态的异常的原因总体上可以分为两种：

1. 用户态软件为获得内核态操作系统的服务功能而执行特殊指令
2. 在执行某条指令出现了错误(如执行了用户态不允许执行的指令)并被 CPU 检测到

| interrupt | exception code | description                    |
|-----------|----------------|--------------------------------|
| 0         | 0              | Instruction address misaligned |
| 0         | 1              | Instruction access fault       |
| 0         | 2              | Illegal instruction            |
| 0         | 3              | Breakpoint                     |
| 0         | 4              | Load address misaligned        |
| 0         | 5              | Load access fault              |
| 0         | 6              | Store/AMO address misaligned   |
| 0         | 7              | Store/AMO access fault         |
| 0         | 8              | Environment call from U-mode   |
| 0         | 9              | Environment call from S-mode   |
| 0         | 11             | Environment call from M-mode   |
| 0         | 12             | Instruction page fault         |
| 0         | 13             | Load page fault                |
| 0         | 15             | Store/AMO page fault           |

其中 `Breakpoint` 和 `Environment call` 两种异常指令称为 陷入 或 trap 类指令.通过在上层软件中执行一条特定的指令触发的：
1. 执行 `ebreak` 指令就会触发 `Breakpoint` 异常
2. 执行 `ecall` 指令就会根据 CPU 当前所处的特权级而触发不同的异常(8/9/11)

### ecall
这是一种特殊的陷入类指令,相邻的两特权级软件之间的接口正是通过这种陷入机制实现的.M 模式软件 SEE 和 S 模式的内核之间的接口被称为**监督模式二进制接口**(Supervisor Binary interface, **SBI**),而内核和 U 模式的应用程序之间的接口被称为**应用程序二进制接口**(Application Binary interface, **ABI**)——系统调用(**syscall**).

而为什么叫二进制接口,是因为它是机器/汇编指令级的接口(没有针对某种特定的高级语言编写的内部调用接口),而且不是普通的函数调用控制流,而是陷入异常控制流,会切换 CPU 特权级.所以只有机器/汇编级别才能满足跨语言的通用和灵活性.

![在软件(应用,操作系统)执行过程中经常能看到特权级切换](/images/Pasted%20image%2020221230220510.png)

总之出现:
1. 执行某一指令发生了某种错误(如除零、无效地址访问、无效指令等)
2. 执行了高特权级指令
3. 访问了不应该方法的高特权级的资源

就需要将控制权移交给高特权级的软件来处理.当错误/异常恢复后,则重新回到低特权级的软件中执行,如果错误不能恢复,那么高特权级软件有权限杀死和清除低特权级软件.

### RISC-V 的S级特权指令

在 RISC-V 中有两类属于 S 模式的特权指令
1. 指令本身属于高特权级,如 `sret`(从 S 模式返回 U 模式)
2. 访问的 S 模式下才能访问的寄存器或内存
	1. sstatus: `SPP` 等字段给出 Trap 发生之前 CPU 处在哪个特权级（S/U）等信息
	2. spec: 当 Trap 是一个异常的时候,记录 Trap 发生之前执行的最后一条指令的地址
	3. scause: 描述 Trap 的原因
	4. stval: 给出 Trap 附加信息
	5. stvec: 控制 Trap 处理代码的入口地址

## 特权级切换

当执行到一条 trap 类指令时(如`ecall`),CPU 发现触发了一个异常并需要进行特殊处理,这涉及到执行环境切换,就是：
1. 用户态的执行环境中的应用程序通过调用`ecall`指令来向内核态的执行环境中的操作系统来请求某项服务
2. 这时候 CPU 和操作系统就会完成用户态到内核态的执行环境切换
3. 并在操作系统完成服务后再次切换回用户态执行环境
4. 然后应用程序就会紧接着`ecall`指令的后一条继续执行

在切换回来之后需要从发出 syscall 的执行位置恢复应用程序上下文并继续执行,这需要在切换前后维持应用程序的上下文保持不变.

应用程序的上下文包括通用寄存器和栈两个主要部分.而 CPU 在不同特权级下共享一套通用寄存器,所以操作系统在处理 trap 的过程中也会使用到这些寄存器,就会改变应用程序的上下文.所以同函数调用一样,在执行操作系统的 trap 处理过程之前我们需要在某个地方(某内存块或内核的栈)保存这些寄存器并在 trap 处理结束之后恢复这些寄存器.

同时还有一些在 S 模式下专用的寄存器,也需要保证它们的变化在预期之内.

{{< block type="tip">}}
执行环境： 主要负责给在其上执行的软件提供相应的功能与资源,并可在计算机系统中形成多层次的执行环境.
1. 比如之间运行在裸机硬件上的操作系统,其执行环境就是 计算机的硬件
2. 后面就出现了在应用程序下面有了一层比较通用的函数库,这使得程序不用直接访问硬件了.所以应用程序的执行环境就是 函数库 -> 计算机硬件
3. 在后来,操作系统取代了函数库来访问硬件. 函数库 -> 操作系统 -> 计算机硬件
{{< /block >}}

### 特权级切换的硬件控制机制

当 CPU 执行完一条指令(如`ecall`)并准备从 U 陷入到 S 时,硬件会完成：
1. `sstatus`的`SPP`会被修改为 CPU 当前的特权级(U/S)
2. `sepc`会被修改为 trap 处理完成后默认会执行的下一条指令的地址
3. `scause/stval`分别会被修改为这次 trap 的原因以及相关的附加信息
4. CPU 会跳转到 `stvec` 所设置的 trap 处理入口地址,并将当前特权级设置为 S,并从 trap 处理入口开始执行
	1. `stvec`保存了中断处理的入口地址
	2. 它后两个字段:
		1. MODE 1~0, 2 bits
		2. BASE 63~2, 62 bits
	3. 当 MODE 为 0 时,`stvec`是 direct 模式,trap 的入口地址固定为 `BASE<<2`

当 CPU 完成 trap 处理准备返回时,需要通过`sret`来完成:
1. CPU 会将当前的特权级按照`sstatus`的`SPP`字段设置为 U/S
2. CPU 会跳转到`sepc`指向的指令并继续执行

### 用户栈和内核栈

当 trap 触发的一瞬间,CPU 就会切换到 S 特权级并跳转到`stvec`设置的位置,但是在正式进入 S 特权级的处理之前,我们必须保存原控制流的寄存器状态,这一般是通过内核栈来保存的.这是专门为操作系统准备的内核栈,而不是应用程序运行时的用户栈.

使用两个栈主要是为了安全性:隔离数据,不让用户态的应用程序读取到内核态的操作系统的数据.

### Trap 管理

特权级切换的核心就是对 trap 的管理：
1. 应用程序通过`ecall`进入到内核状态时,操作系统需要保存被打断的应用程序的 trap 上下文
2. 操作系统根据 CSR 寄存器(上述 S 模式下专有的寄存器),完成系统调用服务的分发与处理
3. 操作系统完成系统调用后,需要恢复被打断的应用程序的 trap 上下文,并通过`sret`让应用程序进行执行
```rust
#[repr(C)]
pub struct TrapContext {
    pub x: [usize; 32],
    pub sstatus: Sstatus,
    pub sepc: usize,
}
```

#### Trap 上下文的保存与恢复

在操作系统初始化时,我们通过修改`stvec`的值来指向 trap 处理入口点,即设置初始的`stvec`的值.
```rust
pub fn init() {  
    extern "C" {  
        fn __alltraps();  
    }  
    unsafe {  
	// 默认为 BASE 为 __alltraps,MODE 为 direct
        stvec::write(__alltraps as usize, TrapMode::Direct);  
    }  
}
```

trap 的处理流程如下： 
1. 通过`__alltraps`将 trap 上下文保存在内核栈上,然后跳转到 `trap_handler` 函数完成 trap 分发及处理
2. 当 `trap_handler`返回之后,使用`__restore`从保存在内核栈上的 trap 上下文恢复寄存器
3. 最后通过`sret`指令回到应用程序执行

```asm
__alltraps:  
    # csrrw rd csr rs => rd = csr, csr = rs
    # sp = sscratch, sscratch = sp, 交换 sscratch 与 sp
    # sp 指向用户栈,sscratch 指向内核栈
    # 交换后 sp 指向内核栈,sscratch 指向用户栈
    csrrw sp, sscratch, sp 
    # now sp->kernel stack, sscratch->user stack  
    # allocate a TrapContext on kernel stack  
    # 预分配 34 * 8 的栈帧
    addi sp, sp, -34*8  
    # save general-purpose registers
    # 保存 x0 ~ x31 跳过 x0(zero),x2(sp),x4(tp)
    sd x1, 1*8(sp)  
    # skip sp(x2), we will save it later  
    sd x3, 3*8(sp)  
    # skip tp(x4), application does not use it  
    # save x5~x31  
    .set n, 5  
    .rept 27  
        SAVE_GP %n  
        .set n, n+1  
    .endr  
    # we can use t0/t1/t2 freely, because they were saved on kernel stack  
    # t0 = sstatus
    csrr t0, sstatus  
    # t1 = spec
    csrr t1, sepc  
    # 32*8 = t0
    sd t0, 32*8(sp)  
    # 33*8 = t1
    sd t1, 33*8(sp)  
    # read user stack from sscratch and save it on the kernel stack  
    # 2*8 = sscratch
    csrr t2, sscratch  
    sd t2, 2*8(sp)  
    # set input argument of trap_handler(cx: &mut TrapContext) 
    # a0 = 内核栈
    mv a0, sp  
    call trap_handler
```

当`trap_handler`返回之后会从`trap_handler`的下一条指令开始执行,也就是`__restore`:

```asm
__restore:  
    # case1: start running app by __restore  
    # case2: back to U after handling trap  
    mv sp, a0  
    # now sp->kernel stack(after allocated), sscratch->user stack  
    # restore sstatus/sepc
    # 恢复在 __alltraps 保存的   
    ld t0, 32*8(sp)  # sstatus
    ld t1, 33*8(sp)  # spec
    ld t2, 2*8(sp)   # sscratch
    csrw sstatus, t0  
    csrw sepc, t1 
    # 设置为用户栈 
    csrw sscratch, t2  
    # 恢复 x0 ~ x31 寄存器
    # restore general-purpuse registers except sp/tp  
    ld x1, 1*8(sp)  
    ld x3, 3*8(sp)  
    .set n, 5  
    .rept 27  
        LOAD_GP %n  
        .set n, n+1  
    .endr  
    # release TrapContext on kernel stack
    # 释放栈帧  
    addi sp, sp, 34*8  
    # now sp->kernel stack, sscratch->user stack  
    csrrw sp, sscratch, sp  
    # 返回到用户程序继续执行
    sret
```

{{< block type="tip">}}
`sscratch`这个寄存器它：
1. 保存了内核栈的地址
2. 作为一个中转站让`sp`（执行用户栈的地址）暂存在`sscratch`中

通过`csrrw  sp, sscratch, sp`这一条指令就完成内核栈与用户栈的相互交换
{{< /block >}}

#### Trap 分发与处理

1. 根据`scause`的`cause`进行分发处理
2. 如果是`UserEnvCall`
	1. 则设置`sepc`为下一条指令 
	2. 调用 syscall
3. 如果出现错误则直接运行下一个应用程序
4. 如果是不支持的 trap 则直接抛出异常 

```rust
#[no_mangle]  
/// handle an interrupt, exception, or system call from user space  
pub fn trap_handler(cx: &mut TrapContext) -> &mut TrapContext {  
    let scause = scause::read(); // get trap cause  
    let stval = stval::read(); // get extra value  
    match scause.cause() {  
        Trap::Exception(Exception::UserEnvCall) => {  
            cx.sepc += 4;  
            cx.x[10] = syscall(cx.x[17], [cx.x[10], cx.x[11], cx.x[12]]) as usize;  
        }  
        Trap::Exception(Exception::StoreFault) | Trap::Exception(Exception::StorePageFault) => {  
            println!("[kernel] PageFault in application, kernel killed it.");  
            run_next_app();  
        }  
        Trap::Exception(Exception::IllegalInstruction) => {  
            println!("[kernel] IllegalInstruction in application, kernel killed it.");  
            run_next_app();  
        }  
        _ => {  
            panic!(  
                "Unsupported trap {:?}, stval = {:#x}!",  
                scause.cause(),  
                stval  
            );  
        }  
    }  
    cx  
}
```

### 执行应用程序

 当操作系统初始化完成或某个应用形成运行结束或失败时,就调用`run_next_app`运行下一个应用程序.此时是 S 模式而要切换到 U 模式,所以切换流程:
1. 构造应用程序开执行所需的 trap 上下文
2. 通过`__restore`函数,从 trap 上下文中恢复应用程序执行所需的寄存器
3. 设置`sepc`的值为`0x80400000`(固定为这个值,后续会把每个应用程序加载到这个地址)
4. 切换`scratch`和`sp`,将`sp`指向应用程序用户栈
5. 执行`sret`切换 S => U

```rust
/// init app context  
pub fn app_init_context(entry: usize, sp: usize) -> Self {  
    let mut sstatus = sstatus::read(); // CSR sstatus  
    sstatus.set_spp(SPP::User); //previous privilege mode: user mode  
    let mut cx = Self {  
        x: [0; 32],  
        sstatus,  
        sepc: entry, // entry point of app  
    };  
    cx.set_sp(sp); // app's user stack pointer  
    cx // return initial Trap Context of app  
}

/// run next app  
pub fn run_next_app() -> ! {  
    /// ...
	
    extern "C" {  
        fn __restore(cx_addr: usize);  
    }  
    // 在内核栈上压入一个 trap 上下文,它在栈顶,所以是 __restore 的参数
    // 即 a0 = 内核栈顶
    // 所以会有 `mv sp a0` 这一句,
    // sepc 的值为固定的程序入口    
    // 根据`__restore`函数,如果是第一次调用,那么`sscratch`是什么时候设置为用户栈的？
    // 根据`mv sp a0`那么则 sp = a0 = trapContext
    // 在`app_init_context`的实现中有`cx.set_sp(sp)`这一句即x[2] = sp = 用户栈
    // 在`__restore`中有`ld t2, 2*8(sp)`与`csrw sscratch, t2`就完成了设置
    unsafe {  
        __restore(KERNEL_STACK.push_context(TrapContext::app_init_context(  
            APP_BASE_ADDRESS,  
            USER_STACK.get_sp(),  
        )) as *const _ as usize);  
    }  
    panic!("Unreachable in batch::run_current_app!");  
}
```