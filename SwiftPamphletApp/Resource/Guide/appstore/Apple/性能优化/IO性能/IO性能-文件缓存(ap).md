# 缓存策略：性能与空间的终极平衡

磁盘 I/O 是昂贵的，而网络请求更是昂贵且不稳定的。构建一个极其健壮的缓存层（Cache Layer），是提升应用流畅度（从网络转本地读取）、节省用户流量的必备手段。

## 1. 内存缓存 (Memory Cache) vs 磁盘缓存 (Disk Cache)

成熟的缓存架构（如著名的第三方图片加载库 `SDWebImage` 或 `Kingfisher`）都采用**双层缓存架构**。

### 第一层：内存缓存 (`NSCache`)
*   **介质**：设备的 RAM (运行内存)。
*   **速度**：纳秒级别，极其恐怖的读写速度。图片直接以解压后的位图（Bitmap / `CGImage`）形式存活在内存里，取出来瞬间就能渲染。
*   **容量**：极小。受系统严格监控。
*   **最佳实践**：**永远使用 `NSCache` 而不是普通的 `Dictionary`** 来做内存缓存。
    *   为什么？因为如果你的 App 突然被塞进后台或者打开了极占内存的大型游戏，系统会发出极其紧急的内存警告（Memory Warning）。`Dictionary` 里的数据雷打不动，最后一起被系统 OOM 强杀。而 `NSCache` 在底层注册了极低层的系统监听，它会自动、静默地清空自己内部的数据，保证 App 免于崩溃！

### 第二层：磁盘缓存 (沙盒文件)
*   **介质**：设备的闪存芯片 (SSD)。通常保存在 `Library/Caches/` 目录下。
*   **速度**：毫秒级别。图片是以压缩的原始二进制 (`Data`) 形式（如 JPEG）存在的，读出来后还需要经过极其耗 CPU 的解码步骤。
*   **容量**：巨大（取决于用户的手机剩余空间）。
*   **最佳实践**：不要为了图方便把图片塞进 `UserDefaults`。应该在 `Caches` 目录下建立专门的文件夹，以图片 URL 的 MD5 值作为文件名来存取。

## 2. 缓存淘汰算法 (Cache Eviction)

缓存不能无限膨胀，否则把用户的 256GB 手机塞满了，App 就会被愤怒的用户卸载。你必须设计极其科学的淘汰机制。

### A. 基于时间的淘汰 (TTL - Time To Live)
给缓存文件加一个有效期。
在每次启动 App 或进入后台时，遍历 `Caches` 目录，获取每个文件的创建时间或最后修改时间。
```swift
// 伪代码：淘汰超过 7 天没更新过的文件
let fileAttributes = try FileManager.default.attributesOfItem(atPath: file.path)
let modificationDate = fileAttributes[.modificationDate] as! Date
if Date().timeIntervalSince(modificationDate) > 7 * 24 * 3600 {
    FileManager.default.removeItem(at: file.path)
}
```

### B. 基于容量上限的 LRU 算法 (Least Recently Used)
这是最符合直觉的算法：设定磁盘缓存最大为 500MB。当新塞入图片导致超平时，**把“最久没被访问过”的旧图片删掉**。

*如何知道谁“最久没被访问过”？*
依靠读取文件的 `creationDate` 是不够的，因为有些文件早就建好了，但用户昨天才看过它。你需要深入读取 APFS 文件系统的特殊属性，或者自己在本地用一个 SQLite 小数据库或双向链表来维护一份极其精确的“最后访问时间”清单表。

## 3.  NSURLCache 系统的隐形缓存

有时候你写了网络请求，发现断网后居然还能拿到旧数据，这是因为 Apple 底层为你配置了极其低调但强大的 `URLCache` 机制。

它完全遵守 HTTP 协议的标准。如果服务器返回的响应头里带有 `Cache-Control: max-age=3600`，`URLSession` 会在底层自动把这段数据写入磁盘。在接下来的一小时内，如果你发起同样的 URL 请求，它甚至不会连网卡，直接以极快的速度把沙盒里存的旧响应扔给你！

这在频繁读取不变的静态资源（如头像、配置表）时能极大提升性能。
