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