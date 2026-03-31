# Swift 中的文件系统操作 (FileManager)

在 iOS 和 macOS 开发中，所有对本地磁盘文件的读写、创建、删除、移动和遍历操作，都是通过 Foundation 框架中极其古老但异常强大的核心类 **\`FileManager\`** 来完成的。

## 1. 认识沙盒机制 (Sandbox)

在 Apple 的移动平台上（iOS/iPadOS），你的 App 不能随便访问用户的整个硬盘。每个 App 都被局限在一个专属的“沙盒”目录中。

沙盒的核心目录有三个：
1. **\`Documents/\`**：存放用户产生的、不可再生的核心数据（比如用户写的日记）。**这个目录会被 iCloud 自动备份**。
2. **\`Library/\`**：存放非用户直观可见的数据。其中最常用的是 **\`Caches/\`** 目录。下载的图片、临时视频应放在这里，因为系统在空间不足时会自动清理它，且它**不会被备份**。
3. **\`tmp/\`**：极其临时的文件。下次启动或系统资源紧张时随时可能被清空。

## 2. 获取目标目录的 URL

在现代 Swift 中，操作文件一定要使用 \`URL\` 对象，而不是 \`String\` 路径。

```swift
import Foundation

// 推荐使用 FileManager.default 单例
let fm = FileManager.default

// 1. 获取 Documents 目录的绝对 URL
do {
    let documentsURL = try fm.url(
        for: .documentDirectory,    // 寻找 Documents
        in: .userDomainMask,      // 在当前用户沙盒下
        appropriateFor: nil,
        create: true              // 如果不存在是否创建
    )
    print("Documents 路径: \(documentsURL.path)")
} catch {
    print("获取路径失败: \(error)")
}

// 2. 获取 Caches 目录
let cachesURL = try? fm.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)

// 3. 获取临时目录
let tempURL = fm.temporaryDirectory
```

## 3. 基础的文件操作 (CRUD)

一旦有了目录的 URL，我们就可以在里面大展身手了。假设我们在 Documents 目录下：

### 写入文件 (Write)
```swift
let fileURL = documentsURL.appendingPathComponent("myNote.txt")
let content = "这是一段极其重要的测试文本。"

do {
    // 将字符串转为 Data 后写入，或者直接调用 String 的底层写入方法
    // atomically: true 意味着它会先写到一个临时文件里，写完后再瞬间替换掉原来的文件，保证数据安全，防止写到一半断电断崩溃。
    try content.write(to: fileURL, atomically: true, encoding: .utf8)
} catch {
    print("写入失败")
}
```

### 检查文件是否存在 (Exists)
```swift
// 注意：检查存在性必须传入 String 类型的 path，而不是 URL
if fm.fileExists(atPath: fileURL.path) {
    print("文件已存在")
}
```

### 读取文件 (Read)
```swift
do {
    let savedContent = try String(contentsOf: fileURL, encoding: .utf8)
    print("读出的内容: \(savedContent)")
} catch {
    print("读取失败")
}
```

### 删除文件 (Delete)
```swift
do {
    try fm.removeItem(at: fileURL)
    print("文件已成功删除")
} catch {
    print("删除失败: \(error)")
}
```

## 4. 目录与遍历操作

### 创建文件夹
```swift
let newFolderURL = documentsURL.appendingPathComponent("ImagesBackup")
do {
    // withIntermediateDirectories: true 表示如果中间缺了某个文件夹，会自动帮你全部建出来 (类似 mkdir -p)
    try fm.createDirectory(at: newFolderURL, withIntermediateDirectories: true, attributes: nil)
} catch {
    print("建文件夹失败")
}
```

### 遍历目录下的所有文件 (Contents)
如果你想知道某个文件夹里到底装了什么。

```swift
do {
    // 浅层遍历（只看当前文件夹第一层的内容）
    let files = try fm.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
    for file in files {
        print("发现文件: \(file.lastPathComponent)")
    }
} catch {
    print("遍历失败")
}
```

## 5. 高级技巧与注意事项

*   **不要硬编码绝对路径**：iOS 系统的沙盒路径在应用每次升级或通过 TestFlight 安装时，其 UUID 目录名都会发生随机改变！你绝对不能把 \`documentsURL.path\` 的完整字符串存进数据库。你**只能存相对文件名**（如 \`myNote.txt\`），然后在每次启动 App 时，动态获取当前的 Documents 路径并拼接它。
*   **大文件读取**：如果你要读一个 1GB 的视频文件，千万不要用 \`Data(contentsOf: url)\`，它会瞬间把你的内存挤爆导致闪退。请使用 \`FileHandle\` 或 \`InputStream\` 进行流式 (Stream) 增量读取。
