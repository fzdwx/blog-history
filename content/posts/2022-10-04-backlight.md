---
title: "调节linux屏幕的亮度"
date: 2022-10-04T10:07:28+08:00
draft: false
tags: ["linux"]
ShowToc: false
ShowBreadCrumbs: false
summary: 由于使用DWM,它不能像KDE那样之间有图形化的亮度调节功能,所以记录一下.
---

**查看当前backlight由什么控制:**

> 一般都是`intel`.

```shell
ls /sys/class/backlight
```

**查看当前的亮度:**

```shell
cat /sys/class/backlight/intel_backlight/max_brightness
```

**修改亮度:**

```shell
echo 5000 | sudo tee /sys/class/backlight/intel_backlight/brightness
```