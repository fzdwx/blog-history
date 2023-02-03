---
title: "操作系统的并发编程"
date: 2022-12-16T20:54:45+08:00
draft: false
docs: [os]
summary: 从操作系统的层面讲要支持并发需要哪些条件
---

> 操作系统是最早的并发程序之一。


开始，我们肯定要理解什么是并发和并行以及它们的区别。
- 并行： 可以同时处理多个任务。
- 并发： 可以执行多个任务，但是同时只能执行一个任务，会在它们之间进行切换。

## 如果一个操作系统要支持并发，那么以下的哪些部分需要复制多份？

1. 全局变量
2. 堆内存m
3. 函数调用栈

![答案显而易见的是 函数调用栈](/images/Pasted%20image%2020221216211245.png)

并发编程为什么难？
1. 所有线程都共享一个堆内存
2. 单个线程的状态机的执行结果是固定的，但是多线程不一样，因为它们涉及到一个线程切换的问题，这会导致每次程序运行的结果可能都是不一样的。

![多线程状态机执行示意图](/images/Pasted%20image%2020221216211708.png)

## 无法保证的三个特性

1. 原子性: 一段代码执行时独占整个计算机系统
	1. 无法保证的例子： 两个线程对一个值进行 ++ N 次， 这个结果可能不是 2N
	2. 实现原子性： `lock` & `unlock` 
		- 实现临界去的绝对串行化
		- 其他部分仍然可以并行执行
2. 顺序性: 代码按编写的顺序执行，也就是实现源代码的按顺序翻译(为汇编)。
	1. 会导致的原因: 编译器的优化(**编译器对内存访问 “eventually consistent” 的处理导致共享内存作为线程同步工具的失效**。)，比如说 gcc 加`-O1/2`
	2. 实际例子：
		```c
		while(!done);
		// => opt
		if (!done) while(1); 
		```
	3. 实现源代码的按顺序翻译： 在代码中插入“优化不能穿越的” barrier
		1. asm volatile ("" ::: "memory");
			1. 含义是 可以读写任何内存
		2. 使用 volatile 变量
			1. 保持 c 语义和汇编语义一致
		 ```c
		 extern int volatile done;
		 while(!done);
		```
3. 可见性： 对某个共享内存的修改，其他线程要立马可见。
	1. 一段代码: 它的结果可能为: `0,0` `0,1` `1,0` `1,1` 4种情况, 但是只要有方法(f1 / f2)被执行就不会出现`0,0`这种结果。但实际的情况是`0,0`这个结果出现的次数最多。
		```c
		int x = 0, y= 0;
		void f1(){
			 x = 1;一个操
			 asm volatile("":::"memory");
			 printf("%d ",y)
		}

		void f2(){
			y = 1;
			asm volatile("":::"memory");
			printf("%d ",x)
		}
		```
	2. 原因是：现代处理器也是一个动态编译器。单个处理器把汇编（用电路）编译成更小的操作符。
		1. 在任何时刻，处理器都维护了一个操作符的容器
		2. 每一周期尽可能多的补充操作符
		3. 每一周期执行尽可能多的操作符
		4. 乱序执行，按序提交
	3. 实现顺序一致性： 使用`mfence`指令或使用原子指令(lock),让它每次都到内存中去读取，而不读取缓存
  

## 自旋锁 spin lock

假如硬件能提供一条“瞬间完成” 的读 + 写的指令
- 其他所有人暂停，load + store
	- 如果有人同时请求，硬件选出一个胜利者
	- 败者等胜利者完成后继续

### X86提供的 lock 前缀

```c
long sum = 0;

void sum(){
	for(;;){
		asm volatile("lock addq $1, %0": "+m"(sum));
	}
}
```

atomic exchange(load + store)

```c
int xchg(volatile int *addr, int newval) {
	int result; 
	asm volatile ("lock xchg %0, %1" 
		: "+m"(*addr), "=a"(result) : "1"(newval)); 
	return result; 
}
```

实现自旋锁:

```c
int locked = 0; 
void lock() { while (xchg(&locked, 1)) ; } 
void unlock() { xchg(&locked, 0); }
```


### lock 指令的现代实现

在 L1 cache 层保持一致性
- 所有 cpu 的L1缓存都用总线连起来
- 对某个内存 M 执行 lock，则其他所有缓存的 M 都无效（这个代价非常大）

## RISC-V 的原子操作

原子操作的目的：
1. `a = load(x); if (a == xx){ store(x,y) }`
2. `a = load(x); store(x,y)`
3. `a = load(x); a++; store(x,a)`

它们的本质都是 load -> exec(进行运算) -> store

### Load reserved / Store Conditional

LR: 在读取时会对这个内存加上一个标记，中断、其他处理器的写入都会导致标记消除
```asm
lr.w rd (rs1)
	rd = M[rs1]
	reserve M[rs1]
```

SC: 如果那片内存还存在标记则继续写入
```asm
sc.w rd rs2 (rs1)
	if still reserved:
		M[rs1] = rs2
		rd = 0
	else:
		rd = nonzero
```

### 实现 cas

```c
int cas(int *addr, int cmp_val, int new_val){
	int old_val = *addr;
	if (old_val == cmp_val){
		*addr = new_val;
		return 0;
	}else{
		return 1;
	}
}
```

```asm
cas:
	lr.w t0 (a0)
	bne t0 a1 fail
	sc.w t0 a2 (a0)
	bnez t0 cas
	li a0 0
	jr ra
fail:
	li a0 1
	ja ra
```


## 线程同步