# 极致文件读写的性能优化

文件 IO（读写磁盘）是 App 发生卡顿（主线程被阻塞）、发生发热（CPU 被频繁的内核态切换消耗）的核心元凶之一。如何根据不同的文件大小和业务场景选择正确的 API，是高级工程师的必修课。

## 1. 致命反面教材：`Data(contentsOf:)`

这是新手最喜欢用的 API，因为它极其简单。但它是引起 OOM（Out Of Memory 内存耗尽崩溃）的罪魁祸首。

```swift
let hugeFileURL = URL(fileURLWithPath: "path/to/2GB_Movie.mp4")

// 灾难！这会强行要求系统立刻在 RAM 里划出 2GB 的连续物理内存空间！
// 如果你的手机只有 3GB 内存，App 瞬间就会被系统杀掉。
let fileData = try Data(contentsOf: hugeFileURL)
```
**适用场景**：只适用于读取极小的配置文件（如几十 KB 的 Plist 或 JSON）。
**解决方案**：使用底层的内存映射技术（详情见专门的 `mmap(ap).md` 章节）或使用流式读取。

## 2. 流式分块读取 (Stream / Chunked Reading)

如果你需要计算一个超大文件的 MD5 哈希值，或者准备把它切片上传给服务器，你必须分块读取。

**现代方案：使用 `FileHandle` (iOS 13.4+)**

```swift
func readHugeFileInChunks(at url: URL) {
    do {
        // 创建一个用于读取的句柄
        let fileHandle = try FileHandle(forReadingFrom: url)
        // 每次只从磁盘搬运一小块（比如 64 KB）到内存里
        let chunkSize = 64 * 1024 
        
        while true {
            // 安全的现代 API (老版本是 readData(ofLength:))
            guard let chunk = try fileHandle.read(upToCount: chunkSize), !chunk.isEmpty else {
                break // 读到文件末尾了
            }
            
            // 在这一小块数据上执行极其耗时的操作...
            // 比如 updateMD5Hash(with: chunk)
        }
        
        try fileHandle.close()
    } catch {
        print("读取出错: \(error)")
    }
}
```
这种做法保证了无论文件有 1MB 还是 100GB，你的 App 永远只占用不到 1MB 的极低峰值内存。

## 3. 高频碎碎写的灾难

这是另一个极端。有时候开发者自己写了一个极简的日志系统。

```swift
// 极其错误的做法
func log(_ msg: String) {
    let oldData = try? Data(contentsOf: logURL)
    var newData = oldData ?? Data()
    newData.append(msg.data(using: .utf8)!)
    
    // 每次发生一点微小的改动，就把整个大文件全量重写一遍！
    // 并且强行触发磁盘的物理写入。
    try? newData.write(to: logURL, options: .atomic) 
}
```

如果这个函数在一秒钟内被调用了 1000 次。即使每次只写 1 个字节，它也会向文件系统发起 1000 次完整的“读取旧文件、内存拼接、新建临时文件、写入、原子覆盖”的恐怖循环。这会让手机发烫发热，甚至报出 MetricKit 的 `Disk Write Exception`。

**正确的解决方案：使用 `FileHandle` 的寻址追加**

```swift
func appendLog(_ msg: String) {
    do {
        let handle = try FileHandle(forWritingTo: logURL)
        // 将文件指针直接跳到文件的最末尾！
        try handle.seekToEnd()
        // 只把新增的这几十个字节“写在屁股后面”
        if let data = msg.data(using: .utf8) {
            try handle.write(contentsOf: data)
        }
        try handle.close()
    } catch {
        // 如果文件不存在就先建一个...
    }
}
```

## 4. 极致性能：Grand Central Dispatch (Dispatch I/O)

如果你在编写极其底层的网络下载工具（类似迅雷），即使是 `FileHandle` 也显得过于上层。
你可以使用 GCD 提供的 `DispatchIO`。它能够直接将硬件控制器的 DMA 缓冲区数据通过操作系统的虚拟内存层，直接映射或传递到用户的 GCD 队列中，最大限度地减少了数据在内核态和用户态之间极其昂贵的内存拷贝。这是在 iOS 上榨干闪存吞吐量极限的终极黑魔法。
