## 添加图片:

```markdown
{{< figure align=center src="/images/2022092801.png" title="asdasd">}}

or

![阿萨德](/images/2.png)
```

## 添加gist

```markdown
{{< gist spf13 7896402 >}}
```

## 视频

[参考](https://github.com/Lednerb/bilberry-hugo-theme#video)

```markdown
<!-- YouTube -->
{{< video type="youtube" id="<youtube-video-id>" >}}

<!-- Vimeo -->
{{< video type="vimeo" id="<vimeo-video-id>" >}}

<!-- Prezi -->
{{< video type="prezi" id="<prezi-video-id>" >}}

<!-- bilibili -->
{{< video type="bili" id="<bilibili-video-id>" >}}

<!-- PeerTube -->
{{< video type="peertube" id="<peertube-video-id>" >}}

<!-- MP4 external -->
{{< video type="mp4" url="<video-file-url>" imageUrl="<image-video-file-url>" >}}

<!-- MP4 in site's static folder -->
{{< video type="mp4" url="/<video-file-name>.mp4" imageUrl="/<image-video-file-name>.png" >}}

```

## 代码块高亮

```text
```go {hl_lines=[8,"15-17"]}
package main

import (
	"fmt"
	"os"
	"os/exec"
	"time"
)
//go:generate go tool yacc -o gopher.go -p parser gopher.y
func main() {
	// hello world
	postsName := fmt.Sprintf(
		"posts/%s-%s.md",
		time.Now().Format("2006-01-02"),
		os.Args[1])

	err := exec.Command("hugo", "new", postsName).Run()
	if err != nil {
		panic(err)
	}
}
/```
```

## 自定义块

当前支持:

- details
- tip

使用模板:

```
{{< block type="xxx" title="xxx">}}
## 这里是内容
{{< /block >}}
```