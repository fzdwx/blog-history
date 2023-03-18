---
title: "Lock、CAS、Futex"
date: 2023-03-18T13:50:19+08:00
update: 2023-03-18T13:50:19+08:00
draft: false
ShowToc: true
ShowBreadCrumbs: false
docs: [ostep]
---

> 在上一篇出现问题的最主要原因就是有多个线程访问了同一个变量(共享变量),导致出现了竞态条件.
> 从而使一个简单的 ++ 操作都不能正确的执行
>
> 这是由于操作系统的打断机制: 操作系统不会让每个程序独占 cpu 一直执行,会进行周期性的打断,
> 来切换其他 线程/程序 来执行.(++ 操作不仅只是一条指令)
>
> 而 Lock 可以直接解决这个问题,在代码中加锁,放在临界区的周围,确保临界区能够向单条指令的原子执行

lock() 就是获取锁,如果没有其他线程持有锁,当前线程就会获取锁从而进入临界区. 如果此时有另一个线程也调用 lock() 那么这个线程调用的 lock() 不会返回,直到这把锁释放.

而当锁的持有者调用 unlock() 后锁就变为可用的了. 如果没有其他线程卡在 lock() 里面,锁的状态就为可用的,如果有线程卡在 lock() 里面,那么其中的某一个会注意到锁状态的变化,然后获取到锁并进入临界区

## 1. 禁用操作系统打断实现的锁

最简单的单 cpu 的锁实现, 可以通过 启用/禁用 操作系统的打断机制来实现

```c
void lock(){
  disableInterrupts()
}

void unlock(){
  enableInterrupts()
}
```

这个锁实现的前提是单 cpu,调用 lock() 后当前线程就能独自 cpu,因为它禁用了操作系统的打断功能,从而独占了 cpu

## 2. xchg 实现的锁

用一个变量来表示锁的状态,如果这个变量为 0,那么锁就是可用的,如果为 1,那么锁就是被占用的

```rust
let lock = 0;

fn lock(){
  // Wait until the lock is free
  while (lock ==1){
    // spin
  }
  // Lock the lock
  lock = 1;
}

fn unlock(){
  lock = 0;
}
```

但上面的代码很显然是有问题的,因为有一个共享变量 lock,而我们无法保证修改 lock 这个操作是原子的

而操心系统为我们提供了一个指令,在 x86 是 xchg, 将旧值返回并写入新值

```rust
fn xchg(&mut self, val: u32) -> u32 {
  let ret = self;
  *self = val;

  ret
}
```

{{< desc "一个模拟的xchg, 不代表真实实现" >}}

然后使用 xchg 改写

```rust
let lock = 0;

fn lock(){
  while (xchg(&lock, 1) == 1){
  }
}

fn unlock(){
  xchg(&lock, 0);
}
```

这种锁可以保证正确性,但效率很低,因为如果当很多线程在获取锁时,那么就会有多少个线程在空转

## 3. CAS 实现的锁

操作系统提供了一个指令 cmpxchg,如果和预期值相等,就将新值写入,否则什么也不做,最后返回实际值

```rust
fn cmpxchg(&mut self, expected: u32, new: u32) -> u32 {
  let actual = self;
  if *self == expected {
    *self = new;
  }

  actual
}
```

{{< desc "一个模拟的cmpxchg, 不代表真实实现" >}}

从结果来说,它与 xchg 实现的锁是一样的

## 4. 怎么避免自旋

基于 CAS 实现锁简单并且有效,但这种解决方案在某些条件会很抵消:

1. 当一个线程持有锁时,被打断
2. 而其他线程去获取锁,但是由于锁被持有,所以会开始自旋
3. 一直自旋,直到被打断,第一个线程继续运行,释放锁
4. 最后另一个线程获取到锁

这种情况下,线程浪费了一次 cpu 执行时间

### 4.1 主动让出时间片

在需要自旋的地方的时候,调用 yield 出让时间片(主动打断自己的运行)

```rust
fn lock(){
  while (cmpxchg(&lock, 0, 1) == 1){
    yield();
  }
}
```

如果当我们有很多线程(100个)反复竞争同一把锁. 在这种情况下,一个线程持有锁,其他 99 个线程都调用 lock ,发现锁已经被持有了,然后调用 yield 让出 cpu.

假设采用某种调度算法(比如顺序或随机),这 99 个线程会一直处于这种循环种,这种方式同样消耗极大(涉及到上下文切换,也就是执行流的切换)

### 4.2 使用队列,休眠代替自旋

线程一直自旋或者立刻让出 CPU,无论哪种方案都可能造成浪费, 这次我们使用 park/unpark 来实现

```c
typedef struct lock_t { 
  int flag; 
  int guard; 
  queue_t *q; 
} lock_t; 
 
void lock_init(lock_t *m) { 
  m->flag  = 0; 
  m->guard = 0; 
  queue_init(m->q); 
} 
 
void lock(lock_t *m) { 
  while (TestAndSet(&m->guard, 1) == 1) 
         ; //acquire guard lock by spinning 
  if (m->flag == 0) { 
    m->flag = 1; // lock is acquired 
    m->guard = 0; 
  } else { 
    queue_add(m->q, gettid()); 
    m->guard = 0; 
    park(); 
  } 
 } 

void unlock(lock_t *m) { 
  while (xchg(&m->guard, 1) == 1) 
      ; //acquire guard lock by spinning 
  if (queue_empty(m->q)) 
      m->flag = 0; // let go of lock; no one wants it 
  else 
      unpark(queue_remove(m->q)); // hold lock (for next thread!) 
  m->guard = 0; 
} 
```

将 park/unpark 与 xchg 结合使用,并通过 queue 控制谁或获得锁

1. guard 用来自旋
2. 如果没有获取到锁,那么就将自己的线程 id 加入到队列中,然后 park 自己
3. 当锁被释放时,就从队列中取出一个线程 id,然后 unpark 这个线程

这个方法并没有完全避免自旋等待。线程在获取锁或者释放锁时可能被中断，从而导致其他
线程自旋等待。但是，这个自旋等待时间是很有限的(不是用户定义的临界区，只是在 lock
和 unlock 代码中的几个指令)

## 5. futex

Linux 提供了 futex, 每个 futex 都管理一个特定的物理内存地址,也有一个事先建好的内核队列. 调用者通过 futex 调用来睡眠或唤醒

调用 futex_wait(address,expected) 如果 address 与 expected 相等那么就会让调用线程睡眠,然后睡眠,否则立即返回

调用 futex_wake(address) 唤醒等待队列的一个线程

Linux 采用的是两阶段锁: 如果第一个自旋阶段没有获得锁,第二阶段调用者会睡眠,知道锁可用
