---
title: "linux 连接蓝牙耳机"
date: 2023-02-09T12:50:21+08:00
draft: false
tags: ["linux"]
ShowToc: false
ShowBreadCrumbs: false
---


以 Archlinux 为例子

```shell
bluetoothctl power on
# 扫描
bluetoothctl scan on  
# 结对
bluetoothctl pair xxx
# 连接
bluetoothctl connect xxx
# 设置 蓝牙为默认输出
pavucontrol
```


![设置 蓝牙为默认输出](/images/Pasted%20image%2020230209125317.png)