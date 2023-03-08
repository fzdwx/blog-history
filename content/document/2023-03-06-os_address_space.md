---
title: "操作系统的地址空间"
date: 2023-03-06T20:30:48+08:00
update: 2023-03-08T22:09:34+0800
draft: false
docs: [os,risc-v]
ShowBreadCrumbs: false
---

{{< block type="tip" title="回顾">}}

前面通过 [Trap 机制](http://fzdwx.github.io/document/2023-01-08-os-multi-programs/#分时多任务系统与抢占式调度),实现了操作系统的分时复用,
这是为了公平性的考虑,防止独占 CPU 的情况发生,而应用自认为的独占 CPU 只是内核想让应用看到的一种假象.

CPU 计算资源被 分时复用 的实质被内核通过恰当的抽象隐藏了起来,对应用不可见.
{{< /block >}}

但是内存管理这一块还是非常狂野的,应用程序可以随便读写内存,这样就会导致一些问题：

1. 应用程序可以随意改写内核的代码,这样就会导致内核崩溃
2. 应用程序运行完毕后,内存中的数据没有被清理,这样就会导致内存泄漏
3. 内核提供的接口不够友善,应用程序需要自己去管理内存,这样就会导致应用程序的复杂度提高

所以为了解决这些问题,更好的管理内存,我们需要引入操作系统的地址空间.

# 1. Rust 中的动态内存分配

静态分配: 在编译器编译程序时已经知道了这些变量所占的字节大小, 于是分配了一块固定的内存将它们存储, 这样变量在栈/数据段中的位置就是固定的.

- 可能是一个局部变量,来自于正在执行的当前函数调用栈上, 即被分配在栈上
- 也可能是一个全局变量, 一般被分配在数据段中

而如果只使用静态分配,它可以应付一部分的需求,但是对于其它情况: 比如文件的读取, 在文件读取时我们并不知道文件的大小, 可能会根据经验来将缓冲区的大小设为某个常量,
而如果待处理的文件很小, 那么就可能会浪费空间, 如果文件很大, 那么就可能会导致缓冲区溢出.

动态分配: 就是有一个大小可以随着应用的运行动态增减的内存空间 - _heap(堆)_.

1. 在程序运行的时候从里面分配一块空间来存放变量
2. 在变量的生命周期结束后, 就回收以待后面的使用

动态内存分配也有缺点, 就是进行多次不同大小的内存分配和释放操作后, 会产生内存空间的浪费, 即存在无法被应用使用的空闲内存碎片

这是 c 语言提供的动态内存分配的接口, `malloc` 用于申请内存并返回指向那片内存的指针, `free` 接受一个指针, 用于释放这块内存.

```c
void* malloc (size_t size);
void free (void* ptr);
```

在 Rust 中我们可以通过实现 `alloc` crate 中定义的接口来实现基本的动态内存分配器:

```rust
// alloc::alloc::GlobalAlloc

pub unsafe fn alloc(&self, layout: Layout) -> *mut u8;
pub unsafe fn dealloc(&self, ptr: *mut u8, layout: Layout);
```

它们类似 c 语言中的接口, 也同样使用一个裸指针(也就是地址)作为分配的返回值和回收的参数.
两个接口中都有一个 `alloc::alloc::Layout` 类型的参数, 它指出了分配的需求, 分为两部分, 分别是所需空间的大小 size ,以及返回地址的对齐要求 align.
这个对齐要求必须是一个 2 的幂次,单位为字节数,限制返回的地址必须是 align 的倍数.


这里直接使用 `buddy_system_allocator` 的 `LockedHeap` 进行实现:
```rust
// os/src/mm/heap_allocator.rs

use buddy_system_allocator::LockedHeap;
use crate::config::KERNEL_HEAP_SIZE;

#[global_allocator]
static HEAP_ALLOCATOR: LockedHeap = LockedHeap::empty();

static mut HEAP_SPACE: [u8; KERNEL_HEAP_SIZE] = [0; KERNEL_HEAP_SIZE];

pub fn init_heap() {
    unsafe {
        HEAP_ALLOCATOR
            .lock()
            .init(HEAP_SPACE.as_ptr() as usize, KERNEL_HEAP_SIZE);
    }
}
```