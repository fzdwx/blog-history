---
title: "HTTP协议"
date: 2022-09-28T12:19:15+08:00
draft: false
tags: ["network","interview"]
---

> HTTP 1.1之前的实现就不讨论了，因为它们已经过时太久了，我上网的时候就已经接触不到了，所以主要说说HTTP/1.1、HTTP/2。

## HTTP协议报文简介

> CRLF: `\r\n`
>
> METHOD: HTTP请求，`GET`、`POST`、`PUT`、`DELETE`...
>
> URI: 统一资源标识符，比如`/`，`/index.html`...
>
> HTTPVersion: HTTP协议的版本号，比如`HTTP/1.1`，`HTTP/2`

```text
METHOD<SPACE>URI<SPACE>HTTPVersion<CRLF>
```

## 生成测试签名

```shell
go run $GOROOT/src/crypto/tls/generate_cert.go --host localhost
```

## Links

- [HTTP/2 资料汇总](https://imququ.com/post/http2-resource.html)
- [HTTP/2 新的机遇与挑战](https://www.dropbox.com/s/4duv6cqrhud4qzw/HTTP2%EF%BC%9A%E6%96%B0%E7%9A%84%E6%9C%BA%E9%81%87%E4%B8%8E%E6%8C%91%E6%88%98.pdf?dl=0)
- [探索http1.0到http3.0的发展史，详解http2.0](https://zhuanlan.zhihu.com/p/566351358)
- [HTTP/2 相比 1.0 有哪些重大改进](https://www.zhihu.com/question/34074946/answer/2264788574)