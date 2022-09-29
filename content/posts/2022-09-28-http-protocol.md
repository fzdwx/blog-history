---
title: "HTTP协议"
date: 2022-09-28T12:19:15+08:00
draft: false
tags: ["network","http"]
summary: 简介HTTP/1.1与H2。
---

> HTTP 1.1之前的实现就不讨论了，因为它们已经过时太久了，我上网的时候就已经接触不到了，所以主要说说HTTP/1.1、HTTP/2。

## HTTP/1.1

### HTTP/1.1协议报文简介

> CRLF: `\r\n`
>
> METHOD: HTTP请求，`GET`、`POST`、`PUT`、`DELETE`...
>
> URI: 统一资源标识符，比如`/`，`/index.html`...
>
> HTTPVersion: HTTP协议的版本号，比如`HTTP/1.1`，`HTTP/2`
>
> HEADERS: 请求头，比如`Host:localhost`，`Accept: */*`。
>
> BODY: 请求体，比如说一个JSON数据`{"name":"fzdwx"}`
>
> HTTPStatus: HTTP响应状态，常见的有`200`，`404`等
>
> HTTPStatusDesc: HTTP响应状态描述，`200`对应的`OK`。

#### 请求

```text
METHOD<SPACE>URI<SPACE>HTTPVersion
HEADERS
<CRLF>
BODY
```

示例:

```http
GET /hello HTTP/1.1
Host: 192.168.1.107:8889
Connection: keep-alive
Cache-Control: max-age=0
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/99.0.4844.82 Safari/537.36
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9
Accept-Encoding: gzip, deflate
Accept-Language: zh-CN,zh;q=0.9
```

#### 响应

```text
HTTPVersion HTTPStatus HTTPStatusDesc
HEADERS
<CRLF>
BODY
```

示例:

> 如果响应中使用了`transfer-encoding: chunked`这个来替代`Content-Length`
> ，就表示这是一个不固定大小的响应，结尾通常用`0\r\n`来分割。

```http
HTTP/1.1 200 OK
transfer-encoding: chunked
content-type: application/json; charset=utf-8

0/r/n
```

### HTTP/1.1主要新特性

1. 默认是长连接(`Connection: Keep-alive`)，支持一个TCP连接处理多个请求。
2. 缓存策略，在请求头中使用`Cache-Control`，`Expires`，`Last-Modified`，`ETag`等来控制。
3. 允许响应分块，就是上面提到的`transfer-encoding: chunked`，允许服务端可以多次返回响应体。

但是还是存在一定的问题，比如说如果有一个TCP连接阻塞了，还是会开启新的TCP连接进行处理请求。

## H2

HTTP2中的主要概念:

1. `Connection`: 一个TCP连接包含一个或多个`Stream`,所有的通讯都在**一个TCP连接**上完成。
2. `Stream`: 一个可以双向通讯的数据流，包含一条或多条`Message`，每个数据流都一个**唯一标识符**以及**可选的优先级**信息。
3. `Message`: 对应HTTP/1.1中的请求或响应，包含一条或多条`Frame`。
4. `Frame`: **最小传输单位**，它以**二进制**进行编码。

[HTTP通讯简图](/images/1.png)

在HTTP/1.1中是有`Start Line` + `header` + `body` 组成的，而在H2中是由一个`HEADER Frame`以及多个`DATA Frame`组成的。

![HTTP/1.1与H2报文组成的区别](/images/2.png)

{{< tweet-ref "https://twitter.com/fzdwx/status/1575314588488593408" >}}

### Frame

通常有一些公共的字段，比如`Length`，`Type`，`Flags`以及`Stream Id`；也各个类型所独有的字段。

分类如下:

- [DATA](https://halfrost.com/http2-http-frames-definitions/#toc-0): 用于传输http消息体。
- [HEADERS](https://halfrost.com/http2-http-frames-definitions/#toc-1): 用于传输首部字段。
- [PRIORITY](https://halfrost.com/http2-http-frames-definitions/#toc-2): 用于指定或重新指定引用资源的优先级。
- [RST_STREAM](https://halfrost.com/http2-http-frames-definitions/#toc-3): 用于通知流的非正常终止。
- [SETTINGS](https://halfrost.com/http2-http-frames-definitions/#toc-4): 用于约定客户端和服务端的配置数据。比如设置初识的双向流量控制窗口大小。
- [PUSH_PROMISE](https://halfrost.com/http2-http-frames-definitions/#toc-9): 服务端推送许可。
- [PING](https://halfrost.com/http2-http-frames-definitions/#toc-10): 用于计算往返时间，执行“ 活性” 检活。
- [GOAWAY](https://halfrost.com/http2-http-frames-definitions/#toc-11): 用于通知对端停止在当前连接中创建流。
- [WINDOW_UPDATE](https://halfrost.com/http2-http-frames-definitions/#toc-12): 用于调整个别流或个别连接的流量。
- [CONTINUATION](https://halfrost.com/http2-http-frames-definitions/#toc-17): 专门用于传递较大 HTTP 头部时的持续帧。

### 为什么H2必须要走HTTPS？

这其实在H2标准中没有规定，主要是为了更方便的进行HTTP协议的 升级/协商，确认一个Web服务器是否支持H2通常有两种方式:

1. 在请求头中设置`Upgrade: HTTP/2.0`以及`Connection: Upgrade,HTTP2-Settings`等，类似升级到`Websocket`。
2. 使用`TLS`中的`ALPN`(Application Layer Protocol Negotiation，应用层协议协商)中的`ALPN Next Protocol`
   字段，在`Client Hello`与`Server Hello`这个阶段就可以确定下来。

而现在的**浏览器**基本都是**实现的方式二**，即**与HTTPS绑定在一起**。但是如果我们不用浏览器进行访问，当然也可以不用HTTPS。

详细可[参考](https://imququ.com/post/protocol-negotiation-in-http2.html)。

### 为什么H2能实现并行响应请求?

在HTTP/1.1中，请求与响应是一一对应的，在同一个连接里，客户端依次发送两个请求，一段时间以后收到来自服务器的一个响应，这个响应一定是对应于第一个发出去的请求的。
因为**没有一个标志来表示哪个响应对应哪个请求**。

而在H2中基于`Stream`和`Frame`的设计: **每个`Frame`都带有`Stream Id`来标识是否为同一个`Stream`里面的数据**，每个`Stream`
互不影响，这样就能做到在一个TCP里面连接里面传输多对请求/响应。

## H2的新特性

H2的对HTTP/1.1优化的核心就是 **使用尽可能少的连接数**。

1. 多路复用: 只用一个TCP连接就能处理多对 请求/响应 ，不用在开启另外的TCP连接，就是通过`Stream`与`Frame`来实现的。
2. 二进制分帧: 使用`Frame`为最小单位进行通讯，并采用二进制编码。
3. [头部压缩](https://juejin.cn/post/7133238781452222472): 使用`HPACK`算法进行优化.
    - 维护一份相同的[静态字典](https://httpwg.org/specs/rfc7541.html#static.table.definition)，包含常见的请求头的KV组合
    - 一份动态字典，可以动态的扩容(每个连接单独维护)
    - 支持哈夫曼编码([静态哈夫曼码表](https://httpwg.org/specs/rfc7541.html#huffman.code))
   > 在HTTP/1中消息体可以用gzip进行压缩，但是请求头通常没有任何压缩，有时候请求头的数据可能比请求体的数据还多。
4. 请求优先级: 一般在`HEADERS`帧与`PRIORITY`帧中携带，通常依赖于服务端的支持程度。

## 工具

### 生成测试签名

```shell
go run $GOROOT/src/crypto/tls/generate_cert.go --host localhost
```

### 使用curl调试HTTPS

```shell
curl https://zcygov.cn -vv
```

## Links

- [Hypertext Transfer Protocol Version 2 (HTTP/2)](https://httpwg.org/specs/rfc7540.html)
- [HPACK: Header Compression for HTTP/2](https://httpwg.org/specs/rfc7541.html)
- [HTTP/2资料汇总](https://imququ.com/post/http2-resource.html)
- [HTTP/2中帧的定义](https://halfrost.com/http2-http-frames-definitions/)
- [HTTP/2新的机遇与挑战](https://www.dropbox.com/s/4duv6cqrhud4qzw/HTTP2%EF%BC%9A%E6%96%B0%E7%9A%84%E6%9C%BA%E9%81%87%E4%B8%8E%E6%8C%91%E6%88%98.pdf?dl=0)
- [探索http1.0到http3.0的发展史，详解http2.0](https://zhuanlan.zhihu.com/p/566351358)
- [HTTP/2相比1.0有哪些重大改进](https://www.zhihu.com/question/34074946/answer/2264788574)